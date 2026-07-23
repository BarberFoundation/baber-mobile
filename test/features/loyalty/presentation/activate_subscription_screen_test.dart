import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
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
    tier: 'ESSENCIAL',
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
        ]),
      );

  testWidgets('rejects submit with an invalid CPF and does not dispatch ActivateSubmitted', (tester) async {
    whenListen(bloc, const Stream<ActivateSubscriptionState>.empty(), initialState: const ActivateSubscriptionState());

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(tier: tier, initialName: 'Fulano', initialPhone: '11999998888'),
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
      const ActivateSubscriptionScreen(tier: tier, initialName: 'Fulano', initialPhone: '11999998888'),
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

  testWidgets('navigates to /loyalty when the state becomes activated', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const ActivateSubscriptionState(activated: true)]),
      initialState: const ActivateSubscriptionState(),
    );

    await tester.pumpWidget(wrap(
      const ActivateSubscriptionScreen(tier: tier, initialName: 'Fulano', initialPhone: '11999998888'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hub'), findsOneWidget);
  });
}
