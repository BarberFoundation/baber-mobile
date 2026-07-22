import 'package:equatable/equatable.dart';
import '../domain/subscription_tier_view.dart';

class SubscriptionPlansState extends Equatable {
  final List<SubscriptionTierView>? tiers;
  final String? errorMessage;
  final bool isLoading;

  const SubscriptionPlansState({this.tiers, this.errorMessage, this.isLoading = false});

  const SubscriptionPlansState.initial() : this();
  const SubscriptionPlansState.loading() : this(isLoading: true);
  const SubscriptionPlansState.loaded(List<SubscriptionTierView> tiers) : this(tiers: tiers);
  const SubscriptionPlansState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [tiers, errorMessage, isLoading];
}
