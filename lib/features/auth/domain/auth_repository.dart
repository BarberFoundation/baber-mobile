import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'auth_user.dart';

abstract class AuthRepository {
  Future<void> requestPhoneCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(Either<Failure, AuthResult> result) onAutoVerified,
    required void Function(Failure failure) onVerificationFailed,
  });

  Future<Either<Failure, AuthResult>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, AuthResult?>> signInWithGoogle();

  Future<Either<Failure, AuthUser>> updateName(String name);
}
