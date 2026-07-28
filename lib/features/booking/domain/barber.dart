import 'package:equatable/equatable.dart';

class Barber extends Equatable {
  final String id;
  final String name;

  const Barber({required this.id, required this.name});

  factory Barber.fromJson(Map<String, dynamic> json) => Barber(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [id, name];
}
