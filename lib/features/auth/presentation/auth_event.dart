import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failure.dart';
import '../domain/auth_user.dart';

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

/// Internal event: fired when the AuthBloc's own callback to
/// AuthRepository.requestPhoneCode receives a verificationId from Firebase.
/// Not dispatched by the UI directly.
class PhoneCodeSent extends AuthEvent {
  final String phone;
  final String verificationId;
  const PhoneCodeSent({required this.phone, required this.verificationId});
  @override
  List<Object?> get props => [phone, verificationId];
}

/// Internal event: fired when Firebase auto-verifies the phone number
/// (Android SMS Retriever) without the user entering a code.
class AutoVerificationCompleted extends AuthEvent {
  final Either<Failure, AuthResult> result;
  const AutoVerificationCompleted(this.result);
  @override
  List<Object?> get props => [result];
}

/// Internal event: fired when Firebase reports a phone verification failure
/// (invalid number, rate limited, etc).
class PhoneVerificationFailed extends AuthEvent {
  final Failure failure;
  const PhoneVerificationFailed(this.failure);
  @override
  List<Object?> get props => [failure];
}
