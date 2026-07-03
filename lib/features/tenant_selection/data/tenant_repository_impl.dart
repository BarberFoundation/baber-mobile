import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failure.dart';
import '../domain/tenant.dart';
import '../domain/tenant_repository.dart';

class TenantRepositoryImpl implements TenantRepository {
  final Dio _dio;
  const TenantRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Tenant>>> listTenants() async {
    try {
      final response = await _dio.get('/tenants');
      final tenants = (response.data as List)
          .map((json) => Tenant.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(tenants);
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Tenant>> findBySlug(String slug) async {
    try {
      final response = await _dio.get('/tenants/$slug');
      return Right(Tenant.fromJson(response.data as Map<String, dynamic>));
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
