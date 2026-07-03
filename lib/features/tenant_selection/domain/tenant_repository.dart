import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'tenant.dart';

abstract class TenantRepository {
  Future<Either<Failure, List<Tenant>>> listTenants();
  Future<Either<Failure, Tenant>> findBySlug(String slug);
}
