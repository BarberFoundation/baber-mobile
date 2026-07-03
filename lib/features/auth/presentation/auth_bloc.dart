import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/error/failure_message.dart';
import '../domain/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final TokenStorage tokenStorage;

  AuthBloc({required this.repository, required this.tokenStorage}) : super(const AuthState.initial()) {
    on<PhoneSubmitted>(_onPhoneSubmitted);
    on<CodeSubmitted>(_onCodeSubmitted);
    on<NameSubmitted>(_onNameSubmitted);
  }

  Future<void> _onPhoneSubmitted(PhoneSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await repository.requestOtp(event.phone);
    result.fold(
      (failure) => emit(AuthState.error(failureMessage(failure))),
      (_) => emit(AuthState.codeSent(event.phone)),
    );
  }

  Future<void> _onCodeSubmitted(CodeSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await repository.verifyOtp(phone: event.phone, code: event.code);
    await result.fold(
      (failure) async => emit(AuthState.error(failureMessage(failure))),
      (authResult) async {
        await tokenStorage.saveTokens(
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
        );
        if (authResult.user.needsName) {
          emit(AuthState.needsName(authResult.user));
        } else {
          emit(AuthState.authenticated(authResult.user));
        }
      },
    );
  }

  Future<void> _onNameSubmitted(NameSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await repository.updateName(event.name);
    result.fold(
      (failure) => emit(AuthState.error(failureMessage(failure))),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
