import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
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
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, Tenant>> findBySlug(String slug) async {
    try {
      final response = await _dio.get('/tenants/$slug');
      return Right(Tenant.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
