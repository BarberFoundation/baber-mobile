import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'time_slot.dart';

abstract class BookingRepository {
  Future<Either<Failure, List<TimeSlot>>> getAvailableSlots({
    required String serviceId,
    required String date,
    String? barberId,
  });

  Future<Either<Failure, void>> bookAppointment({
    required String serviceId,
    required String clientName,
    required String clientPhone,
    required String date,
    required String startTime,
    String? barberId,
  });
}
