import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/error/failure_message.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final TokenStorage tokenStorage;

  AuthBloc({required this.repository, required this.tokenStorage}) : super(const AuthState.initial()) {
    on<PhoneSubmitted>(_onPhoneSubmitted);
    on<PhoneCodeSent>(_onPhoneCodeSent);
    on<AutoVerificationCompleted>(_onAutoVerificationCompleted);
    on<PhoneVerificationFailed>(_onPhoneVerificationFailed);
    on<CodeSubmitted>(_onCodeSubmitted);
    on<NameSubmitted>(_onNameSubmitted);
  }

  Future<void> _onPhoneSubmitted(PhoneSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));
    await repository.requestPhoneCode(
      phone: event.phone,
      onCodeSent: (verificationId) => add(PhoneCodeSent(phone: event.phone, verificationId: verificationId)),
      onAutoVerified: (result) => add(AutoVerificationCompleted(result)),
      onVerificationFailed: (failure) => add(PhoneVerificationFailed(failure)),
    );
  }

  void _onPhoneCodeSent(PhoneCodeSent event, Emitter<AuthState> emit) {
    emit(state.copyWith(codeSentToPhone: event.phone, verificationId: event.verificationId));
  }

  Future<void> _onAutoVerificationCompleted(AutoVerificationCompleted event, Emitter<AuthState> emit) async {
    await event.result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (authResult) => _completeLogin(authResult, emit),
    );
  }

  void _onPhoneVerificationFailed(PhoneVerificationFailed event, Emitter<AuthState> emit) {
    emit(state.copyWith(errorMessage: failureMessage(event.failure)));
  }

  Future<void> _onCodeSubmitted(CodeSubmitted event, Emitter<AuthState> emit) async {
    final verificationId = state.verificationId;
    emit(state.copyWith(isLoading: true));
    if (verificationId == null) {
      emit(state.copyWith(errorMessage: 'Código expirado. Solicite um novo.'));
      return;
    }
    final result = await repository.confirmPhoneCode(verificationId: verificationId, smsCode: event.code);
    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (authResult) => _completeLogin(authResult, emit),
    );
  }

  Future<void> _onNameSubmitted(NameSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updateName(event.name);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (user) => emit(state.copyWith(authenticatedUser: user)),
    );
  }

  Future<void> _completeLogin(AuthResult authResult, Emitter<AuthState> emit) async {
    await tokenStorage.saveTokens(
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
    );
    if (authResult.user.needsName) {
      emit(state.copyWith(userNeedingName: authResult.user));
    } else {
      emit(state.copyWith(authenticatedUser: authResult.user));
    }
  }
}
