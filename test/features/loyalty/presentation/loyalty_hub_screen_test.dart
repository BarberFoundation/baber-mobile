import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/session_cubit.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/loyalty/domain/club_subscription.dart';
import 'package:baber_mobile/features/loyalty/domain/stamp_card.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_hub_screen.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_state.dart';
import 'package:baber_mobile/shared/widgets/ring_confetti_overlay.dart';
import 'package:baber_mobile/shared/widgets/stamp_grid.dart';

class MockLoyaltyBloc extends MockBloc<LoyaltyEvent, LoyaltyState> implements LoyaltyBloc {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLoyaltyBloc bloc;
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockAuthRepository authRepository;

  setUp(() {
    bloc = MockLoyaltyBloc();
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    authRepository = MockAuthRepository();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => authRepository.signOut()).thenAnswer((_) async {});
  });

  const stampCard = StampCard(currentStamps: 3, stampsRequired: 10, creditBalanceInCents: 1500);

  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<LoyaltyBloc>.value(value: bloc),
                BlocProvider(
                  create: (_) => SessionCubit(
                    tokenStorage: tokenStorage,
                    tenantStorage: tenantStorage,
                    authRepository: authRepository,
                  ),
                ),
              ],
              child: child,
            ),
          ),
          GoRoute(path: '/loyalty/plans', builder: (context, state) => const Scaffold(body: Text('Planos'))),
          GoRoute(path: '/phone', builder: (context, state) => const Scaffold(body: Text('phone'))),
        ]),
      );

  testWidgets('shows the stamp card progress and credit balance when there is no subscription', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.text('3 / 10'), findsOneWidget);
    expect(find.textContaining('R\$ 15,00'), findsOneWidget);
    expect(find.text('Ver planos'), findsOneWidget);
  });

  testWidgets('shows the 10-dot stamp grid and a "faltam N selos" message when incomplete', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.byType(StampGrid), findsOneWidget);
    expect(find.text('Faltam 7 selos para 1 corte grátis'), findsOneWidget);
  });

  testWidgets('shows completion copy and "Resgatar corte grátis" when the card is complete', (tester) async {
    const completeCard = StampCard(currentStamps: 10, stampsRequired: 10, creditBalanceInCents: 0);
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: completeCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.text('Cartão completo! Resgate seu corte grátis'), findsOneWidget);
    expect(find.text('Resgatar corte grátis'), findsOneWidget);
    expect(find.textContaining('Faltam'), findsNothing);
  });

  testWidgets('shows the celebration overlay when the card just completed', (tester) async {
    const completeCard = StampCard(currentStamps: 10, stampsRequired: 10, creditBalanceInCents: 0);
    whenListen(
      bloc,
      const Stream<LoyaltyState>.empty(),
      initialState: const LoyaltyState(stampCard: completeCard, justCompletedCard: true),
    );

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.byType(RingConfettiOverlay), findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-card-completion-pulse')), findsOneWidget);
  });

  testWidgets('does not show the celebration overlay on a normal (non-completing) load', (tester) async {
    whenListen(bloc, const Stream<LoyaltyState>.empty(), initialState: const LoyaltyState(stampCard: stampCard));

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));

    expect(find.byType(RingConfettiOverlay), findsNothing);
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

  testWidgets('tapping "Cancelar assinatura" opens a bottom sheet listing the benefits lost', (tester) async {
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

    expect(find.text('Manter assinatura'), findsOneWidget);
    expect(find.text('Cancelar mesmo assim'), findsOneWidget);
    expect(find.text('2 cortes inclusos por mês'), findsOneWidget);
    expect(find.text('10% de desconto em produtos'), findsOneWidget);
    expect(find.text('Prioridade de horário'), findsOneWidget);
  });

  testWidgets('tapping "Cancelar mesmo assim" in the sheet dispatches CancelSubscriptionRequested', (tester) async {
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
    await tester.tap(find.text('Cancelar mesmo assim'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(CancelSubscriptionRequested())).called(1);
  });

  testWidgets('tapping "Manter assinatura" in the sheet does not dispatch CancelSubscriptionRequested', (tester) async {
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
    await tester.tap(find.text('Manter assinatura'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(CancelSubscriptionRequested()));
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

  testWidgets('sessionExpired clears the Firebase/Google session and navigates to /phone', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const LoyaltyState(sessionExpired: true)]),
      initialState: const LoyaltyState(isLoading: true),
    );

    await tester.pumpWidget(wrap(const LoyaltyHubScreen()));
    await tester.pumpAndSettle();

    verify(() => authRepository.signOut()).called(1);
    verify(() => tokenStorage.clear()).called(1);
    expect(find.text('phone'), findsOneWidget);
  });
}
