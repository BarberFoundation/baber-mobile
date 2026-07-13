import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/notification_item.dart';
import '../domain/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final Dio _dio;
  const NotificationsRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<NotificationItem>>> listMine() async {
    try {
      final response = await _dio.get('/notifications/my');
      final items = (response.data as List)
          .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(items);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
