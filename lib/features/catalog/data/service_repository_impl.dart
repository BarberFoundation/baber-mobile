import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failure.dart';
import '../domain/service.dart';
import '../domain/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final Dio _dio;
  const ServiceRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Service>>> listServices() async {
    try {
      final response = await _dio.get('/services');
      final services = (response.data as List)
          .map((json) => Service.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(services);
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
