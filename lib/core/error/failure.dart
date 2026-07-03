import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();
}

class NetworkFailure extends Failure {
  final String message;
  const NetworkFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ApiFailure extends Failure {
  final int statusCode;
  final String message;
  const ApiFailure({required this.statusCode, required this.message});

  @override
  List<Object?> get props => [statusCode, message];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();

  @override
  List<Object?> get props => [];
}
