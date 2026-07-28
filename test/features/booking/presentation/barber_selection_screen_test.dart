import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/booking/domain/barber.dart';
import 'package:baber_mobile/features/booking/domain/barber_repository.dart';
import 'package:baber_mobile/features/booking/presentation/barber_selection_screen.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingBloc extends MockBloc<BookingEvent, BookingState> implements BookingBloc {}

class MockBarberRepository extends Mock implements BarberRepository {}

void main() {
  late MockBookingBloc bloc;
  late MockBarberRepository barberRepository;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const barbers = [Barber(id: 'b1', name: 'João'), Barber(id: 'b2', name: 'Marcos')];

  setUpAll(() {
    registerFallbackValue(const BarberSelected(null));
  });

  setUp(() {
    bloc = MockBookingBloc();
    barberRepository = MockBarberRepository();
    when(() => barberRepository.listBarbers()).thenAnswer((_) async => const Right(barbers));
  });

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: BlocProvider<BookingBloc>.value(value: bloc, child: child)),
      );

  testWidgets('shows "Qualquer barbeiro disponível" and the fetched barbers', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(BarberSelectionScreen(repository: barberRepository)));
    await tester.pump();

    expect(find.text('Qualquer barbeiro disponível'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Marcos'), findsOneWidget);
  });

  testWidgets('tapping a barber dispatches BarberSelected with that barber', (tester) async {
    whenListen(bloc, const Stream<BookingState>.empty(), initialState: const BookingState(service: service));

    await tester.pumpWidget(wrap(BarberSelectionScreen(repository: barberRepository)));
    await tester.pump();
    await tester.tap(find.text('João'));

    verify(() => bloc.add(const BarberSelected(Barber(id: 'b1', name: 'João')))).called(1);
  });

  testWidgets('tapping "Qualquer barbeiro disponível" dispatches BarberSelected(null)', (tester) async {
    whenListen(
      bloc,
      const Stream<BookingState>.empty(),
      initialState: const BookingState(service: service, selectedBarber: Barber(id: 'b1', name: 'João')),
    );

    await tester.pumpWidget(wrap(BarberSelectionScreen(repository: barberRepository)));
    await tester.pump();
    await tester.tap(find.text('Qualquer barbeiro disponível'));

    verify(() => bloc.add(const BarberSelected(null))).called(1);
  });
}
