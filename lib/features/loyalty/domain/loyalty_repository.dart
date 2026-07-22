import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'club_subscription.dart';
import 'stamp_card.dart';
import 'subscription_tier_view.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, StampCard>> getMyStampCard();
  Future<Either<Failure, void>> redeemCredit(int amountInCents);
  Future<Either<Failure, ClubSubscription?>> getMySubscription();
  Future<Either<Failure, List<SubscriptionTierView>>> getAvailableTiers();
  Future<Either<Failure, ClubSubscription>> activateSubscription({
    required String tier,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phone,
  });
  Future<Either<Failure, void>> cancelSubscription();
}
