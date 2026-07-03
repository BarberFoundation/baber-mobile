import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class PhoneSubmitted extends AuthEvent {
  final String phone;
  const PhoneSubmitted(this.phone);
  @override
  List<Object?> get props => [phone];
}

class CodeSubmitted extends AuthEvent {
  final String phone;
  final String code;
  const CodeSubmitted({required this.phone, required this.code});
  @override
  List<Object?> get props => [phone, code];
}

class NameSubmitted extends AuthEvent {
  final String name;
  const NameSubmitted(this.name);
  @override
  List<Object?> get props => [name];
}
