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
import 'package:baber_mobile/features/booking/presentation/slot_selection_screen.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

void main() {
  late MockBookingBloc bloc;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const slot = TimeSlot(startTime: '09:00', endTime: '09:30');

  setUpAll(() {
    registerFallbackValue(const SlotSelected(slot));
  });

  setUp(() {
    bloc = MockBookingBloc();
  });

  // Wrapped with a real GoRouter (rather than a bare MaterialApp) because
  // SlotSelectionScreen navigates via context.push on tap; without a
  // GoRouter ancestor that call throws "No GoRouter found in context".
  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => BlocProvider<BookingBloc>.value(value: bloc, child: child),
            ),
            GoRoute(path: '/booking/confirm', builder: (_, __) => const SizedBox()),
          ],
        ),
      );

  testWidgets('shows spinner while loading', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', isLoading: true));

    await tester.pumpWidget(wrap(const SlotSelectionScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders available slots and dispatches SlotSelected on tap', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', slots: [slot]));

    await tester.pumpWidget(wrap(const SlotSelectionScreen()));
    await tester.tap(find.text('09:00'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const SlotSelected(slot))).called(1);
  });

  testWidgets('shows message when no slots are available', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', slots: []));

    await tester.pumpWidget(wrap(const SlotSelectionScreen()));

    expect(find.text('Nenhum horário disponível nesta data.'), findsOneWidget);
  });
}
