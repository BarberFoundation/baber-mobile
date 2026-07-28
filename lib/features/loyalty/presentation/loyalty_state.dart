import 'package:equatable/equatable.dart';
import '../../catalog/domain/service.dart';
import '../domain/club_subscription.dart';
import '../domain/stamp_card.dart';
import '../domain/subscription_tier_view.dart';

class LoyaltyState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final StampCard? stampCard;
  final ClubSubscription? subscription;
  final List<Service> services;
  final List<SubscriptionTierView> tiers;
  final bool actionInProgress;
  final String? actionErrorMessage;
  final bool sessionExpired;
  // Transient — true only for the single emission where the stamp card just
  // crossed from incomplete to complete, so the UI can play the celebration
  // once and not replay it on every subsequent load.
  final bool justCompletedCard;

  const LoyaltyState({
    this.isLoading = false,
    this.errorMessage,
    this.stampCard,
    this.subscription,
    this.services = const [],
    this.tiers = const [],
    this.actionInProgress = false,
    this.actionErrorMessage,
    this.sessionExpired = false,
    this.justCompletedCard = false,
  });

  LoyaltyState copyWith({
    bool? isLoading,
    StampCard? stampCard,
    bool? actionInProgress,
    String? actionErrorMessage,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? false,
      stampCard: stampCard ?? this.stampCard,
      subscription: subscription,
      services: services,
      tiers: tiers,
      actionInProgress: actionInProgress ?? false,
      actionErrorMessage: actionErrorMessage,
    );
  }

  String? tierNameFor(String tierId) {
    for (final t in tiers) {
      if (t.id == tierId) return t.name;
    }
    return null;
  }

  String? serviceNameFor(String serviceId) {
    for (final s in services) {
      if (s.id == serviceId) return s.name;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        stampCard,
        subscription,
        services,
        tiers,
        actionInProgress,
        actionErrorMessage,
        sessionExpired,
        justCompletedCard,
      ];
}
