import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int priceInCents;
  final int durationMinutes;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.priceInCents,
    required this.durationMinutes,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        priceInCents: json['priceInCents'] as int,
        durationMinutes: json['durationMinutes'] as int,
      );

  String get formattedPrice {
    final reais = priceInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [id, name, description, priceInCents, durationMinutes];
}
