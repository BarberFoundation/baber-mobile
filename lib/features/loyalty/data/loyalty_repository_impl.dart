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
