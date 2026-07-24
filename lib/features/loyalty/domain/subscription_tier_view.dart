import 'package:equatable/equatable.dart';

class TierServiceItem extends Equatable {
  final String serviceId;
  final int quantity;
  final int priceInCents;

  const TierServiceItem({required this.serviceId, required this.quantity, required this.priceInCents});

  factory TierServiceItem.fromJson(Map<String, dynamic> json) => TierServiceItem(
        serviceId: json['serviceId'] as String,
        quantity: json['quantity'] as int,
        priceInCents: json['priceInCents'] as int,
      );

  @override
  List<Object?> get props => [serviceId, quantity, priceInCents];
}

class SubscriptionTierView extends Equatable {
  final String id;
  final String name;
  final List<TierServiceItem> services;
  final int monthlyPriceInCents;
  final int discountPercentage;

  const SubscriptionTierView({
    required this.id,
    required this.name,
    required this.services,
    required this.monthlyPriceInCents,
    required this.discountPercentage,
  });

  factory SubscriptionTierView.fromJson(Map<String, dynamic> json) => SubscriptionTierView(
        id: json['id'] as String,
        name: json['name'] as String,
        services: (json['services'] as List)
            .map((s) => TierServiceItem.fromJson(s as Map<String, dynamic>))
            .toList(),
        monthlyPriceInCents: json['monthlyPriceInCents'] as int,
        discountPercentage: json['discountPercentage'] as int,
      );

  String get formattedMonthlyPrice {
    final reais = monthlyPriceInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [id, name, services, monthlyPriceInCents, discountPercentage];
}
