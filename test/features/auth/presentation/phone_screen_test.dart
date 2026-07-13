import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/auth/presentation/auth_bloc.dart';
import 'package:baber_mobile/features/auth/presentation/auth_event.dart';
import 'package:baber_mobile/features/auth/presentation/auth_state.dart';
import 'package:baber_mobile/features/auth/presentation/phone_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(const PhoneSubmitted(''));
  });

  setUp(() {
    bloc = MockAuthBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
      );

  GoRouter routerFor(MockAuthBloc bloc) => GoRouter(
        initialLocation: '/phone',
        routes: [
          GoRoute(
            path: '/phone',
            builder: (_, _) => BlocProvider<AuthBloc>.value(value: bloc, child: const PhoneScreen()),
          ),
          GoRoute(path: '/otp', builder: (_, _) => const Scaffold(body: Text('OTP_SCREEN'))),
          GoRoute(path: '/name', builder: (_, _) => const Scaffold(body: Text('NAME_SCREEN'))),
          GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('HOME_SCREEN'))),
          GoRoute(path: '/tenant-selection', builder: (_, _) => const Scaffold(body: Text('TENANT'))),
        ],
      );

  testWidgets('tapping Continuar dispatches PhoneSubmitted', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState.initial());

    await tester.pumpWidget(wrap(const PhoneScreen()));
    await tester.enterText(find.byType(TextField), '+5511999999999');
    await tester.tap(find.text('Continuar'));

    verify(() => bloc.add(const PhoneSubmitted('+5511999999999'))).called(1);
  });

  testWidgets('shows spinner and disables button when loading', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState(isLoading: true));

    await tester.pumpWidget(wrap(const PhoneScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const AuthState(errorMessage: 'telefone inválido')]),
      initialState: const AuthState.initial(),
    );

    await tester.pumpWidget(wrap(const PhoneScreen()));
    await tester.pump();

    expect(find.text('telefone inválido'), findsOneWidget);
  });

  testWidgets('navega para /home quando auto-verificação autentica usuário com nome', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        const AuthState(isLoading: true),
        const AuthState(authenticatedUser: AuthUser(id: 'u1', name: 'Gab', phone: '+5511999999999')),
      ]),
      initialState: const AuthState.initial(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: routerFor(bloc)));
    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('navega para /name quando auto-verificação autentica usuário sem nome', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        const AuthState(isLoading: true),
        const AuthState(userNeedingName: AuthUser(id: 'u1', name: null, phone: '+5511999999999')),
      ]),
      initialState: const AuthState.initial(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: routerFor(bloc)));
    await tester.pumpAndSettle();

    expect(find.text('NAME_SCREEN'), findsOneWidget);
  });
}
