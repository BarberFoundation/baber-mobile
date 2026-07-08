import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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
  }) async {
    try {
      final response = await _dio.get(
        '/appointments/available-slots',
        queryParameters: {'serviceId': serviceId, 'date': date},
      );
      final slots = (response.data as List)
          .map((json) => TimeSlot.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(slots);
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> bookAppointment({
    required String serviceId,
    required String clientName,
    required String clientPhone,
    required String date,
    required String startTime,
  }) async {
    try {
      await _dio.post('/appointments', data: {
        'serviceId': serviceId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'date': date,
        'startTime': startTime,
      });
      return const Right(null);
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
