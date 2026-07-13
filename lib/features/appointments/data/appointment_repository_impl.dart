import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/appointment.dart';
import '../domain/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final Dio _dio;
  const AppointmentRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Appointment>>> listMine() async {
    try {
      final response = await _dio.get('/appointments/my');
      final appointments = (response.data as List)
          .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(appointments);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancel(String id) async {
    try {
      await _dio.patch('/appointments/$id/cancel');
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
