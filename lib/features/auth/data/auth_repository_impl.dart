import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  const AuthRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, Unit>> requestOtp(String phone) async {
    try {
      await _dio.post('/auth/otp/request', data: {'phone': phone});
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyOtp({required String phone, required String code}) async {
    try {
      final response = await _dio.post('/auth/otp/verify', data: {'phone': phone, 'code': code});
      return Right(AuthResult.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> updateName(String name) async {
    try {
      final response = await _dio.patch('/me', data: {'name': name});
      return Right(AuthUser.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  Failure _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == null) return NetworkFailure(e.message ?? 'network error');
    final data = e.response?.data;
    final message = (data is Map) ? (data['message']?.toString() ?? 'api error') : 'api error';
    return ApiFailure(statusCode: statusCode, message: message);
  }
}
