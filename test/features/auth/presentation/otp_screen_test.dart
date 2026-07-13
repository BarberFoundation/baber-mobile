import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/auth/presentation/auth_bloc.dart';
import 'package:baber_mobile/features/auth/presentation/auth_event.dart';
import 'package:baber_mobile/features/auth/presentation/auth_state.dart';
import 'package:baber_mobile/features/auth/presentation/otp_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(const PhoneSubmitted(''));
    registerFallbackValue(const CodeSubmitted(phone: '', code: ''));
  });

  setUp(() {
    bloc = MockAuthBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
      );

  testWidgets('tapping Confirmar dispatches CodeSubmitted with phone from state', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'));

    await tester.pumpWidget(wrap(const OtpScreen()));
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Confirmar'));

    verify(() => bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '123456'))).called(1);
  });

  testWidgets('resend button starts disabled with 30s countdown', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'));

    await tester.pumpWidget(wrap(const OtpScreen()));

    expect(find.text('Reenviar em 30 s'), findsOneWidget);
  });

  testWidgets('resend button enables after 30s and dispatches PhoneSubmitted on tap', (tester) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'));

    await tester.pumpWidget(wrap(const OtpScreen()));
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('Reenviar código'), findsOneWidget);

    await tester.tap(find.text('Reenviar código'));

    verify(() => bloc.add(const PhoneSubmitted('+5511999999999'))).called(1);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const AuthState(errorMessage: 'código inválido')]),
      initialState: const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'),
    );

    await tester.pumpWidget(wrap(const OtpScreen()));
    await tester.pump();

    expect(find.text('código inválido'), findsOneWidget);
  });
}
