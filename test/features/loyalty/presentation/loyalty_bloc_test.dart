import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/club_subscription.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/stamp_card.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/loyalty_state.dart';

class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late MockLoyaltyRepository repository;
  late MockServiceRepository serviceRepository;

  const stampCard = StampCard(currentStamps: 3, stampsRequired: 10, creditBalanceInCents: 1500);
  const service = Service(id: 'svc-1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  const tier = SubscriptionTierView(
    id: 'tier-1',
    tier: 'ESSENCIAL',
    services: [TierServiceItem(serviceId: 'svc-1', quantity: 2, priceInCents: 4000)],
    monthlyPriceInCents: 8000,
    discountPercentage: 0,
  );
  const subscription = ClubSubscription(
    status: 'ACTIVE',
    tierId: 'tier-1',
    currentCycleStart: '2026-07-01',
    currentCycleEnd: '2026-07-31',
    quotas: [SubscriptionQuota(serviceId: 'svc-1', quantityTotal: 2, quantityConsumed: 1)],
  );

  setUp(() {
    repository = MockLoyaltyRepository();
    serviceRepository = MockServiceRepository();
  });

  LoyaltyBloc build() => LoyaltyBloc(repository: repository, serviceRepository: serviceRepository);

  blocTest<LoyaltyBloc, LoyaltyState>(
    'emits [loading, loaded without subscription] when the client never subscribed',
    build: () {
      when(() => repository.getMyStampCard()).thenAnswer((_) async => const Right(stampCard));
      when(() => repository.getMySubscription()).thenAnswer((_) async => const Right(null));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      return build();
    },
    act: (bloc) => bloc.add(LoadLoyaltyHub()),
    expect: () => [
      const LoyaltyState(isLoading: true),
      const LoyaltyState(stampCard: stampCard, subscription: null, services: [service], tiers: [tier]),
    ],
  );

  blocTest<LoyaltyBloc, LoyaltyState>(
    'emits [loading, loaded with subscription] when the client has an active subscription',
    build: () {
      when(() => repository.getMyStampCard()).thenAnswer((_) async => const Right(stampCard));
      when(() => repository.getMySubscription()).thenAnswer((_) async => const Right(subscription));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      return build();
    },
    act: (bloc) => bloc.add(LoadLoyaltyHub()),
    expect: () => [
      const LoyaltyState(isLoading: true),
      const LoyaltyState(stampCard: stampCard, subscription: subscription, services: [service], tiers: [tier]),
    ],
    verify: (bloc) {
      expect(bloc.state.tierNameFor('tier-1'), 'ESSENCIAL');
      expect(bloc.state.serviceNameFor('svc-1'), 'Corte');
    },
  );

  blocTest<LoyaltyBloc, LoyaltyState>(
    'emits [loading, error] when the stamp card fetch fails',
    build: () {
      when(() => repository.getMyStampCard())
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 500, message: 'erro interno')));
      when(() => repository.getMySubscription()).thenAnswer((_) async => const Right(null));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      return build();
    },
    act: (bloc) => bloc.add(LoadLoyaltyHub()),
    expect: () => [
      const LoyaltyState(isLoading: true),
      const LoyaltyState(errorMessage: 'erro interno'),
    ],
  );

  blocTest<LoyaltyBloc, LoyaltyState>(
    'RedeemAllCreditRequested zeroes the credit balance on success',
    build: () {
      when(() => repository.getMyStampCard()).thenAnswer((_) async => const Right(stampCard));
      when(() => repository.getMySubscription()).thenAnswer((_) async => const Right(null));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      when(() => repository.redeemCredit(1500)).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (bloc) => bloc..add(LoadLoyaltyHub())..add(RedeemAllCreditRequested()),
    skip: 2,
    expect: () => [
      isA<LoyaltyState>().having((s) => s.actionInProgress, 'actionInProgress', true),
      isA<LoyaltyState>().having((s) => s.stampCard?.creditBalanceInCents, 'creditBalanceInCents', 0),
    ],
  );

  blocTest<LoyaltyBloc, LoyaltyState>(
    'CancelSubscriptionRequested clears the subscription on success',
    build: () {
      when(() => repository.getMyStampCard()).thenAnswer((_) async => const Right(stampCard));
      when(() => repository.getMySubscription()).thenAnswer((_) async => const Right(subscription));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      when(() => repository.cancelSubscription()).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (bloc) => bloc..add(LoadLoyaltyHub())..add(CancelSubscriptionRequested()),
    skip: 2,
    expect: () => [
      isA<LoyaltyState>().having((s) => s.actionInProgress, 'actionInProgress', true),
      isA<LoyaltyState>().having((s) => s.subscription, 'subscription', isNull),
    ],
  );
}
