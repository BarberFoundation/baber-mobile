import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/booking/domain/barber.dart';
import 'package:baber_mobile/features/booking/domain/barber_repository.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_flow_screen.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

class MockBarberRepository extends Mock implements BarberRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockBookingBloc bloc;
  late MockBarberRepository barberRepository;
  late MockProfileRepository profileRepository;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const slot = TimeSlot(startTime: '09:00', endTime: '09:30');

  setUpAll(() {
    registerFallbackValue(const BarberSelected(null));
  });

  setUp(() {
    bloc = MockBookingBloc();
    barberRepository = MockBarberRepository();
    profileRepository = MockProfileRepository();
    when(() => barberRepository.listBarbers()).thenAnswer((_) async => const Right(<Barber>[]));
    when(() => profileRepository.getMe())
        .thenAnswer((_) async => const Right(AuthUser(id: 'u1', name: 'João', phone: '+5511999999999')));
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<BookingBloc>.value(value: bloc, child: child),
      );

  Widget buildFlow() => BookingFlowScreen(barberRepository: barberRepository, profileRepository: profileRepository);

  testWidgets('starts on the Barbeiro step with 5 step dots and Continuar enabled', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(buildFlow()));
    await tester.pump();

    expect(find.text('Qualquer barbeiro disponível'), findsOneWidget);
    expect(find.byKey(const ValueKey('booking-step-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('booking-step-dot-4')), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continuar'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Continuar advances to the Horário step, disabled until a slot is chosen', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(buildFlow()));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha uma data para ver os horários.'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continuar'));
    expect(button.onPressed, isNull);
  });

  testWidgets('Continuar enables on the Horário step once a slot is selected', (tester) async {
    whenListen(
      bloc,
      const Stream<BookingState>.empty(),
      initialState: const BookingState(service: service, selectedDate: '2026-08-01', selectedSlot: slot),
    );

    await tester.pumpWidget(wrap(buildFlow()));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continuar'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('advancing to Confirmar hides the flow-level Continuar bar', (tester) async {
    whenListen(
      bloc,
      const Stream<BookingState>.empty(),
      initialState: const BookingState(service: service, selectedDate: '2026-08-01', selectedSlot: slot),
    );

    await tester.pumpWidget(wrap(buildFlow()));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Continuar'), findsNothing);
    expect(find.text('Confirmar'), findsOneWidget);
  });
}
