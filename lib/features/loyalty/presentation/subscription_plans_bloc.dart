import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../domain/loyalty_repository.dart';
import 'subscription_plans_event.dart';
import 'subscription_plans_state.dart';

class SubscriptionPlansBloc extends Bloc<SubscriptionPlansEvent, SubscriptionPlansState> {
  final LoyaltyRepository repository;

  SubscriptionPlansBloc({required this.repository}) : super(const SubscriptionPlansState.initial()) {
    on<LoadSubscriptionPlans>(_onLoad);
  }

  Future<void> _onLoad(LoadSubscriptionPlans event, Emitter<SubscriptionPlansState> emit) async {
    emit(const SubscriptionPlansState.loading());
    final result = await repository.getAvailableTiers();
    result.fold(
      (failure) => emit(SubscriptionPlansState.error(failureMessage(failure))),
      (tiers) => emit(SubscriptionPlansState.loaded(tiers)),
    );
  }
}
