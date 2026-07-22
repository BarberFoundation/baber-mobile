import 'package:equatable/equatable.dart';

class StampCard extends Equatable {
  final int currentStamps;
  final int? stampsRequired;
  final int creditBalanceInCents;

  const StampCard({
    required this.currentStamps,
    required this.stampsRequired,
    required this.creditBalanceInCents,
  });

  factory StampCard.fromJson(Map<String, dynamic> json) => StampCard(
        currentStamps: json['currentStamps'] as int,
        stampsRequired: json['stampsRequired'] as int?,
        creditBalanceInCents: json['creditBalanceInCents'] as int,
      );

  String get formattedCreditBalance {
    final reais = creditBalanceInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [currentStamps, stampsRequired, creditBalanceInCents];
}
