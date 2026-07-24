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
              'name': 'Essencial',
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
      expect(tiers[0].name, 'Essencial');
      expect(tiers[0].formattedMonthlyPrice, 'R\$ 70,00');
    });
  });

  test('activateSubscription posts the form and returns Right with the subscription', () async {
    when(() => dio.post('/loyalty/club-subscription/activate', data: {
          'tierId': 'tier-1',
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

    final result = await repository.activateSubscription(tierId: 'tier-1', name: 'Fulano', cpfCnpj: '12345678900');

    result.fold((_) => fail('expected right'), (activation) {
      expect(activation.subscription.status, 'ACTIVE');
      expect(activation.payment, isNull);
    });
  });

  test('activateSubscription returns Right with a PixPayment when the response includes a charge', () async {
    when(() => dio.post('/loyalty/club-subscription/activate', data: {
          'tierId': 'tier-1',
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
            'payment': {
              'paymentId': 'pay_1',
              'pix': {'encodedImage': 'img', 'payload': 'copia-e-cola', 'expirationDate': '2027-01-01'},
            },
          },
        ));

    final result = await repository.activateSubscription(tierId: 'tier-1', name: 'Fulano', cpfCnpj: '12345678900');

    result.fold((_) => fail('expected right'), (activation) {
      expect(activation.payment?.paymentId, 'pay_1');
      expect(activation.payment?.encodedImage, 'img');
    });
  });

  test('getPaymentStatus GETs the status endpoint and returns Right with the status string', () async {
    when(() => dio.get('/loyalty/club-subscription/payments/pay_1/status')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/loyalty/club-subscription/payments/pay_1/status'),
          statusCode: 200,
          data: {'status': 'RECEIVED'},
        ));

    final result = await repository.getPaymentStatus('pay_1');

    result.fold((_) => fail('expected right'), (status) => expect(status, 'RECEIVED'));
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
