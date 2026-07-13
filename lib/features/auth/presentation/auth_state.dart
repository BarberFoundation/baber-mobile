import 'package:equatable/equatable.dart';
import '../domain/auth_user.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? codeSentToPhone;
  final String? verificationId;
  final AuthUser? userNeedingName;
  final AuthUser? authenticatedUser;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.codeSentToPhone,
    this.verificationId,
    this.userNeedingName,
    this.authenticatedUser,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  /// errorMessage e isLoading resetam a cada transição, a menos que passados
  /// explicitamente. Os demais campos são preservados — um erro de código
  /// não pode destruir o verificationId do SMS em andamento (C1 do review).
  AuthState copyWith({
    bool isLoading = false,
    String? codeSentToPhone,
    String? verificationId,
    AuthUser? userNeedingName,
    AuthUser? authenticatedUser,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading,
      codeSentToPhone: codeSentToPhone ?? this.codeSentToPhone,
      verificationId: verificationId ?? this.verificationId,
      userNeedingName: userNeedingName ?? this.userNeedingName,
      authenticatedUser: authenticatedUser ?? this.authenticatedUser,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, codeSentToPhone, verificationId, userNeedingName, authenticatedUser, errorMessage];
}
