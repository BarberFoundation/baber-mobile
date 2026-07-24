import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/subscription_plans_state.dart';

class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

void main() {
  late MockLoyaltyRepository repository;

  setUp(() {
    repository = MockLoyaltyRepository();
  });

  const tier = SubscriptionTierView(
    id: 'tier-1',
    name: 'ESSENCIAL',
    services: [TierServiceItem(serviceId: 'svc-1', quantity: 2, priceInCents: 4000)],
    monthlyPriceInCents: 8000,
    discountPercentage: 0,
  );

  blocTest<SubscriptionPlansBloc, SubscriptionPlansState>(
    'emits [loading, loaded] when LoadSubscriptionPlans succeeds',
    build: () {
      when(() => repository.getAvailableTiers()).thenAnswer((_) async => const Right([tier]));
      return SubscriptionPlansBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadSubscriptionPlans()),
    expect: () => [
      const SubscriptionPlansState.loading(),
      const SubscriptionPlansState.loaded([tier]),
    ],
  );

  blocTest<SubscriptionPlansBloc, SubscriptionPlansState>(
    'emits [loading, error] when LoadSubscriptionPlans fails',
    build: () {
      when(() => repository.getAvailableTiers())
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 500, message: 'erro interno')));
      return SubscriptionPlansBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadSubscriptionPlans()),
    expect: () => [
      const SubscriptionPlansState.loading(),
      const SubscriptionPlansState.error('erro interno'),
    ],
  );
}
