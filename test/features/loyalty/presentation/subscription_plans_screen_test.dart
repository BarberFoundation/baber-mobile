import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_screen.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_state.dart';

class MockSubscriptionPlansBloc extends MockBloc<SubscriptionPlansEvent, SubscriptionPlansState>
    implements SubscriptionPlansBloc {}

void main() {
  late MockSubscriptionPlansBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadSubscriptionPlans());
  });

  setUp(() {
    bloc = MockSubscriptionPlansBloc();
  });

  const tier = SubscriptionTierView(
    id: 'tier-1',
    name: 'ESSENCIAL',
    services: [TierServiceItem(serviceId: 'svc-1', quantity: 2, priceInCents: 4000)],
    monthlyPriceInCents: 8000,
    discountPercentage: 0,
  );

  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => BlocProvider<SubscriptionPlansBloc>.value(value: bloc, child: child),
          ),
          GoRoute(path: '/loyalty/activate', builder: (context, state) => const Scaffold(body: Text('Ativar'))),
        ]),
      );

  testWidgets('dispatches LoadSubscriptionPlans on init', (tester) async {
    whenListen(bloc, const Stream<SubscriptionPlansState>.empty(), initialState: const SubscriptionPlansState.initial());

    await tester.pumpWidget(wrap(const SubscriptionPlansScreen()));

    verify(() => bloc.add(LoadSubscriptionPlans())).called(1);
  });

  testWidgets('lists the available tiers with name and price', (tester) async {
    whenListen(bloc, const Stream<SubscriptionPlansState>.empty(), initialState: const SubscriptionPlansState.loaded([tier]));

    await tester.pumpWidget(wrap(const SubscriptionPlansScreen()));

    expect(find.text('ESSENCIAL'), findsOneWidget);
    expect(find.textContaining('R\$ 80,00'), findsOneWidget);
  });

  testWidgets('navigates to /loyalty/activate when a plan is tapped', (tester) async {
    whenListen(bloc, const Stream<SubscriptionPlansState>.empty(), initialState: const SubscriptionPlansState.loaded([tier]));

    await tester.pumpWidget(wrap(const SubscriptionPlansScreen()));
    await tester.tap(find.text('Assinar'));
    await tester.pumpAndSettle();

    expect(find.text('Ativar'), findsOneWidget);
  });
}
