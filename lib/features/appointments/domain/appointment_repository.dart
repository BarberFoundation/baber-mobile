import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'appointment.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, List<Appointment>>> listMine();
  Future<Either<Failure, void>> cancel(String id);
}
