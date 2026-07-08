import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'notification_item.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationItem>>> listMine();
}
