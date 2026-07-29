import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_bloc.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_event.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_screen.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_state.dart';

class MockMyAppointmentsBloc extends MockBloc<MyAppointmentsEvent, MyAppointmentsState>
    implements MyAppointmentsBloc {}

void main() {
  late MockMyAppointmentsBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadMyAppointments());
    registerFallbackValue(const CancelAppointmentRequested(''));
  });

  setUp(() {
    bloc = MockMyAppointmentsBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<MyAppointmentsBloc>.value(value: bloc, child: child),
      );

  const future = Appointment(
    id: 'appt-1', serviceId: 's1', date: '2999-01-01',
    startTime: '09:00', endTime: '09:30', status: AppointmentStatus.confirmed,
  );
  const past = Appointment(
    id: 'appt-2', serviceId: 's1', date: '2000-01-01',
    startTime: '09:00', endTime: '09:30', status: AppointmentStatus.completed,
  );

  testWidgets('dispatches LoadMyAppointments on init', (tester) async {
    whenListen(bloc, const Stream<MyAppointmentsState>.empty(), initialState: const MyAppointmentsState.initial());

    await tester.pumpWidget(wrap(const MyAppointmentsScreen()));

    verify(() => bloc.add(LoadMyAppointments())).called(1);
  });

  testWidgets('shows a humanized Portuguese date instead of the raw ISO string', (tester) async {
    // 2026-07-31 is a Friday.
    const appointment = Appointment(
      id: 'appt-3', serviceId: 's1', date: '2026-07-31',
      startTime: '15:30', endTime: '16:00', status: AppointmentStatus.confirmed,
    );
    whenListen(
      bloc,
      const Stream<MyAppointmentsState>.empty(),
      initialState: const MyAppointmentsState(appointments: [appointment], serviceNames: {'s1': 'Corte'}),
    );

    await tester.pumpWidget(wrap(const MyAppointmentsScreen()));

    expect(find.textContaining('Sex, 31 jul · 15:30'), findsOneWidget);
    expect(find.text('2026-07-31 · 15:30'), findsNothing);
  });

  testWidgets('splits appointments into Próximas and Histórico sections', (tester) async {
    whenListen(
      bloc,
      const Stream<MyAppointmentsState>.empty(),
      initialState: const MyAppointmentsState.loaded(appointments: [future, past], serviceNames: {'s1': 'Corte'}),
    );

    await tester.pumpWidget(wrap(const MyAppointmentsScreen()));

    expect(find.text('Próximas'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Corte'), findsNWidgets(2));
  });

  testWidgets('shows Cancelar button only for a cancellable future appointment', (tester) async {
    whenListen(
      bloc,
      const Stream<MyAppointmentsState>.empty(),
      initialState: const MyAppointmentsState.loaded(appointments: [future, past], serviceNames: {'s1': 'Corte'}),
    );

    await tester.pumpWidget(wrap(const MyAppointmentsScreen()));

    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('tapping Cancelar then confirming dispatches CancelAppointmentRequested', (tester) async {
    whenListen(
      bloc,
      const Stream<MyAppointmentsState>.empty(),
      initialState: const MyAppointmentsState.loaded(appointments: [future], serviceNames: {'s1': 'Corte'}),
    );

    await tester.pumpWidget(wrap(const MyAppointmentsScreen()));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim, cancelar'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const CancelAppointmentRequested('appt-1'))).called(1);
  });
}
