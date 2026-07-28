import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/booking/presentation/schedule_selection_screen.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

void main() {
  late MockBookingBloc bloc;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const slot = TimeSlot(startTime: '09:00', endTime: '09:30');

  setUpAll(() {
    registerFallbackValue(const SlotSelected(slot));
    registerFallbackValue(const DateSelected(''));
  });

  setUp(() {
    bloc = MockBookingBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: BlocProvider<BookingBloc>.value(value: bloc, child: child)),
      );

  testWidgets('renders a 4-day date strip and dispatches DateSelected on tap', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));

    expect(find.byType(InkWell), findsNWidgets(4));

    await tester.tap(find.byType(InkWell).first);

    verify(() => bloc.add(any(that: isA<DateSelected>()))).called(1);
  });

  testWidgets('shows spinner while loading slots', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', isLoading: true));

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders available slots and dispatches SlotSelected on tap', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', slots: [slot]));

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));
    await tester.tap(find.text('09:00'));

    verify(() => bloc.add(const SlotSelected(slot))).called(1);
  });

  testWidgets('shows message when no slots are available for the selected date', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(),
        initialState: const BookingState(service: service, selectedDate: '2026-08-01', slots: []));

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));

    expect(find.text('Nenhum horário disponível nesta data.'), findsOneWidget);
  });

  testWidgets('shows error with retry button when errorMessage is present', (tester) async {
    whenListen(
      bloc,
      const Stream<BookingState>.empty(),
      initialState: const BookingState(service: service, selectedDate: '2026-07-21', errorMessage: 'sem rede'),
    );

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));

    expect(find.text('Não foi possível carregar os horários.'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));

    verify(() => bloc.add(const DateSelected('2026-07-21'))).called(1);
  });

  testWidgets('prompts to pick a date before any date is selected', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(const ScheduleSelectionScreen()));

    expect(find.text('Escolha uma data para ver os horários.'), findsOneWidget);
  });
}
