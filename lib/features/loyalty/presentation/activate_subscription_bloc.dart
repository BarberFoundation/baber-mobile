import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../domain/loyalty_repository.dart';
import '../domain/subscription_tier_view.dart';
import 'activate_subscription_event.dart';
import 'activate_subscription_state.dart';

class ActivateSubscriptionBloc extends Bloc<ActivateSubscriptionEvent, ActivateSubscriptionState> {
  final LoyaltyRepository repository;
  final SubscriptionTierView tier;

  ActivateSubscriptionBloc({required this.repository, required this.tier})
      : super(const ActivateSubscriptionState()) {
    on<ActivateSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(ActivateSubmitted event, Emitter<ActivateSubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.activateSubscription(
      tier: tier.tier,
      name: event.name,
      cpfCnpj: event.cpfCnpj,
      email: event.email,
      phone: event.phone,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(activated: true)),
    );
  }
}
