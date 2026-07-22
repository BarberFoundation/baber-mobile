import 'package:equatable/equatable.dart';

sealed class SubscriptionPlansEvent extends Equatable {
  const SubscriptionPlansEvent();
  @override
  List<Object?> get props => [];
}

class LoadSubscriptionPlans extends SubscriptionPlansEvent {}
