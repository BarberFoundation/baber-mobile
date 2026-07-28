import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';

class BookingRepositoryImpl implements BookingRepository {
  final Dio _dio;
  const BookingRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<TimeSlot>>> getAvailableSlots({
    required String serviceId,
    required String date,
    String? barberId,
  }) async {
    try {
      final response = await _dio.get(
        '/appointments/available-slots',
        queryParameters: {
          'serviceId': serviceId,
          'date': date,
          'barberId': ?barberId,
        },
      );
      final slots = (response.data as List)
          .map((json) => TimeSlot.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(slots);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> bookAppointment({
    required String serviceId,
    required String clientName,
    required String clientPhone,
    required String date,
    required String startTime,
    String? barberId,
  }) async {
    try {
      await _dio.post('/appointments', data: {
        'serviceId': serviceId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'date': date,
        'startTime': startTime,
        'barberId': ?barberId,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
