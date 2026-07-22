import 'package:equatable/equatable.dart';

sealed class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object?> get props => [];
}

class LoadLoyaltyHub extends LoyaltyEvent {}

class RedeemAllCreditRequested extends LoyaltyEvent {}

class CancelSubscriptionRequested extends LoyaltyEvent {}
