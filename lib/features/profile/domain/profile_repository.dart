import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../../auth/domain/auth_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> getMe();
}
