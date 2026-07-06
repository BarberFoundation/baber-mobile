import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/auth/presentation/auth_bloc.dart';
import 'package:baber_mobile/features/auth/presentation/auth_event.dart';
import 'package:baber_mobile/features/auth/presentation/auth_state.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/auth/presentation/name_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(const NameSubmitted(''));
  });

  setUp(() {
    bloc = MockAuthBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
      );

  testWidgets('tapping Continuar dispatches NameSubmitted', (tester) async {
    const user = AuthUser(id: 'u1', name: null, phone: '+5511999999999');
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: AuthState.needsName(user));

    await tester.pumpWidget(wrap(const NameScreen()));
    await tester.enterText(find.byType(TextField), 'João');
    await tester.tap(find.text('Continuar'));

    verify(() => bloc.add(const NameSubmitted('João'))).called(1);
  });

  testWidgets('shows spinner and disables button when loading', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState.loading());

    await tester.pumpWidget(wrap(const NameScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const AuthState.error('nome inválido')]),
      initialState: const AuthState.initial(),
    );

    await tester.pumpWidget(wrap(const NameScreen()));
    await tester.pump();

    expect(find.text('nome inválido'), findsOneWidget);
  });
}
