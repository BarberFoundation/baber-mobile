import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'barber.dart';

abstract class BarberRepository {
  Future<Either<Failure, List<Barber>>> listBarbers();
}
