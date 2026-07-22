# Loyalty (cartão fidelidade + clube de assinatura) no mobile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trazer o módulo loyalty (cartão fidelidade + clube de assinatura), que já existe completo na API, pro app mobile CLIENT — incluindo 1 endpoint novo na API pra listar planos com preço calculado (hoje só existe versão ADMIN, sem preço).

**Architecture:** Backend: 1 use case + 1 endpoint novo no módulo `loyalty` já existente (monorepo `baber`, repo separado do mobile). Mobile: feature `loyalty` nova em `baber-mobile`, seguindo exatamente o padrão já usado por `catalog`/`booking` (domain/data/presentation, 1 bloc por tela, repositórios via Dio, telas via GoRouter). Design completo em `docs/superpowers/specs/2026-07-21-loyalty-design.md` (mesmo repo mobile).

**Tech Stack:** Backend: NestJS 11 + Drizzle + Jest. Mobile: Flutter, flutter_bloc, dartz (Either), dio, go_router, mocktail/bloc_test.

**Repos:**
- **Backend** (Tasks 1-3): `C:\Users\gabry\Documents\baber` (monorepo, `apps/api`)
- **Mobile** (Tasks 4-15): `C:\Users\gabry\Documents\baber-mobile`

---

## Task 1: `GetAvailableSubscriptionTiersUseCase` (backend)

**Repo:** `baber`

**Files:**
- Create: `apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.ts`
- Test: `apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.spec.ts`

- [ ] **Step 1: Write the failing test**

```ts
// apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.spec.ts
import { GetAvailableSubscriptionTiersUseCase } from './get-available-subscription-tiers.use-case';
import { SubscriptionTier } from '../../domain/entities/subscription-tier.entity';

describe('GetAvailableSubscriptionTiersUseCase', () => {
  function makeTier(overrides: { tier: 'ESSENCIAL' | 'JOGADOR' | 'LENDARIO'; isActive: boolean; discountPercentage?: number }) {
    return SubscriptionTier.create({
      tenantId: 't1',
      tier: overrides.tier,
      services: [{ serviceId: 'svc-1', quantity: 2 }],
      discountPercentage: overrides.discountPercentage ?? 0,
      isActive: overrides.isActive,
    });
  }

  it('returns only active tiers, with id, computed price and per-service price', async () => {
    const active = makeTier({ tier: 'ESSENCIAL', isActive: true, discountPercentage: 10 });
    const inactive = makeTier({ tier: 'JOGADOR', isActive: false });
    const tierRepo = { findByTenantId: jest.fn().mockResolvedValue([active, inactive]) };
    const catalogRepo = { findById: jest.fn().mockResolvedValue({ priceInCents: 5000 }) };
    const useCase = new GetAvailableSubscriptionTiersUseCase(tierRepo as never, catalogRepo as never);

    const result = await useCase.execute({ tenantId: 't1' });

    expect(result).toHaveLength(1);
    expect(result[0]).toEqual({
      id: active.id,
      tier: 'ESSENCIAL',
      services: [{ serviceId: 'svc-1', quantity: 2, priceInCents: 5000 }],
      monthlyPriceInCents: 9000, // 2 * 5000 = 10000, -10% = 9000
      discountPercentage: 10,
    });
    expect(catalogRepo.findById).toHaveBeenCalledWith('svc-1', 't1');
  });

  it('excludes a tier service that no longer exists in the catalog from the price calculation', async () => {
    const tier = SubscriptionTier.create({
      tenantId: 't1',
      tier: 'ESSENCIAL',
      services: [{ serviceId: 'svc-deleted', quantity: 1 }],
      discountPercentage: 0,
      isActive: true,
    });
    const tierRepo = { findByTenantId: jest.fn().mockResolvedValue([tier]) };
    const catalogRepo = { findById: jest.fn().mockResolvedValue(null) };
    const useCase = new GetAvailableSubscriptionTiersUseCase(tierRepo as never, catalogRepo as never);

    const result = await useCase.execute({ tenantId: 't1' });

    expect(result[0].services).toEqual([]);
    expect(result[0].monthlyPriceInCents).toBe(0);
  });

  it('returns an empty array when there are no active tiers', async () => {
    const tierRepo = { findByTenantId: jest.fn().mockResolvedValue([]) };
    const catalogRepo = { findById: jest.fn() };
    const useCase = new GetAvailableSubscriptionTiersUseCase(tierRepo as never, catalogRepo as never);

    const result = await useCase.execute({ tenantId: 't1' });

    expect(result).toEqual([]);
    expect(catalogRepo.findById).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `apps/api`): `npx jest get-available-subscription-tiers.use-case.spec.ts`
Expected: FAIL — `Cannot find module './get-available-subscription-tiers.use-case'`

- [ ] **Step 3: Write minimal implementation**

```ts
// apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.ts
import { Inject, Injectable } from '@nestjs/common';
import {
  SUBSCRIPTION_TIER_REPOSITORY,
  ISubscriptionTierRepository,
} from '../../domain/repositories/subscription-tier.repository';
import { CATALOG_REPOSITORY, ICatalogRepository } from '../../../catalog/domain/repositories/catalog.repository';
import { SubscriptionTierName } from '../../domain/entities/subscription-tier.entity';

export interface GetAvailableSubscriptionTiersInput {
  tenantId: string;
}

export interface AvailableSubscriptionTierServiceView {
  serviceId: string;
  quantity: number;
  priceInCents: number;
}

export interface AvailableSubscriptionTierView {
  id: string;
  tier: SubscriptionTierName;
  services: AvailableSubscriptionTierServiceView[];
  monthlyPriceInCents: number;
  discountPercentage: number;
}

@Injectable()
export class GetAvailableSubscriptionTiersUseCase {
  constructor(
    @Inject(SUBSCRIPTION_TIER_REPOSITORY) private readonly tierRepo: ISubscriptionTierRepository,
    @Inject(CATALOG_REPOSITORY) private readonly catalogRepo: ICatalogRepository,
  ) {}

