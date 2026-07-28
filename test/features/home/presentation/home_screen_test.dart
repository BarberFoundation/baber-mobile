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
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/home/presentation/home_bloc.dart';
import 'package:baber_mobile/features/home/presentation/home_event.dart';
import 'package:baber_mobile/features/home/presentation/home_screen.dart';
import 'package:baber_mobile/features/home/presentation/home_state.dart';
import 'package:baber_mobile/shared/theme/theme_cubit.dart';
import 'package:baber_mobile/shared/theme/theme_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockThemeStorage extends Mock implements ThemeStorage {}
class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockAuthRepository authRepository;
  late MockThemeStorage themeStorage;
  late MockHomeBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadHome());
  });

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    authRepository = MockAuthRepository();
    themeStorage = MockThemeStorage();
    bloc = MockHomeBloc();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
    when(() => authRepository.signOut()).thenAnswer((_) async {});
    when(() => themeStorage.readMode()).thenAnswer((_) async => null);
    when(() => themeStorage.saveMode(any())).thenAnswer((_) async {});
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
                create: (_) => SessionCubit(
                  tokenStorage: tokenStorage,
                  tenantStorage: tenantStorage,
                  authRepository: authRepository,
                ),
              ),
              BlocProvider(create: (_) => ThemeCubit(storage: themeStorage)),
            ],
            child: const HomeScreen(),
          ),
        ),
        GoRoute(path: '/tenant-selection', builder: (context, state) => const Scaffold(body: Text('tenant selection'))),
        GoRoute(path: '/services', builder: (context, state) => const Scaffold(body: Text('services'))),
        GoRoute(path: '/appointments', builder: (context, state) => const Scaffold(body: Text('appointments'))),
        GoRoute(path: '/notifications', builder: (context, state) => const Scaffold(body: Text('notifications'))),
        GoRoute(path: '/loyalty', builder: (context, state) => const Scaffold(body: Text('loyalty'))),
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

  testWidgets('shows empty-state card with Agendar agora CTA when there is no next appointment', (tester) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: const HomeState(userName: 'João'));

    await pumpHome(tester);

    expect(find.text('Agendar agora'), findsOneWidget);

    await tester.tap(find.text('Agendar agora'));
    await tester.pumpAndSettle();

    expect(find.text('services'), findsOneWidget);
  });

  testWidgets('shows Assine o Clube banner when there is no active subscription', (tester) async {
    whenListen(
      bloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeState(userName: 'João', hasActiveSubscription: false),
    );

    await pumpHome(tester);

    expect(find.text('Assine o Clube'), findsOneWidget);

    await tester.tap(find.text('Assine o Clube'));
    await tester.pumpAndSettle();

    expect(find.text('loyalty'), findsOneWidget);
  });

  testWidgets('hides Assine o Clube banner when the user already has a subscription', (tester) async {
    whenListen(
      bloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeState(userName: 'João', hasActiveSubscription: true),
    );

    await pumpHome(tester);

    expect(find.text('Assine o Clube'), findsNothing);
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
