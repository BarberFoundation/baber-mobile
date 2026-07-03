import 'package:equatable/equatable.dart';
import '../domain/auth_user.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? codeSentToPhone;
  final AuthUser? userNeedingName;
  final AuthUser? authenticatedUser;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.codeSentToPhone,
    this.userNeedingName,
    this.authenticatedUser,
    this.errorMessage,
  });

  const AuthState.initial() : this();
  const AuthState.loading() : this(isLoading: true);
  const AuthState.codeSent(String phone) : this(codeSentToPhone: phone);
  const AuthState.needsName(AuthUser user) : this(userNeedingName: user);
  const AuthState.authenticated(AuthUser user) : this(authenticatedUser: user);
  const AuthState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [isLoading, codeSentToPhone, userNeedingName, authenticatedUser, errorMessage];
}
