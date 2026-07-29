import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/loyalty/domain/pix_payment.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_screen.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_state.dart';

class MockActivateSubscriptionBloc extends MockBloc<ActivateSubscriptionEvent, ActivateSubscriptionState>
    implements ActivateSubscriptionBloc {}

void main() {
  late MockActivateSubscriptionBloc bloc;

  const tier = SubscriptionTierView(
    id: 'tier-1',
    name: 'ESSENCIAL',
    services: [TierServiceItem(serviceId: 'svc-1', quantity: 2, priceInCents: 4000)],
    monthlyPriceInCents: 8000,
    discountPercentage: 0,
  );

  setUpAll(() {
    registerFallbackValue(const ActivateSubmitted(name: '', cpfCnpj: ''));
  });

  setUp(() {
    bloc = MockActivateSubscriptionBloc();
  });

  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => BlocProvider<ActivateSubscriptionBloc>.value(value: bloc, child: child),
          ),
          GoRoute(path: '/loyalty', builder: (context, state) => const Scaffold(body: Text('Hub'))),
          GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/loyalty/pix-payment', builder: (context, state) => const Scaffold(body: Text('Pix Screen'))),
        ]),
      );

  testWidgets('rejects submit with an invalid CPF and does not dispatch ActivateSubmitted', (tester) async {
    whenListen(bloc, const Stream<ActivateSubscriptionState>.empty(), initialState: const ActivateSubscriptionState());

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(
        tier: tier,
        initialName: 'Fulano',
        initialPhone: '11999998888',
        initialEmail: '',
        initialCpfCnpj: '',
      ),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'CPF ou CNPJ'), '123');
    await tester.tap(find.text('Assinar'));
    await tester.pump();

    expect(find.text('Informe um CPF ou CNPJ válido'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('submits ActivateSubmitted with the form data on a valid CPF', (tester) async {
    whenListen(bloc, const Stream<ActivateSubscriptionState>.empty(), initialState: const ActivateSubscriptionState());

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(
        tier: tier,
        initialName: 'Fulano',
        initialPhone: '11999998888',
        initialEmail: '',
        initialCpfCnpj: '',
      ),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'CPF ou CNPJ'), '11144477735');
    await tester.tap(find.text('Assinar'));
    await tester.pump();

    verify(() => bloc.add(const ActivateSubmitted(
          name: 'Fulano',
          cpfCnpj: '11144477735',
          email: null,
          phone: '11999998888',
        ))).called(1);
  });

  testWidgets('navigates to /home when the state becomes activated with no pending payment', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const ActivateSubscriptionState(activated: true)]),
      initialState: const ActivateSubscriptionState(),
    );

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(
        tier: tier,
        initialName: 'Fulano',
        initialPhone: '11999998888',
        initialEmail: '',
        initialCpfCnpj: '',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('pushes /loyalty/pix-payment (keeping the back stack) when activation includes a PIX charge', (tester) async {
    const payment = PixPayment(
      paymentId: 'pay_1', encodedImage: 'img', payload: 'copia-e-cola', expirationDate: '2027-01-01',
    );
    whenListen(
      bloc,
      Stream.fromIterable([const ActivateSubscriptionState(activated: true, pixPayment: payment)]),
      initialState: const ActivateSubscriptionState(),
    );

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(
        tier: tier,
        initialName: 'Fulano',
        initialPhone: '11999998888',
        initialEmail: '',
        initialCpfCnpj: '',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pix Screen'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isTrue);
  });
}
