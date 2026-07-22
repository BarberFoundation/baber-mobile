import 'package:equatable/equatable.dart';

sealed class ActivateSubscriptionEvent extends Equatable {
  const ActivateSubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class ActivateSubmitted extends ActivateSubscriptionEvent {
  final String name;
  final String cpfCnpj;
  final String? email;
  final String? phone;

  const ActivateSubmitted({required this.name, required this.cpfCnpj, this.email, this.phone});

  @override
  List<Object?> get props => [name, cpfCnpj, email, phone];
}
