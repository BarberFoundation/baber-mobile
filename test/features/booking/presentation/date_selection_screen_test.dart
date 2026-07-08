import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/booking/presentation/date_selection_screen.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

void main() {
  late MockBookingBloc bloc;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);

  setUpAll(() {
    registerFallbackValue(const DateSelected('2026-08-01'));
  });

  setUp(() {
    bloc = MockBookingBloc();
  });

  // Wrapped with a real GoRouter (rather than a bare MaterialApp) because
  // DateSelectionScreen navigates via context.push on tap; without a
  // GoRouter ancestor that call throws "No GoRouter found in context".
  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<BookingBloc>.value(value: bloc, child: child),
            ),
            GoRoute(path: '/booking/slots', builder: (context, state) => const SizedBox()),
          ],
        ),
      );

  testWidgets('renders 30 selectable upcoming days', (tester) async {
    // Enlarge the test surface so all 30 ListTiles are laid out simultaneously;
    // ListView.builder only builds items within the viewport, and 30 tiles
    // don't fit in the default 800x600 test surface.
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(const DateSelectionScreen()));

    expect(find.byType(ListTile), findsNWidgets(30));
  });

  testWidgets('tapping a day dispatches DateSelected', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(const DateSelectionScreen()));
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    verify(() => bloc.add(any(that: isA<DateSelected>()))).called(1);
  });
}
