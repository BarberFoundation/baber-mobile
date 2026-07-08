import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/booking/presentation/confirm_booking_screen.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

void main() {
  late MockBookingBloc bloc;
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
  });

  // Wrapped with a real GoRouter (rather than a bare MaterialApp) because
  // ConfirmBookingScreen navigates via context.go on bookingSucceeded; without
  // a GoRouter ancestor that call throws "No GoRouter found in context".
  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<BookingBloc>.value(value: bloc, child: child),
            ),
            GoRoute(path: '/booking/success', builder: (context, state) => const SizedBox()),
          ],
        ),
      );

  testWidgets('shows service name, date and slot summary', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: initialState);

    await tester.pumpWidget(wrap(const ConfirmBookingScreen(initialName: 'João', initialPhone: '+5511999999999')));

    expect(find.textContaining('Corte'), findsOneWidget);
    expect(find.textContaining('09:00'), findsOneWidget);
  });

  testWidgets('pre-fills name and phone fields, tapping Confirmar dispatches BookingConfirmed', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: initialState);

    await tester.pumpWidget(wrap(const ConfirmBookingScreen(initialName: 'João', initialPhone: '+5511999999999')));
    await tester.tap(find.text('Confirmar'));

    verify(() => bloc.add(const BookingConfirmed(clientName: 'João', clientPhone: '+5511999999999'))).called(1);
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

    await tester.pumpWidget(wrap(const ConfirmBookingScreen(initialName: 'João', initialPhone: '+5511999999999')));
    await tester.pump();

    expect(find.text('Nenhum barbeiro disponível.'), findsOneWidget);
  });
}