  async execute(input: GetAvailableSubscriptionTiersInput): Promise<AvailableSubscriptionTierView[]> {
    const tiers = await this.tierRepo.findByTenantId(input.tenantId);
    const activeTiers = tiers.filter((t) => t.isActive);

    const views: AvailableSubscriptionTierView[] = [];
    for (const tier of activeTiers) {
      const catalogPrices = new Map<string, number>();
      const services: AvailableSubscriptionTierServiceView[] = [];
      for (const item of tier.services) {
        const service = await this.catalogRepo.findById(item.serviceId, input.tenantId);
        if (service) {
          catalogPrices.set(item.serviceId, service.priceInCents);
          services.push({ serviceId: item.serviceId, quantity: item.quantity, priceInCents: service.priceInCents });
        }
      }
      views.push({
        id: tier.id,
        tier: tier.tier,
        services,
        monthlyPriceInCents: tier.calculatePriceInCents(catalogPrices),
        discountPercentage: tier.discountPercentage,
      });
    }
    return views;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx jest get-available-subscription-tiers.use-case.spec.ts`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.ts apps/api/src/modules/loyalty/application/use-cases/get-available-subscription-tiers.use-case.spec.ts
git commit -m "feat(api): add GetAvailableSubscriptionTiersUseCase for client plan browsing"
```

---

## Task 2: `GET /loyalty/club-subscription/tiers/available` endpoint (backend)

**Repo:** `baber`

**Files:**
- Modify: `apps/api/src/modules/loyalty/http/club-subscription.controller.ts`
- Modify: `apps/api/src/modules/loyalty/http/club-subscription.controller.spec.ts`

- [ ] **Step 1: Write the failing test**

Add to `club-subscription.controller.spec.ts`, alongside the other mock objects at the top of the `describe` block:

```ts
  const getAvailableTiers = { execute: jest.fn() };
```

Add `{ provide: GetAvailableSubscriptionTiersUseCase, useValue: getAvailableTiers },` to the `providers` array inside `buildApp`, and add the import at the top:

```ts
import { GetAvailableSubscriptionTiersUseCase } from '../application/use-cases/get-available-subscription-tiers.use-case';
```

Add this test case (anywhere after the `GET /loyalty/club-subscription/tiers returns serialized tiers as ADMIN` test):

```ts
  it('GET /loyalty/club-subscription/tiers/available returns tiers with computed price as CLIENT', async () => {
    app = await buildApp('CLIENT');
    getAvailableTiers.execute.mockResolvedValue([
      {
        id: 'tier-1',
        tier: 'ESSENCIAL',
        services: [{ serviceId: 'svc-1', quantity: 2, priceInCents: 3500 }],
        monthlyPriceInCents: 7000,
        discountPercentage: 0,
      },
    ]);

    const res = await request(app.getHttpServer()).get('/loyalty/club-subscription/tiers/available');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].monthlyPriceInCents).toBe(7000);
    expect(getAvailableTiers.execute).toHaveBeenCalledWith({ tenantId: 't1' });
  });

  it('GET /loyalty/club-subscription/tiers/available rejects ADMIN with 403', async () => {
    app = await buildApp('ADMIN');

    const res = await request(app.getHttpServer()).get('/loyalty/club-subscription/tiers/available');

    expect(res.status).toBe(403);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest club-subscription.controller.spec.ts`
Expected: FAIL — `Nest can't resolve dependencies of the ClubSubscriptionController` (missing provider) or 404 on the new route.

- [ ] **Step 3: Write minimal implementation**

In `club-subscription.controller.ts`, add the import:

```ts
import { GetAvailableSubscriptionTiersUseCase } from '../application/use-cases/get-available-subscription-tiers.use-case';
```

Add to the constructor:

```ts
    private readonly getAvailableTiers: GetAvailableSubscriptionTiersUseCase,
```

Add this handler (place it right after the `tiers()` ADMIN handler, before `activateSubscription`):

```ts
  @Roles('CLIENT')
  @Get('tiers/available')
  async availableTiers(@CurrentUser() user: JwtPayload) {
    return this.getAvailableTiers.execute({ tenantId: user.tenantId });
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx jest club-subscription.controller.spec.ts`
Expected: PASS (all tests, including the 2 new ones)

- [ ] **Step 5: Commit**

```bash
git add apps/api/src/modules/loyalty/http/club-subscription.controller.ts apps/api/src/modules/loyalty/http/club-subscription.controller.spec.ts
git commit -m "feat(api): add GET /loyalty/club-subscription/tiers/available for CLIENT"
```

---

## Task 3: Wire the new use case into `LoyaltyModule`, run full suite (backend)

**Repo:** `baber`

**Files:**
- Modify: `apps/api/src/modules/loyalty/loyalty.module.ts`

- [ ] **Step 1: Add the import and provider**

Add the import near the other use-case imports:

```ts
import { GetAvailableSubscriptionTiersUseCase } from './application/use-cases/get-available-subscription-tiers.use-case';
```

Add `GetAvailableSubscriptionTiersUseCase,` to the `providers` array (next to `GetSubscriptionTiersUseCase,`).

- [ ] **Step 2: Run the full API suite**

Run (from `apps/api`): `npx jest`
Expected: PASS, all suites (previous count 94 suites/408 tests + 5 new tests from Tasks 1-2 = 96 suites/413 tests)

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/modules/loyalty/loyalty.module.ts
git commit -m "chore(api): wire GetAvailableSubscriptionTiersUseCase into LoyaltyModule"
```

---

## Task 4: Domain models (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/domain/stamp_card.dart`
- Create: `lib/features/loyalty/domain/subscription_tier_view.dart`
- Create: `lib/features/loyalty/domain/club_subscription.dart`

No dedicated unit tests for these — matches the existing convention (`lib/features/catalog/domain/service.dart` has no direct test file; its `fromJson`/formatting are exercised through the repository test in Task 5).

- [ ] **Step 1: Create `stamp_card.dart`**

```dart
// lib/features/loyalty/domain/stamp_card.dart
import 'package:equatable/equatable.dart';

class StampCard extends Equatable {
  final int currentStamps;
  final int? stampsRequired;
  final int creditBalanceInCents;

  const StampCard({
    required this.currentStamps,
    required this.stampsRequired,
    required this.creditBalanceInCents,
  });

  factory StampCard.fromJson(Map<String, dynamic> json) => StampCard(
        currentStamps: json['currentStamps'] as int,
        stampsRequired: json['stampsRequired'] as int?,
        creditBalanceInCents: json['creditBalanceInCents'] as int,
      );

  String get formattedCreditBalance {
    final reais = creditBalanceInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [currentStamps, stampsRequired, creditBalanceInCents];
}
```

- [ ] **Step 2: Create `subscription_tier_view.dart`**

```dart
// lib/features/loyalty/domain/subscription_tier_view.dart
import 'package:equatable/equatable.dart';

class TierServiceItem extends Equatable {
  final String serviceId;
  final int quantity;
  final int priceInCents;

  const TierServiceItem({required this.serviceId, required this.quantity, required this.priceInCents});

  factory TierServiceItem.fromJson(Map<String, dynamic> json) => TierServiceItem(
        serviceId: json['serviceId'] as String,
        quantity: json['quantity'] as int,
        priceInCents: json['priceInCents'] as int,
      );

  @override
  List<Object?> get props => [serviceId, quantity, priceInCents];
}

class SubscriptionTierView extends Equatable {
  final String id;
  final String tier;
  final List<TierServiceItem> services;
  final int monthlyPriceInCents;
  final int discountPercentage;

  const SubscriptionTierView({
    required this.id,
    required this.tier,
    required this.services,
    required this.monthlyPriceInCents,
    required this.discountPercentage,
  });

  factory SubscriptionTierView.fromJson(Map<String, dynamic> json) => SubscriptionTierView(
        id: json['id'] as String,
        tier: json['tier'] as String,
        services: (json['services'] as List)
            .map((s) => TierServiceItem.fromJson(s as Map<String, dynamic>))
            .toList(),
        monthlyPriceInCents: json['monthlyPriceInCents'] as int,
        discountPercentage: json['discountPercentage'] as int,
      );

  String get formattedMonthlyPrice {
    final reais = monthlyPriceInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [id, tier, services, monthlyPriceInCents, discountPercentage];
}
```

- [ ] **Step 3: Create `club_subscription.dart`**

```dart
// lib/features/loyalty/domain/club_subscription.dart
import 'package:equatable/equatable.dart';

class SubscriptionQuota extends Equatable {
  final String serviceId;
  final int quantityTotal;
  final int quantityConsumed;

  const SubscriptionQuota({
    required this.serviceId,
    required this.quantityTotal,
    required this.quantityConsumed,
  });

  factory SubscriptionQuota.fromJson(Map<String, dynamic> json) => SubscriptionQuota(
        serviceId: json['serviceId'] as String,
        quantityTotal: json['quantityTotal'] as int,
        quantityConsumed: json['quantityConsumed'] as int,
      );

  @override
  List<Object?> get props => [serviceId, quantityTotal, quantityConsumed];
}

class ClubSubscription extends Equatable {
  final String status;
  final String tierId;
  final String currentCycleStart;
  final String currentCycleEnd;
  final List<SubscriptionQuota> quotas;

  const ClubSubscription({
    required this.status,
    required this.tierId,
    required this.currentCycleStart,
    required this.currentCycleEnd,
    required this.quotas,
  });

  factory ClubSubscription.fromJson(Map<String, dynamic> json) => ClubSubscription(
        status: json['status'] as String,
        tierId: json['tierId'] as String,
        currentCycleStart: json['currentCycleStart'] as String,
        currentCycleEnd: json['currentCycleEnd'] as String,
        quotas: (json['quotas'] as List)
            .map((q) => SubscriptionQuota.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  bool get isPastDue => status == 'PAST_DUE';

  @override
  List<Object?> get props => [status, tierId, currentCycleStart, currentCycleEnd, quotas];
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/loyalty/domain/stamp_card.dart lib/features/loyalty/domain/subscription_tier_view.dart lib/features/loyalty/domain/club_subscription.dart
git commit -m "feat(loyalty): add domain models for stamp card, subscription tiers and club subscription"
```

---

## Task 5: `LoyaltyRepository` + `LoyaltyRepositoryImpl` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/domain/loyalty_repository.dart`
- Create: `lib/features/loyalty/data/loyalty_repository_impl.dart`
- Test: `test/features/loyalty/data/loyalty_repository_impl_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/loyalty/data/loyalty_repository_impl_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/loyalty/data/loyalty_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late LoyaltyRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = LoyaltyRepositoryImpl(dio);
  });

  test('getMyStampCard returns Right with parsed card on 200', () async {
    when(() => dio.get('/loyalty/stamp-card/me')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/stamp-card/me'),
          statusCode: 200,
          data: {'currentStamps': 3, 'stampsRequired': 10, 'creditBalanceInCents': 1500},
        ));

    final result = await repository.getMyStampCard();

    result.fold((_) => fail('expected right'), (card) {
      expect(card.currentStamps, 3);
      expect(card.creditBalanceInCents, 1500);
    });
  });

  test('redeemCredit posts the amount and returns Right on 204', () async {
    when(() => dio.post('/loyalty/stamp-card/redeem', data: {'amountInCents': 1500}))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/loyalty/stamp-card/redeem'),
              statusCode: 204,
            ));

    final result = await repository.redeemCredit(1500);

    expect(result.isRight(), true);
    verify(() => dio.post('/loyalty/stamp-card/redeem', data: {'amountInCents': 1500})).called(1);
  });

  test('getMySubscription returns Right(null) on 404 (no active subscription)', () async {
    when(() => dio.get('/loyalty/club-subscription/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/loyalty/club-subscription/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/loyalty/club-subscription/me'),
        statusCode: 404,
        data: {'message': 'not found'},
      ),
    ));

    final result = await repository.getMySubscription();

    result.fold((_) => fail('expected right'), (subscription) => expect(subscription, isNull));
  });

  test('getMySubscription returns Right with parsed subscription on 200', () async {
    when(() => dio.get('/loyalty/club-subscription/me')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/club-subscription/me'),
          statusCode: 200,
          data: {
            'status': 'ACTIVE',
            'tierId': 'tier-1',
            'currentCycleStart': '2026-07-01',
            'currentCycleEnd': '2026-07-31',
            'quotas': [
              {'serviceId': 'svc-1', 'quantityTotal': 2, 'quantityConsumed': 1},
            ],
          },
        ));

    final result = await repository.getMySubscription();

    result.fold((_) => fail('expected right'), (subscription) {
      expect(subscription, isNotNull);
      expect(subscription!.status, 'ACTIVE');
      expect(subscription.quotas, hasLength(1));
    });
  });

  test('getMySubscription maps a non-404 DioException to ApiFailure', () async {
    when(() => dio.get('/loyalty/club-subscription/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/loyalty/club-subscription/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/loyalty/club-subscription/me'),
        statusCode: 500,
        data: {'message': 'erro interno'},
      ),
    ));

    final result = await repository.getMySubscription();

    result.fold((failure) => expect(failure, isA<ApiFailure>()), (_) => fail('expected left'));
  });

  test('getAvailableTiers returns Right with parsed tiers on 200', () async {
    when(() => dio.get('/loyalty/club-subscription/tiers/available')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/club-subscription/tiers/available'),
          statusCode: 200,
          data: [
            {
              'id': 'tier-1',
              'tier': 'ESSENCIAL',
              'services': [
                {'serviceId': 'svc-1', 'quantity': 2, 'priceInCents': 3500},
              ],
              'monthlyPriceInCents': 7000,
              'discountPercentage': 0,
            },
          ],
        ));

    final result = await repository.getAvailableTiers();

    result.fold((_) => fail('expected right'), (tiers) {
      expect(tiers, hasLength(1));
      expect(tiers[0].tier, 'ESSENCIAL');
      expect(tiers[0].formattedMonthlyPrice, 'R\$ 70,00');
    });
  });

  test('activateSubscription posts the form and returns Right with the subscription', () async {
    when(() => dio.post('/loyalty/club-subscription/activate', data: {
          'tier': 'ESSENCIAL',
          'name': 'Fulano',
          'cpfCnpj': '12345678900',
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/club-subscription/activate'),
          statusCode: 201,
          data: {
            'status': 'ACTIVE',
            'tierId': 'tier-1',
            'currentCycleStart': '2026-07-01',
            'currentCycleEnd': '2026-07-31',
            'quotas': <dynamic>[],
          },
        ));

    final result = await repository.activateSubscription(tier: 'ESSENCIAL', name: 'Fulano', cpfCnpj: '12345678900');

    result.fold((_) => fail('expected right'), (subscription) => expect(subscription.status, 'ACTIVE'));
  });

  test('cancelSubscription posts and returns Right on 204', () async {
    when(() => dio.post('/loyalty/club-subscription/cancel')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/club-subscription/cancel'),
          statusCode: 204,
        ));

    final result = await repository.cancelSubscription();

    expect(result.isRight(), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/data/loyalty_repository_impl_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:baber_mobile/features/loyalty/data/loyalty_repository_impl.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/domain/loyalty_repository.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import 'club_subscription.dart';
import 'stamp_card.dart';
import 'subscription_tier_view.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, StampCard>> getMyStampCard();
  Future<Either<Failure, void>> redeemCredit(int amountInCents);
  Future<Either<Failure, ClubSubscription?>> getMySubscription();
  Future<Either<Failure, List<SubscriptionTierView>>> getAvailableTiers();
  Future<Either<Failure, ClubSubscription>> activateSubscription({
    required String tier,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phone,
  });
  Future<Either<Failure, void>> cancelSubscription();
}
```

```dart
// lib/features/loyalty/data/loyalty_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/club_subscription.dart';
import '../domain/loyalty_repository.dart';
import '../domain/stamp_card.dart';
import '../domain/subscription_tier_view.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final Dio _dio;
  const LoyaltyRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, StampCard>> getMyStampCard() async {
    try {
      final response = await _dio.get('/loyalty/stamp-card/me');
      return Right(StampCard.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> redeemCredit(int amountInCents) async {
    try {
      await _dio.post('/loyalty/stamp-card/redeem', data: {'amountInCents': amountInCents});
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, ClubSubscription?>> getMySubscription() async {
    try {
      final response = await _dio.get('/loyalty/club-subscription/me');
      return Right(ClubSubscription.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      // 404 é o estado "sem assinatura", não é uma falha — o cliente pode
      // simplesmente nunca ter assinado o clube.
      if (e.response?.statusCode == 404) return const Right(null);
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionTierView>>> getAvailableTiers() async {
    try {
      final response = await _dio.get('/loyalty/club-subscription/tiers/available');
      final tiers = (response.data as List)
          .map((json) => SubscriptionTierView.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(tiers);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, ClubSubscription>> activateSubscription({
    required String tier,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _dio.post('/loyalty/club-subscription/activate', data: {
        'tier': tier,
        'name': name,
        'cpfCnpj': cpfCnpj,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      return Right(ClubSubscription.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await _dio.post('/loyalty/club-subscription/cancel');
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/data/loyalty_repository_impl_test.dart`
Expected: PASS (8 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/domain/loyalty_repository.dart lib/features/loyalty/data/loyalty_repository_impl.dart test/features/loyalty/data/loyalty_repository_impl_test.dart
git commit -m "feat(loyalty): add LoyaltyRepository and its Dio implementation"
```

---

## Task 6: `LoyaltyBloc` (hub screen's bloc) (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/loyalty_event.dart`
- Create: `lib/features/loyalty/presentation/loyalty_state.dart`
- Create: `lib/features/loyalty/presentation/loyalty_bloc.dart`
- Test: `test/features/loyalty/presentation/loyalty_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/loyalty/presentation/loyalty_bloc_test.dart
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
    act: (bloc) => bloc.add(LoadLoyaltyHub())..add(RedeemAllCreditRequested()),
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
    act: (bloc) => bloc.add(LoadLoyaltyHub())..add(CancelSubscriptionRequested()),
    skip: 2,
    expect: () => [
      isA<LoyaltyState>().having((s) => s.actionInProgress, 'actionInProgress', true),
      isA<LoyaltyState>().having((s) => s.subscription, 'subscription', isNull),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/loyalty_bloc_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/loyalty_event.dart
import 'package:equatable/equatable.dart';

sealed class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object?> get props => [];
}

class LoadLoyaltyHub extends LoyaltyEvent {}

class RedeemAllCreditRequested extends LoyaltyEvent {}

class CancelSubscriptionRequested extends LoyaltyEvent {}
```

```dart
// lib/features/loyalty/presentation/loyalty_state.dart
import 'package:equatable/equatable.dart';
import '../../catalog/domain/service.dart';
import '../domain/club_subscription.dart';
import '../domain/stamp_card.dart';
import '../domain/subscription_tier_view.dart';

class LoyaltyState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final StampCard? stampCard;
  final ClubSubscription? subscription;
  final List<Service> services;
  final List<SubscriptionTierView> tiers;
  final bool actionInProgress;
  final String? actionErrorMessage;

  const LoyaltyState({
    this.isLoading = false,
    this.errorMessage,
    this.stampCard,
    this.subscription,
    this.services = const [],
    this.tiers = const [],
    this.actionInProgress = false,
    this.actionErrorMessage,
  });

  LoyaltyState copyWith({
    bool? isLoading,
    StampCard? stampCard,
    bool? actionInProgress,
    String? actionErrorMessage,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? false,
      stampCard: stampCard ?? this.stampCard,
      subscription: subscription,
      services: services,
      tiers: tiers,
      actionInProgress: actionInProgress ?? false,
      actionErrorMessage: actionErrorMessage,
    );
  }

  String? tierNameFor(String tierId) {
    for (final t in tiers) {
      if (t.id == tierId) return t.tier;
    }
    return null;
  }

  String? serviceNameFor(String serviceId) {
    for (final s in services) {
      if (s.id == serviceId) return s.name;
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [isLoading, errorMessage, stampCard, subscription, services, tiers, actionInProgress, actionErrorMessage];
}
```

```dart
// lib/features/loyalty/presentation/loyalty_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../../catalog/domain/service_repository.dart';
import '../domain/loyalty_repository.dart';
import '../domain/stamp_card.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyRepository repository;
  final ServiceRepository serviceRepository;

  LoyaltyBloc({required this.repository, required this.serviceRepository}) : super(const LoyaltyState()) {
    on<LoadLoyaltyHub>(_onLoad);
    on<RedeemAllCreditRequested>(_onRedeem);
    on<CancelSubscriptionRequested>(_onCancel);
  }

  Future<void> _onLoad(LoadLoyaltyHub event, Emitter<LoyaltyState> emit) async {
    emit(const LoyaltyState(isLoading: true));

    // As 4 chamadas disparam em paralelo (futures criadas antes de qualquer
    // await); cartão fidelidade é o dado essencial — sua falha vira erro de
    // tela, as outras degradam graciosamente (mostram menos informação).
    final stampCardFuture = repository.getMyStampCard();
    final subscriptionFuture = repository.getMySubscription();
    final servicesFuture = serviceRepository.listServices();
    final tiersFuture = repository.getAvailableTiers();

    final stampCardResult = await stampCardFuture;
    final subscriptionResult = await subscriptionFuture;
    final servicesResult = await servicesFuture;
    final tiersResult = await tiersFuture;

    final failureMsg = stampCardResult.fold((failure) => failureMessage(failure), (_) => null);
    if (failureMsg != null) {
      emit(LoyaltyState(errorMessage: failureMsg));
      return;
    }

    emit(LoyaltyState(
      stampCard: stampCardResult.fold((_) => null, (card) => card),
      subscription: subscriptionResult.fold((_) => null, (s) => s),
      services: servicesResult.fold((_) => const [], (s) => s),
      tiers: tiersResult.fold((_) => const [], (t) => t),
    ));
  }

  Future<void> _onRedeem(RedeemAllCreditRequested event, Emitter<LoyaltyState> emit) async {
    final card = state.stampCard;
    if (card == null || card.creditBalanceInCents <= 0) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await repository.redeemCredit(card.creditBalanceInCents);
    result.fold(
      (failure) => emit(state.copyWith(actionErrorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(
        stampCard: StampCard(
          currentStamps: card.currentStamps,
          stampsRequired: card.stampsRequired,
          creditBalanceInCents: 0,
        ),
      )),
    );
  }

  Future<void> _onCancel(CancelSubscriptionRequested event, Emitter<LoyaltyState> emit) async {
    emit(state.copyWith(actionInProgress: true));
    final result = await repository.cancelSubscription();
    result.fold(
      (failure) => emit(state.copyWith(actionErrorMessage: failureMessage(failure))),
      (_) => emit(LoyaltyState(stampCard: state.stampCard, subscription: null, services: state.services, tiers: state.tiers)),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/loyalty_bloc_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/loyalty_event.dart lib/features/loyalty/presentation/loyalty_state.dart lib/features/loyalty/presentation/loyalty_bloc.dart test/features/loyalty/presentation/loyalty_bloc_test.dart
git commit -m "feat(loyalty): add LoyaltyBloc for the hub screen"
```

---

## Task 7: `loyalty_hub_screen.dart` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/loyalty_hub_screen.dart`
- Test: `test/features/loyalty/presentation/loyalty_hub_screen_test.dart`

- [ ] **Step 1: Write the failing test**

This follows the codebase's established widget-test convention (see
`test/features/catalog/presentation/services_list_screen_test.dart` and
`test/features/booking/presentation/confirm_booking_screen_test.dart`): a
`MockBloc` driven via `whenListen`, not a real bloc wired to a mocked
repository.

```dart
// test/features/loyalty/presentation/loyalty_hub_screen_test.dart
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
        tiers: [SubscriptionTierView(id: 'tier-1', tier: 'ESSENCIAL', services: [], monthlyPriceInCents: 8000, discountPercentage: 0)],
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/loyalty_hub_screen_test.dart`
Expected: FAIL — `loyalty_hub_screen.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/loyalty_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'loyalty_bloc.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text('Você perde o acesso aos benefícios do clube ao final do ciclo atual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoyaltyBloc>().add(CancelSubscriptionRequested());
    }
  }

  Future<void> _confirmRedeem(BuildContext context, String formattedBalance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usar crédito?'),
        content: Text('Isso zera seu saldo de $formattedBalance. Combine o desconto com o barbeiro no balcão.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoyaltyBloc>().add(RedeemAllCreditRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Clube'),
      body: BlocConsumer<LoyaltyBloc, LoyaltyState>(
        listener: (context, state) {
          if (state.actionErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionErrorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }

          final subscription = state.subscription;
          if (subscription != null) {
            final tierName = state.tierNameFor(subscription.tierId) ?? 'Clube';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (subscription.isPastDue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Pagamento atrasado — regularize para manter os benefícios.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.barberRed),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLANO $tierName',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.brass, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ciclo: ${subscription.currentCycleStart} – ${subscription.currentCycleEnd}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 24),
                        for (final quota in subscription.quotas)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${state.serviceNameFor(quota.serviceId) ?? quota.serviceId}: '
                              '${quota.quantityConsumed}/${quota.quantityTotal} usado no ciclo',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: state.actionInProgress ? null : () => _confirmCancel(context),
                  child: const Text('Cancelar assinatura'),
                ),
              ],
            );
          }

          final stampCard = state.stampCard!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARTÃO FIDELIDADE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.brass, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stampCard.currentStamps} / ${stampCard.stampsRequired ?? '-'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('Saldo de crédito: ${stampCard.formattedCreditBalance}'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: stampCard.creditBalanceInCents <= 0 || state.actionInProgress
                            ? null
                            : () => _confirmRedeem(context, stampCard.formattedCreditBalance),
                        child: const Text('Usar crédito'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/loyalty/plans'),
                child: const Text('Ver planos'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/loyalty_hub_screen_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/loyalty_hub_screen.dart test/features/loyalty/presentation/loyalty_hub_screen_test.dart
git commit -m "feat(loyalty): add hub screen (stamp card / active subscription view)"
```

---

## Task 8: `SubscriptionPlansBloc` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/subscription_plans_event.dart`
- Create: `lib/features/loyalty/presentation/subscription_plans_state.dart`
- Create: `lib/features/loyalty/presentation/subscription_plans_bloc.dart`
- Test: `test/features/loyalty/presentation/subscription_plans_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/loyalty/presentation/subscription_plans_bloc_test.dart
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
    tier: 'ESSENCIAL',
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/subscription_plans_bloc_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/subscription_plans_event.dart
import 'package:equatable/equatable.dart';

sealed class SubscriptionPlansEvent extends Equatable {
  const SubscriptionPlansEvent();
  @override
  List<Object?> get props => [];
}

class LoadSubscriptionPlans extends SubscriptionPlansEvent {}
```

```dart
// lib/features/loyalty/presentation/subscription_plans_state.dart
import 'package:equatable/equatable.dart';
import '../domain/subscription_tier_view.dart';

class SubscriptionPlansState extends Equatable {
  final List<SubscriptionTierView>? tiers;
  final String? errorMessage;
  final bool isLoading;

  const SubscriptionPlansState({this.tiers, this.errorMessage, this.isLoading = false});

  const SubscriptionPlansState.initial() : this();
  const SubscriptionPlansState.loading() : this(isLoading: true);
  const SubscriptionPlansState.loaded(List<SubscriptionTierView> tiers) : this(tiers: tiers);
  const SubscriptionPlansState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [tiers, errorMessage, isLoading];
}
```

```dart
// lib/features/loyalty/presentation/subscription_plans_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../domain/loyalty_repository.dart';
import 'subscription_plans_event.dart';
import 'subscription_plans_state.dart';

class SubscriptionPlansBloc extends Bloc<SubscriptionPlansEvent, SubscriptionPlansState> {
  final LoyaltyRepository repository;

  SubscriptionPlansBloc({required this.repository}) : super(const SubscriptionPlansState.initial()) {
    on<LoadSubscriptionPlans>(_onLoad);
  }

  Future<void> _onLoad(LoadSubscriptionPlans event, Emitter<SubscriptionPlansState> emit) async {
    emit(const SubscriptionPlansState.loading());
    final result = await repository.getAvailableTiers();
    result.fold(
      (failure) => emit(SubscriptionPlansState.error(failureMessage(failure))),
      (tiers) => emit(SubscriptionPlansState.loaded(tiers)),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/subscription_plans_bloc_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/subscription_plans_event.dart lib/features/loyalty/presentation/subscription_plans_state.dart lib/features/loyalty/presentation/subscription_plans_bloc.dart test/features/loyalty/presentation/subscription_plans_bloc_test.dart
git commit -m "feat(loyalty): add SubscriptionPlansBloc"
```

---

## Task 9: `subscription_plans_screen.dart` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/subscription_plans_screen.dart`
- Test: `test/features/loyalty/presentation/subscription_plans_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Same `MockBloc`/`whenListen` convention as Task 7.

```dart
// test/features/loyalty/presentation/subscription_plans_screen_test.dart
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
    tier: 'ESSENCIAL',
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/subscription_plans_screen_test.dart`
Expected: FAIL — `subscription_plans_screen.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/subscription_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'subscription_plans_bloc.dart';
import 'subscription_plans_event.dart';
import 'subscription_plans_state.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionPlansBloc>().add(LoadSubscriptionPlans());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Planos do clube'),
      body: BlocConsumer<SubscriptionPlansBloc, SubscriptionPlansState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final tiers = state.tiers ?? [];
          if (tiers.isEmpty) {
            return Center(
              child: Text(
                'Nenhum plano disponível no momento.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: tiers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tier = tiers[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.tier, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${tier.formattedMonthlyPrice} / mês',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.brass),
                      ),
                      const SizedBox(height: 12),
                      for (final item in tier.services)
                        Text('${item.quantity}x serviço incluso', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/loyalty/activate', extra: tier),
                        child: const Text('Assinar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/subscription_plans_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/subscription_plans_screen.dart test/features/loyalty/presentation/subscription_plans_screen_test.dart
git commit -m "feat(loyalty): add subscription plans list screen"
```

---

## Task 10: `ActivateSubscriptionBloc` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/activate_subscription_event.dart`
- Create: `lib/features/loyalty/presentation/activate_subscription_state.dart`
- Create: `lib/features/loyalty/presentation/activate_subscription_bloc.dart`
- Test: `test/features/loyalty/presentation/activate_subscription_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/loyalty/presentation/activate_subscription_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/loyalty/domain/club_subscription.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
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
    'emits [loading, activated] when activation succeeds',
    build: () {
      when(() => repository.activateSubscription(
            tier: 'ESSENCIAL',
            name: 'Fulano',
            cpfCnpj: '12345678900',
            email: null,
            phone: null,
          )).thenAnswer((_) async => const Right(subscription));
      return ActivateSubscriptionBloc(repository: repository, tier: tier);
    },
    act: (bloc) => bloc.add(const ActivateSubmitted(name: 'Fulano', cpfCnpj: '12345678900')),
    expect: () => [
      const ActivateSubscriptionState(isLoading: true),
      const ActivateSubscriptionState(activated: true),
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/activate_subscription_bloc_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/activate_subscription_event.dart
import 'package:equatable/equatable.dart';

sealed class ActivateSubscriptionEvent extends Equatable {
  const ActivateSubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class ActivateSubmitted extends ActivateSubscriptionEvent {
  final String name;
  final String cpfCnpj;
  final String? email;
  final String? phone;

  const ActivateSubmitted({required this.name, required this.cpfCnpj, this.email, this.phone});

  @override
  List<Object?> get props => [name, cpfCnpj, email, phone];
}
```

```dart
// lib/features/loyalty/presentation/activate_subscription_state.dart
import 'package:equatable/equatable.dart';

class ActivateSubscriptionState extends Equatable {
  final bool isLoading;
  final bool activated;
  final String? errorMessage;

  const ActivateSubscriptionState({this.isLoading = false, this.activated = false, this.errorMessage});

  ActivateSubscriptionState copyWith({bool? isLoading, bool? activated, String? errorMessage}) {
    return ActivateSubscriptionState(
      isLoading: isLoading ?? false,
      activated: activated ?? false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, activated, errorMessage];
}
```

```dart
// lib/features/loyalty/presentation/activate_subscription_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../domain/loyalty_repository.dart';
import '../domain/subscription_tier_view.dart';
import 'activate_subscription_event.dart';
import 'activate_subscription_state.dart';

class ActivateSubscriptionBloc extends Bloc<ActivateSubscriptionEvent, ActivateSubscriptionState> {
  final LoyaltyRepository repository;
  final SubscriptionTierView tier;

  ActivateSubscriptionBloc({required this.repository, required this.tier})
      : super(const ActivateSubscriptionState()) {
    on<ActivateSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(ActivateSubmitted event, Emitter<ActivateSubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.activateSubscription(
      tier: tier.tier,
      name: event.name,
      cpfCnpj: event.cpfCnpj,
      email: event.email,
      phone: event.phone,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(activated: true)),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/activate_subscription_bloc_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/activate_subscription_event.dart lib/features/loyalty/presentation/activate_subscription_state.dart lib/features/loyalty/presentation/activate_subscription_bloc.dart test/features/loyalty/presentation/activate_subscription_bloc_test.dart
git commit -m "feat(loyalty): add ActivateSubscriptionBloc"
```

---

## Task 11: `activate_subscription_screen.dart` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Create: `lib/features/loyalty/presentation/activate_subscription_screen.dart`
- Test: `test/features/loyalty/presentation/activate_subscription_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Same `MockBloc`/`whenListen` convention as Tasks 7 and 9.

```dart
// test/features/loyalty/presentation/activate_subscription_screen_test.dart
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
    await tester.enterText(find.widgetWithText(TextFormField, 'CPF ou CNPJ'), '12345678900');
    await tester.tap(find.text('Assinar'));
    await tester.pump();

    verify(() => bloc.add(const ActivateSubmitted(
          name: 'Fulano',
          cpfCnpj: '12345678900',
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/loyalty/presentation/activate_subscription_screen_test.dart`
Expected: FAIL — `activate_subscription_screen.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/loyalty/presentation/activate_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../domain/subscription_tier_view.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'activate_subscription_bloc.dart';
import 'activate_subscription_event.dart';
import 'activate_subscription_state.dart';

class ActivateSubscriptionScreen extends StatefulWidget {
  final SubscriptionTierView tier;
  final String initialName;
  final String initialPhone;

  const ActivateSubscriptionScreen({
    super.key,
    required this.tier,
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<ActivateSubscriptionScreen> createState() => _ActivateSubscriptionScreenState();
}

class _ActivateSubscriptionScreenState extends State<ActivateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cpfCnpjController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _cpfCnpjController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfCnpjController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe seu nome';
    return null;
  }

  String? _validateCpfCnpj(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) return 'Informe um CPF ou CNPJ válido';
    return null;
  }

  void _submit(ActivateSubscriptionState state) {
    if (state.isLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<ActivateSubscriptionBloc>().add(ActivateSubmitted(
            name: _nameController.text,
            cpfCnpj: _cpfCnpjController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarberAppBar(title: 'Assinar ${widget.tier.tier}'),
      body: BlocConsumer<ActivateSubscriptionBloc, ActivateSubscriptionState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.activated) {
            context.go('/loyalty');
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${widget.tier.formattedMonthlyPrice} / mês', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpfCnpjController,
                  keyboardType: TextInputType.number,
                  validator: _validateCpfCnpj,
                  decoration: const InputDecoration(labelText: 'CPF ou CNPJ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.isLoading ? null : () => _submit(state),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assinar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/loyalty/presentation/activate_subscription_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/loyalty/presentation/activate_subscription_screen.dart test/features/loyalty/presentation/activate_subscription_screen_test.dart
git commit -m "feat(loyalty): add activation form screen"
```

---

## Task 12: Wire the 3 new routes into `app_router.dart` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Modify: `lib/core/router/app_router.dart`

No dedicated test for this file (it has no existing test file — routing is exercised indirectly by the screen tests above and by manual smoke test in Task 15).

- [ ] **Step 1: Add the new imports**

Add these imports near the other feature imports (alphabetically, after the `home` imports and before `notifications`):

```dart
import '../../features/loyalty/domain/loyalty_repository.dart';
import '../../features/loyalty/domain/subscription_tier_view.dart';
import '../../features/loyalty/presentation/activate_subscription_bloc.dart';
import '../../features/loyalty/presentation/activate_subscription_screen.dart';
import '../../features/loyalty/presentation/loyalty_bloc.dart';
import '../../features/loyalty/presentation/loyalty_event.dart';
import '../../features/loyalty/presentation/loyalty_hub_screen.dart';
import '../../features/loyalty/presentation/subscription_plans_bloc.dart';
import '../../features/loyalty/presentation/subscription_plans_screen.dart';
```

- [ ] **Step 2: Add the `_ActivateSubscriptionGuard` widget**

Add this class right after `_BookingShellState` (before `GoRouter buildAppRouter(...)`). It mirrors `_BookingShell`'s defensive handling of a lost `extra` on process restore (the same bug class fixed for booking in commit `1922e8a`):

```dart
class _ActivateSubscriptionGuard extends StatefulWidget {
  final SubscriptionTierView? tier;
  final Widget Function(SubscriptionTierView tier) builder;

  const _ActivateSubscriptionGuard({required this.tier, required this.builder});

  @override
  State<_ActivateSubscriptionGuard> createState() => _ActivateSubscriptionGuardState();
}

class _ActivateSubscriptionGuardState extends State<_ActivateSubscriptionGuard> {
  @override
  void initState() {
    super.initState();
    if (widget.tier == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/loyalty/plans');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    if (tier == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.builder(tier);
  }
}
```

- [ ] **Step 3: Add `required LoyaltyRepository loyaltyRepository` to `buildAppRouter`'s parameters**

In the `buildAppRouter({...})` signature, add (alphabetically among the required repos):

```dart
  required LoyaltyRepository loyaltyRepository,
```

- [ ] **Step 4: Add the 3 new routes**

Add this block right after the closing `GoRoute(path: '/services', ...)` block (before the booking `ShellRoute`):

```dart
      GoRoute(
        path: '/loyalty',
        builder: (context, state) => BlocProvider(
          create: (_) => LoyaltyBloc(repository: loyaltyRepository, serviceRepository: serviceRepository)
            ..add(LoadLoyaltyHub()),
          child: const LoyaltyHubScreen(),
        ),
      ),
      GoRoute(
        path: '/loyalty/plans',
        builder: (context, state) => BlocProvider(
          create: (_) => SubscriptionPlansBloc(repository: loyaltyRepository),
          child: const SubscriptionPlansScreen(),
        ),
      ),
      GoRoute(
        path: '/loyalty/activate',
        builder: (context, state) {
          final extra = state.extra;
          final tier = extra is SubscriptionTierView ? extra : null;
          return _ActivateSubscriptionGuard(
            tier: tier,
            builder: (tier) => FutureBuilder<Either<Failure, AuthUser>>(
              future: profileRepository.getMe(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                return snapshot.data!.fold(
                  (_) => BlocProvider(
                    create: (_) => ActivateSubscriptionBloc(repository: loyaltyRepository, tier: tier),
                    child: ActivateSubscriptionScreen(tier: tier, initialName: '', initialPhone: ''),
                  ),
                  (user) => BlocProvider(
                    create: (_) => ActivateSubscriptionBloc(repository: loyaltyRepository, tier: tier),
                    child: ActivateSubscriptionScreen(tier: tier, initialName: user.name ?? '', initialPhone: user.phone),
                  ),
                );
              },
            ),
          );
        },
      ),
```

- [ ] **Step 5: Run the full test suite to catch any missed wiring**

Run: `flutter test`
Expected: FAIL only on `test/core/router` (if any) or on `main.dart`/`baber_app.dart` compile errors from the new required parameter — this is expected until Task 13 wires the caller. If there's no router test and nothing else references `buildAppRouter`, this may already PASS; if `flutter analyze` reports the missing named argument at `baber_app.dart`, that's expected and fixed in Task 13.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat(loyalty): wire /loyalty, /loyalty/plans and /loyalty/activate routes"
```

---

## Task 13: DI wiring in `baber_app.dart` and `main.dart` (mobile)

**Repo:** `baber-mobile`

**Files:**
- Modify: `lib/baber_app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Update `baber_app.dart`**

Add the import:

```dart
import 'features/loyalty/domain/loyalty_repository.dart';
```

Add the field and constructor parameter (alphabetically, next to `bookingRepository`):

```dart
  final LoyaltyRepository loyaltyRepository;
```

```dart
    required this.loyaltyRepository,
```

Pass it through to `buildAppRouter(...)`:

```dart
      loyaltyRepository: loyaltyRepository,
```

- [ ] **Step 2: Update `main.dart`**

Add the import:

```dart
import 'features/loyalty/data/loyalty_repository_impl.dart';
```

Construct the repository (next to `bookingRepository`):

```dart
  final loyaltyRepository = LoyaltyRepositoryImpl(apiClient.dio);
```

Pass it into `BaberApp(...)`:

```dart
    loyaltyRepository: loyaltyRepository,
```

- [ ] **Step 3: Run `flutter analyze` to confirm the wiring compiles**

Run: `flutter analyze`
Expected: No errors (no unresolved required-parameter issues).

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS, all suites (previous count + all new `loyalty` tests from Tasks 5-11)

- [ ] **Step 5: Commit**

```bash
git add lib/baber_app.dart lib/main.dart
git commit -m "chore(loyalty): wire LoyaltyRepository through the app's DI"
```

---

## Task 14: "Clube" shortcut on the Home screen (mobile)

**Repo:** `baber-mobile`

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`
- Test: check `test/features/home/presentation/home_screen_test.dart` if it exists (see Step 1)

- [ ] **Step 1: Check for an existing Home screen test**

Run: `flutter test test/features/home/presentation/home_screen_test.dart` (or locate it via `find test/features/home -type f`)

If a test asserts the exact list/count of shortcut tiles (e.g. `find.byType(_ShortcutTile)` with a count, or checks the `Row`'s children count), update it to expect 4 tiles instead of 3 as part of this task. If no such test exists, skip straight to Step 2.

- [ ] **Step 2: Add the "Clube" shortcut**

In `home_screen.dart`, the shortcuts `Row` currently has 3 `Expanded(child: _ShortcutTile(...))` entries (Serviços, Consultas, Notificações). Change it to:

```dart
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.content_cut,
                      label: 'Serviços',
                      onTap: () => context.push('/services'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.event_outlined,
                      label: 'Consultas',
                      onTap: () => context.go('/appointments'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notificações',
                      onTap: () => context.go('/notifications'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Clube',
                      onTap: () => context.push('/loyalty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
```

This keeps the existing 3-tile row untouched (no risk of breaking an existing test that counts exactly 3 tiles in that row) and adds a 2nd row below with "Clube" as its first tile, empty spacers in the other 2 slots to preserve the tile width/alignment grid.

- [ ] **Step 3: Run the Home screen test (if one exists) and the widget manually**

Run: `flutter test test/features/home/presentation/home_screen_test.dart` (if it exists)
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart
git commit -m "feat(loyalty): add Clube shortcut to the Home screen"
```

---

## Task 15: Full mobile test suite + `flutter analyze` (mobile)

**Repo:** `baber-mobile`

**Files:** none (verification task)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: PASS, all suites (all pre-existing tests + all new `loyalty` tests from Tasks 5-11 + Task 14's Home test if applicable)

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: If everything passes, this task needs no commit** (nothing changed) — it's a checkpoint before manual smoke test.

---

## Manual smoke test (not automatable — do after Task 15)

Once all 15 tasks are done and merged, a manual pass on the emulator (same pattern as the Task 22 club-subscription backend smoke test) should cover:
1. Home → "Clube" → no subscription yet → stamp card view shows, "Ver planos" works.
2. "Ver planos" → lists tiers with correct price → "Assinar" → form → invalid CPF blocked → valid CPF submits → returns to hub showing the new ACTIVE subscription with correct tier name and quotas.
3. "Cancelar assinatura" → confirms → returns to stamp-card view.
4. Credit balance > 0 → "Usar crédito" → confirms → balance zeroes.

This is out of scope for the automated plan (needs a live API + Asaas sandbox + emulator), same as Task 22 was for the backend club-subscription plan.
