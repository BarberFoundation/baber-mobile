import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../../auth/domain/auth_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> getMe();
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? cpf,
  });
}
