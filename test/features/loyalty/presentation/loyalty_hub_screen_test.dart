import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/loyalty/domain/club_subscription.dart';
import 'package:baber_mobile/features/loyalty/domain/stamp_card.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_hub_screen.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_state.dart';

class MockLoyaltyBloc extends MockBloc<LoyaltyEvent, LoyaltyState> implements LoyaltyBloc {}

void main() {
  late MockLoyaltyBloc bloc;

  setUp(() {
    bloc = MockLoyaltyBloc();
  });

  const stampCard = StampCard(currentStamps: 3, stampsRequired: 10, creditBalanceInCents: 1500);

  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (context, state) => BlocProvider<LoyaltyBloc>.value(value: bloc, child: child)),
          GoRoute(path: '/loyalty/plans', builder: (context, state) => const Scaffold(body: Text('Planos'))),
        ]),
      );

  testWidgets('shows the stamp card progress and credit balance when there is no subscription', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.text('3 / 10'), findsOneWidget);
    expect(find.textContaining('R\$ 15,00'), findsOneWidget);
    expect(find.text('Ver planos'), findsOneWidget);
  });

  testWidgets('disables "Usar crédito" when the balance is zero', (tester) async {
    const zeroBalanceCard = StampCard(currentStamps: 0, stampsRequired: 10, creditBalanceInCents: 0);
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: zeroBalanceCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Usar crédito'));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping "Usar crédito" and confirming dispatches RedeemAllCreditRequested', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));
    await tester.tap(find.text('Usar crédito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(RedeemAllCreditRequested())).called(1);
  });

  testWidgets('navigates to /loyalty/plans when "Ver planos" is tapped', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));
    await tester.tap(find.text('Ver planos'));
    await tester.pumpAndSettle();

    expect(find.text('Planos'), findsOneWidget);
  });

  testWidgets('shows the active subscription card with tier name and quota progress', (tester) async {
    const subscription = ClubSubscription(
      status: 'ACTIVE',
      tierId: 'tier-1',
      currentCycleStart: '2026-07-01',
      currentCycleEnd: '2026-07-31',
      quotas: [SubscriptionQuota(serviceId: 'svc-1', quantityTotal: 2, quantityConsumed: 1)],
    );
    whenListen(
      bloc,
      const Stream<LoyaltyState>.empty(),
      initialState: const LoyaltyState(
        subscription: subscription,
        tiers: [SubscriptionTierView(id: 'tier-1', name: 'ESSENCIAL', services: [], monthlyPriceInCents: 8000, discountPercentage: 0)],
        services: [Service(id: 'svc-1', name: 'Corte', priceInCents: 4000, durationMinutes: 30)],
      ),
    );

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.text('PLANO ESSENCIAL'), findsOneWidget);
    expect(find.textContaining('Corte: 1/2 usado no ciclo'), findsOneWidget);
  });

  testWidgets('tapping "Cancelar assinatura" and confirming dispatches CancelSubscriptionRequested', (tester) async {
    const subscription = ClubSubscription(
      status: 'ACTIVE',
      tierId: 'tier-1',
      currentCycleStart: '2026-07-01',
      currentCycleEnd: '2026-07-31',
      quotas: [],
    );
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(subscription: subscription));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));
    await tester.tap(find.text('Cancelar assinatura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(CancelSubscriptionRequested())).called(1);
  });

  testWidgets('shows a past-due banner when the subscription is PAST_DUE', (tester) async {
    const subscription = ClubSubscription(
      status: 'PAST_DUE',
      tierId: 'tier-1',
      currentCycleStart: '2026-07-01',
      currentCycleEnd: '2026-07-31',
      quotas: [],
    );
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(subscription: subscription));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.textContaining('Pagamento atrasado'), findsOneWidget);
  });
}
