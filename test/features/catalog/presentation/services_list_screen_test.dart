import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/presentation/services_bloc.dart';
import 'package:baber_mobile/features/catalog/presentation/services_event.dart';
import 'package:baber_mobile/features/catalog/presentation/services_list_screen.dart';
import 'package:baber_mobile/features/catalog/presentation/services_state.dart';

class MockServicesBloc extends MockBloc<ServicesEvent, ServicesState> implements ServicesBloc {}

void main() {
  late MockServicesBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadServices());
  });

  setUp(() {
    bloc = MockServicesBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<ServicesBloc>.value(value: bloc, child: child),
      );

  testWidgets('dispatches LoadServices on init', (tester) async {
    whenListen(bloc, const Stream<ServicesState>.empty(), initialState: const ServicesState.initial());

    await tester.pumpWidget(wrap(const ServicesListScreen()));

    verify(() => bloc.add(LoadServices())).called(1);
  });

  testWidgets('shows spinner while loading', (tester) async {
    whenListen(bloc, const Stream<ServicesState>.empty(), initialState: const ServicesState.loading());

    await tester.pumpWidget(wrap(const ServicesListScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders service list with name and formatted price', (tester) async {
    const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
    whenListen(bloc, const Stream<ServicesState>.empty(), initialState: const ServicesState.loaded([service]));

    await tester.pumpWidget(wrap(const ServicesListScreen()));

    expect(find.text('Corte'), findsOneWidget);
    expect(find.textContaining('R\$ 40,00'), findsOneWidget);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const ServicesState.error('falha ao carregar')]),
      initialState: const ServicesState.initial(),
    );

    await tester.pumpWidget(wrap(const ServicesListScreen()));
    await tester.pump();

    expect(find.text('falha ao carregar'), findsOneWidget);
  });
}
