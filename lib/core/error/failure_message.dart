import 'failure.dart';

String failureMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure(:final message) => message,
    ApiFailure(:final message) => message,
    UnauthorizedFailure() => 'Sessão expirada.',
    FirebaseAuthFailure(:final message) => message,
  };
}
