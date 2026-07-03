import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Unit>> requestOtp(String phone);
  Future<Either<Failure, AuthResult>> verifyOtp({required String phone, required String code});
  Future<Either<Failure, AuthUser>> updateName(String name);
}
