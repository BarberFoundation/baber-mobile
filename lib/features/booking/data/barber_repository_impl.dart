import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/barber.dart';
import '../domain/barber_repository.dart';

class BarberRepositoryImpl implements BarberRepository {
  final Dio _dio;
  const BarberRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Barber>>> listBarbers() async {
    try {
      final response = await _dio.get('/barbers');
      final barbers = (response.data as List)
          .map((json) => Barber.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(barbers);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
