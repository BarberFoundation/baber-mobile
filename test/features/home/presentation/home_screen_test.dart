import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/session_cubit.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';
import 'package:baber_mobile/features/home/presentation/home_bloc.dart';
import 'package:baber_mobile/features/home/presentation/home_event.dart';
import 'package:baber_mobile/features/home/presentation/home_screen.dart';
import 'package:baber_mobile/features/home/presentation/home_state.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockHomeBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadHome());
  });

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    bloc = MockHomeBloc();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
  });

  Future<GoRouter> pumpHome(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeBloc>.value(value: bloc),
              BlocProvider(
                create: (_) => SessionCubit(tokenStorage: tokenStorage, tenantStorage: tenantStorage),
              ),
            ],
            child: const HomeScreen(),
          ),
        ),
        GoRoute(path: '/tenant-selection', builder: (context, state) => const Scaffold(body: Text('tenant selection'))),
        GoRoute(path: '/services', builder: (context, state) => const Scaffold(body: Text('services'))),
        GoRoute(path: '/appointments', builder: (context, state) => const Scaffold(body: Text('appointments'))),
        GoRoute(path: '/notifications', builder: (context, state) => const Scaffold(body: Text('notifications'))),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    return router;
  }

  testWidgets('dispatches LoadHome on init', (tester) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: const HomeState());

    await pumpHome(tester);

    verify(() => bloc.add(LoadHome())).called(1);
  });

  testWidgets('renders welcome text with user name', (tester) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: const HomeState(userName: 'João'));

    await pumpHome(tester);

    expect(find.text('Bem-vindo,'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
  });

  testWidgets('renders next appointment card when present', (tester) async {
    final appointment = Appointment(
      id: 'appt-1', serviceId: 's1', date: '2999-01-01',
      startTime: '09:00', endTime: '09:30', status: AppointmentStatus.confirmed,
    );
    whenListen(
      bloc,
      const Stream<HomeState>.empty(),
      initialState: HomeState(userName: 'João', nextAppointment: appointment, nextAppointmentServiceName: 'Corte'),
    );

    await pumpHome(tester);

    expect(find.textContaining('Corte'), findsOneWidget);
  });

  testWidgets('tapping shortcuts navigates to services/appointments/notifications', (tester) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: const HomeState(userName: 'João'));

    await pumpHome(tester);
    await tester.tap(find.text('Serviços'));
    await tester.pumpAndSettle();

    expect(find.text('services'), findsOneWidget);
  });

  testWidgets('tapping logout clears storages and navigates to tenant-selection', (tester) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: const HomeState(userName: 'João'));

    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    verify(() => tokenStorage.clear()).called(1);
    verify(() => tenantStorage.clear()).called(1);
    expect(find.text('tenant selection'), findsOneWidget);
  });
}
