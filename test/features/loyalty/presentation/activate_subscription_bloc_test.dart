import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/loyalty/domain/club_subscription.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/pix_payment.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/activate_subscription_state.dart';

class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

void main() {
  late MockLoyaltyRepository repository;

  setUp(() {
    repository = MockLoyaltyRepository();
  });

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
    quotas: [],
  );

  blocTest<ActivateSubscriptionBloc, ActivateSubscriptionState>(
    'emits [loading, activated] with no pixPayment when activation succeeds without a charge',
    build: () {
      when(() => repository.activateSubscription(
            tier: 'ESSENCIAL',
            name: 'Fulano',
            cpfCnpj: '12345678900',
            email: null,
            phone: null,
          )).thenAnswer((_) async => const Right(ActivationResult(subscription: subscription, payment: null)));
      return ActivateSubscriptionBloc(repository: repository, tier: tier);
    },
    act: (bloc) => bloc.add(const ActivateSubmitted(name: 'Fulano', cpfCnpj: '12345678900')),
    expect: () => [
      const ActivateSubscriptionState(isLoading: true),
      const ActivateSubscriptionState(activated: true),
    ],
  );

  blocTest<ActivateSubscriptionBloc, ActivateSubscriptionState>(
    'emits [loading, activated] with pixPayment when activation succeeds with a pro-rata charge',
    build: () {
      const payment = PixPayment(
        paymentId: 'pay_1', encodedImage: 'img', payload: 'copia-e-cola', expirationDate: '2027-01-01',
      );
      when(() => repository.activateSubscription(
            tier: 'ESSENCIAL',
            name: 'Fulano',
            cpfCnpj: '12345678900',
            email: null,
            phone: null,
          )).thenAnswer((_) async => const Right(ActivationResult(subscription: subscription, payment: payment)));
      return ActivateSubscriptionBloc(repository: repository, tier: tier);
    },
    act: (bloc) => bloc.add(const ActivateSubmitted(name: 'Fulano', cpfCnpj: '12345678900')),
    expect: () => [
      const ActivateSubscriptionState(isLoading: true),
      const ActivateSubscriptionState(
        activated: true,
        pixPayment: PixPayment(paymentId: 'pay_1', encodedImage: 'img', payload: 'copia-e-cola', expirationDate: '2027-01-01'),
      ),
    ],
  );

  blocTest<ActivateSubscriptionBloc, ActivateSubscriptionState>(
    'emits [loading, error] when activation fails',
    build: () {
      when(() => repository.activateSubscription(
            tier: 'ESSENCIAL',
            name: 'Fulano',
            cpfCnpj: '12345678900',
            email: null,
            phone: null,
          )).thenAnswer((_) async => const Left(ApiFailure(statusCode: 409, message: 'Assinatura já ativa.')));
      return ActivateSubscriptionBloc(repository: repository, tier: tier);
    },
    act: (bloc) => bloc.add(const ActivateSubmitted(name: 'Fulano', cpfCnpj: '12345678900')),
    expect: () => [
      const ActivateSubscriptionState(isLoading: true),
      const ActivateSubscriptionState(errorMessage: 'Assinatura já ativa.'),
    ],
  );
}
