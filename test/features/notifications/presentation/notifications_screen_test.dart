import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/notifications/domain/notification_item.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_bloc.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_event.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:baber_mobile/features/notifications/presentation/notifications_state.dart';

class MockNotificationsBloc extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

void main() {
  late MockNotificationsBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadNotifications());
  });

  setUp(() {
    bloc = MockNotificationsBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<NotificationsBloc>.value(value: bloc, child: child),
      );

  testWidgets('dispatches LoadNotifications on init', (tester) async {
    whenListen(bloc, const Stream<NotificationsState>.empty(), initialState: const NotificationsState.initial());

    await tester.pumpWidget(wrap(const NotificationsScreen()));

    verify(() => bloc.add(LoadNotifications())).called(1);
  });

  testWidgets('renders notification message', (tester) async {
    final item = NotificationItem(
      appointmentId: 'appt-1', type: NotificationItemType.confirmation,
      message: 'Confirmado!', status: 'SENT', sentAt: DateTime.now(), createdAt: DateTime.now(),
    );
    whenListen(bloc, const Stream<NotificationsState>.empty(), initialState: NotificationsState.loaded([item]));

    await tester.pumpWidget(wrap(const NotificationsScreen()));

    expect(find.text('Confirmado!'), findsOneWidget);
  });

  testWidgets('shows empty message when there are no notifications', (tester) async {
    whenListen(bloc, const Stream<NotificationsState>.empty(), initialState: const NotificationsState.loaded([]));

    await tester.pumpWidget(wrap(const NotificationsScreen()));

    expect(find.text('Nenhuma notificação ainda.'), findsOneWidget);
  });
}
