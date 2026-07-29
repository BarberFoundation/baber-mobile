import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/booking/domain/barber.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/booking/presentation/confirm_booking_screen.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

void main() {
  late MockBookingBloc bloc;
  late bool succeededCalled;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const slot = TimeSlot(startTime: '09:00', endTime: '09:30');
  const initialState = BookingState(
    service: service,
    selectedDate: '2026-08-01',
    selectedSlot: slot,
  );

  setUpAll(() {
    registerFallbackValue(const BookingConfirmed(clientName: '', clientPhone: ''));
  });

  setUp(() {
    bloc = MockBookingBloc();
    succeededCalled = false;
  });

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: BlocProvider<BookingBloc>.value(value: bloc, child: child)),
      );

  Widget buildScreen() => ConfirmBookingScreen(
        initialName: 'João',
        initialPhone: '+5511999999999',
        onBookingSucceeded: () => succeededCalled = true,
      );

  testWidgets('shows a ticket header with date chip, weekday/time, service and price', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: initialState);

    await tester.pumpWidget(wrap(buildScreen()));

    // 2026-08-01 is a Saturday.
    expect(find.text('AGO'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('SÁBADO · 09:00'), findsOneWidget);
    expect(find.text('Corte'), findsOneWidget);
    expect(find.textContaining('40'), findsOneWidget);
  });

  testWidgets('shows "com {barbeiro}" under the ticket header when one was selected', (tester) async {
    whenListen(
      bloc,
      const Stream<BookingState>.empty(),
      initialState: const BookingState(
        service: service,
        selectedBarber: Barber(id: 'b1', name: 'Marcos'),
        selectedDate: '2026-08-01',
        selectedSlot: slot,
      ),
    );

    await tester.pumpWidget(wrap(buildScreen()));

    expect(find.text('com Marcos'), findsOneWidget);
  });

  testWidgets('omits the "com" line when no barber was selected', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: initialState);

    await tester.pumpWidget(wrap(buildScreen()));

    expect(find.textContaining('com '), findsNothing);
  });

  testWidgets('pre-fills name and phone fields, tapping Confirmar dispatches BookingConfirmed', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: initialState);

    await tester.pumpWidget(wrap(buildScreen()));
    await tester.tap(find.text('Confirmar'));

    verify(() => bloc.add(const BookingConfirmed(clientName: 'João', clientPhone: '+5511999999999'))).called(1);
  });

  testWidgets('calls onBookingSucceeded when bookingSucceeded becomes true', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([initialState.copyWith(bookingSucceeded: true)]),
      initialState: initialState,
    );

    await tester.pumpWidget(wrap(buildScreen()));
    await tester.pump();

    expect(succeededCalled, isTrue);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        BookingState(
          service: initialState.service,
          selectedDate: initialState.selectedDate,
          selectedSlot: initialState.selectedSlot,
          errorMessage: 'Nenhum barbeiro disponível.',
        ),
      ]),
      initialState: initialState,
    );

    await tester.pumpWidget(wrap(buildScreen()));
    await tester.pump();

    expect(find.text('Nenhum barbeiro disponível.'), findsOneWidget);
  });
}
