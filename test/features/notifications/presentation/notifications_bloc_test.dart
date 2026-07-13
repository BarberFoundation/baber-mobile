import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/notifications/domain/notification_item.dart';
import 'package:baber_mobile/features/notifications/domain/notifications_repository.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_bloc.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_event.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_state.dart';

class MockNotificationsRepository extends Mock implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository repository;

  final item = NotificationItem(
    appointmentId: 'appt-1', type: NotificationItemType.confirmation,
    message: 'Confirmado!', status: 'SENT', sentAt: DateTime(2026, 1, 1), createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockNotificationsRepository();
  });

  blocTest<NotificationsBloc, NotificationsState>(
    'emits [loading, loaded] when LoadNotifications succeeds',
    build: () {
      when(() => repository.listMine()).thenAnswer((_) async => Right([item]));
      return NotificationsBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadNotifications()),
    expect: () => [
      const NotificationsState.loading(),
      NotificationsState.loaded([item]),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'emite sessionExpired quando listMine retorna UnauthorizedFailure',
    build: () {
      when(() => repository.listMine())
          .thenAnswer((_) async => const Left(UnauthorizedFailure()));
      return NotificationsBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadNotifications()),
    expect: () => [
      const NotificationsState.loading(),
      const NotificationsState(sessionExpired: true),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'emits [loading, error] when LoadNotifications fails',
    build: () {
      when(() => repository.listMine())
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 500, message: 'erro interno')));
      return NotificationsBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadNotifications()),
    expect: () => [
      const NotificationsState.loading(),
      const NotificationsState.error('erro interno'),
    ],
  );
}
