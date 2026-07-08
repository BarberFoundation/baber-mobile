import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'service.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<Service>>> listServices();
}
