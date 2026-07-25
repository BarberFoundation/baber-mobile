import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/firebase/firebase_auth_gateway.dart';
import '../../../core/tenancy/tenant_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthGateway _gateway;
  final Dio _dio;
  final TenantStorage _tenantStorage;
  const AuthRepositoryImpl(this._gateway, this._dio, this._tenantStorage);

  @override
  Future<void> requestPhoneCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(Either<Failure, AuthResult> result) onAutoVerified,
    required void Function(Failure failure) onVerificationFailed,
  }) {
    return _gateway.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: onCodeSent,
      onAutoVerified: (idToken) async => onAutoVerified(await _exchangeToken(idToken)),
      onVerificationFailed: (code, message) =>
          onVerificationFailed(FirebaseAuthFailure(code: code, message: _mapFirebaseCode(code))),
    );
  }

  @override
  Future<Either<Failure, AuthResult>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final idToken = await _gateway.confirmCode(verificationId: verificationId, smsCode: smsCode);
      return _exchangeToken(idToken);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseAuthFailure(code: e.code, message: _mapFirebaseCode(e.code)));
    }
  }

  @override
  Future<Either<Failure, AuthResult?>> signInWithGoogle() async {
    try {
      final idToken = await _gateway.signInWithGoogle();
      if (idToken == null) return const Right(null); // usuário cancelou
      return _exchangeToken(idToken);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseAuthFailure(code: e.code, message: _mapGoogleCode(e.code)));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> updateName(String name) async {
    try {
      final response = await _dio.patch('/me', data: {'name': name});
      return Right(AuthUser.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  Future<Either<Failure, AuthResult>> _exchangeToken(String idToken) async {
    try {
      // Tenant is always selected before this screen is reachable.
      final tenantId = (await _tenantStorage.readTenantId())!;
      final response = await _dio.post('/auth/client/exchange', data: {'idToken': idToken, 'tenantId': tenantId});
      return Right(AuthResult.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  String _mapFirebaseCode(String code) {
    return switch (code) {
      'invalid-phone-number' => 'Número de telefone inválido.',
      'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
      'invalid-verification-code' => 'Código de verificação inválido.',
      'session-expired' => 'Código expirado. Solicite um novo.',
      _ => 'Erro ao verificar telefone. Tente novamente.',
    };
  }

  String _mapGoogleCode(String code) {
    return switch (code) {
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      'account-exists-with-different-credential' => 'Já existe uma conta com este e-mail.',
      'popup-closed-by-user' || 'canceled' => 'Login cancelado.',
      _ => 'Erro ao entrar com Google. Tente novamente.',
    };
  }
}
