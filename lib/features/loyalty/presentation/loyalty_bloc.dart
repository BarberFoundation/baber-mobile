import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../../catalog/domain/service_repository.dart';
import '../domain/loyalty_repository.dart';
import '../domain/stamp_card.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyRepository repository;
  final ServiceRepository serviceRepository;

  LoyaltyBloc({required this.repository, required this.serviceRepository}) : super(const LoyaltyState()) {
    // Handler único com transformer sequencial (asyncExpand pausa a
    // subscription até o handler anterior terminar). Isso é necessário
    // porque o transformer padrão do Bloc roda cada `on<E>` numa subscription
    // independente do mesmo stream — eventos de tipos diferentes (ex.:
    // LoadLoyaltyHub seguido de RedeemAllCreditRequested) processariam em
    // paralelo e a ação leria o estado antigo (ainda sem stampCard/subscription).
    on<LoyaltyEvent>(_onEvent, transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  Future<void> _onEvent(LoyaltyEvent event, Emitter<LoyaltyState> emit) async {
    switch (event) {
      case LoadLoyaltyHub():
        await _onLoad(emit);
      case RedeemAllCreditRequested():
        await _onRedeem(emit);
      case CancelSubscriptionRequested():
        await _onCancel(emit);
    }
  }

  Future<void> _onLoad(Emitter<LoyaltyState> emit) async {
    emit(const LoyaltyState(isLoading: true));

    // As 4 chamadas disparam em paralelo (futures criadas antes de qualquer
    // await); cartão fidelidade é o dado essencial — sua falha vira erro de
    // tela, as outras degradam graciosamente (mostram menos informação).
    final stampCardFuture = repository.getMyStampCard();
    final subscriptionFuture = repository.getMySubscription();
    final servicesFuture = serviceRepository.listServices();
    final tiersFuture = repository.getAvailableTiers();

    final stampCardResult = await stampCardFuture;
    final subscriptionResult = await subscriptionFuture;
    final servicesResult = await servicesFuture;
    final tiersResult = await tiersFuture;

    final failureMsg = stampCardResult.fold((failure) => failureMessage(failure), (_) => null);
    if (failureMsg != null) {
      emit(LoyaltyState(errorMessage: failureMsg));
      return;
    }

    emit(LoyaltyState(
      stampCard: stampCardResult.fold((_) => null, (card) => card),
      subscription: subscriptionResult.fold((_) => null, (s) => s),
      services: servicesResult.fold((_) => const [], (s) => s),
      tiers: tiersResult.fold((_) => const [], (t) => t),
    ));
  }

  Future<void> _onRedeem(Emitter<LoyaltyState> emit) async {
    final card = state.stampCard;
    if (card == null || card.creditBalanceInCents <= 0) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await repository.redeemCredit(card.creditBalanceInCents);
    result.fold(
      (failure) => emit(state.copyWith(actionErrorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(
        stampCard: StampCard(
          currentStamps: card.currentStamps,
          stampsRequired: card.stampsRequired,
          creditBalanceInCents: 0,
        ),
      )),
    );
  }

  Future<void> _onCancel(Emitter<LoyaltyState> emit) async {
    emit(state.copyWith(actionInProgress: true));
    final result = await repository.cancelSubscription();
    result.fold(
      (failure) => emit(state.copyWith(actionErrorMessage: failureMessage(failure))),
      (_) => emit(LoyaltyState(stampCard: state.stampCard, subscription: null, services: state.services, tiers: state.tiers)),
    );
  }
}
