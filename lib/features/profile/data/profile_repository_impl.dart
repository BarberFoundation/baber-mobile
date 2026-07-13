import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  const ProfileRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, AuthUser>> getMe() async {
    try {
      final response = await _dio.get('/me');
      return Right(AuthUser.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
