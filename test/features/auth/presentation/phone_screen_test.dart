import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
