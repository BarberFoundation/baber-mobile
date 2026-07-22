import 'package:equatable/equatable.dart';

class SubscriptionQuota extends Equatable {
  final String serviceId;
  final int quantityTotal;
  final int quantityConsumed;

  const SubscriptionQuota({
    required this.serviceId,
    required this.quantityTotal,
    required this.quantityConsumed,
  });

  factory SubscriptionQuota.fromJson(Map<String, dynamic> json) => SubscriptionQuota(
        serviceId: json['serviceId'] as String,
        quantityTotal: json['quantityTotal'] as int,
        quantityConsumed: json['quantityConsumed'] as int,
      );

  @override
  List<Object?> get props => [serviceId, quantityTotal, quantityConsumed];
}

class ClubSubscription extends Equatable {
  final String status;
  final String tierId;
  final String currentCycleStart;
  final String currentCycleEnd;
  final List<SubscriptionQuota> quotas;

  const ClubSubscription({
    required this.status,
    required this.tierId,
    required this.currentCycleStart,
    required this.currentCycleEnd,
    required this.quotas,
  });

  factory ClubSubscription.fromJson(Map<String, dynamic> json) => ClubSubscription(
        status: json['status'] as String,
        tierId: json['tierId'] as String,
        currentCycleStart: json['currentCycleStart'] as String,
        currentCycleEnd: json['currentCycleEnd'] as String,
        quotas: (json['quotas'] as List)
            .map((q) => SubscriptionQuota.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  bool get isPastDue => status == 'PAST_DUE';

  @override
  List<Object?> get props => [status, tierId, currentCycleStart, currentCycleEnd, quotas];
}
