import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  final String id;
  final String slug;
  final String name;
  const Tenant({required this.id, required this.slug, required this.name});

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [id, slug, name];
}
