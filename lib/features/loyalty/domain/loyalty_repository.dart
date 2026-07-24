import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failure.dart';
import 'club_subscription.dart';
import 'pix_payment.dart';
import 'stamp_card.dart';
import 'subscription_tier_view.dart';

class ActivationResult extends Equatable {
  final ClubSubscription subscription;
  final PixPayment? payment;

  const ActivationResult({required this.subscription, this.payment});

  @override
  List<Object?> get props => [subscription, payment];
}

abstract class LoyaltyRepository {
  Future<Either<Failure, StampCard>> getMyStampCard();
  Future<Either<Failure, void>> redeemCredit(int amountInCents);
  Future<Either<Failure, ClubSubscription?>> getMySubscription();
  Future<Either<Failure, List<SubscriptionTierView>>> getAvailableTiers();
  Future<Either<Failure, ActivationResult>> activateSubscription({
    required String tierId,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phone,
  });
  Future<Either<Failure, String>> getPaymentStatus(String paymentId);
  Future<Either<Failure, void>> cancelSubscription();
}
