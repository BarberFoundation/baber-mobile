import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/failure_message.dart';
import '../../catalog/domain/service_repository.dart';
import '../domain/loyalty_repository.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyRepository repository;
  final ServiceRepository serviceRepository;

  LoyaltyBloc({required this.repository, required this.serviceRepository})
      : super(const LoyaltyState(isLoading: true)) {
    // Handler único com sequential() (bloc_concurrency): processa um evento
    // por vez, na ordem em que chegaram, esperando o handler anterior
    // terminar antes de começar o próximo. Necessário porque o transformer
    // padrão do Bloc roda cada `on<E>` numa subscription independente do
    // mesmo stream — eventos de tipos diferentes (ex.: LoadLoyaltyHub seguido
    // de RedeemAllCreditRequested) processariam em paralelo e a ação leria o
    // estado antigo (ainda sem stampCard/subscription).
    //
    // Nota de alcance prático: hoje a UI trava os botões de ação atrás de
    // `isLoading`, então essa corrida não é disparável por um toque real do
    // usuário no momento — o fix protege principalmente mudanças futuras de
    // UI e a suíte de testes (que dispara os eventos back-to-back sem
    // aguardar), não um bug hoje alcançável em produção.
    on<LoyaltyEvent>(_onEvent, transformer: sequential());
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
    final previousCard = state.stampCard;
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

    final unauthorized = stampCardResult.fold((f) => f is UnauthorizedFailure, (_) => false);
    if (unauthorized) {
      emit(const LoyaltyState(sessionExpired: true));
      return;
    }

    final failureMsg = stampCardResult.fold((failure) => failureMessage(failure), (_) => null);
    if (failureMsg != null) {
      emit(LoyaltyState(errorMessage: failureMsg));
      return;
    }

    final newCard = stampCardResult.fold((_) => null, (card) => card);
    final wasIncomplete = previousCard != null &&
        previousCard.stampsRequired != null &&
        previousCard.currentStamps < previousCard.stampsRequired!;
    final isNowComplete =
        newCard != null && newCard.stampsRequired != null && newCard.currentStamps >= newCard.stampsRequired!;

    emit(LoyaltyState(
      stampCard: newCard,
      subscription: subscriptionResult.fold((_) => null, (s) => s),
      services: servicesResult.fold((_) => const [], (s) => s),
      tiers: tiersResult.fold((_) => const [], (t) => t),
      justCompletedCard: wasIncomplete && isNowComplete,
    ));
  }

  Future<void> _onRedeem(Emitter<LoyaltyState> emit) async {
    final card = state.stampCard;
    if (card == null || card.creditBalanceInCents <= 0) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await repository.redeemCredit(card.creditBalanceInCents);
    final failureMsg = result.fold((failure) => failureMessage(failure), (_) => null);
    if (failureMsg != null) {
      emit(state.copyWith(actionErrorMessage: failureMsg));
      return;
    }

    // POST /redeem returns 204 (no body) — refetch instead of assuming the
    // balance zeroed out, so the UI reflects the server's authoritative
    // post-redeem state rather than drifting from it.
    final refreshed = await repository.getMyStampCard();
    emit(state.copyWith(stampCard: refreshed.fold((_) => card, (c) => c)));
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
