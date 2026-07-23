import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/loyalty/presentation/pix_payment_bloc.dart';
import 'package:baber_mobile/features/loyalty/presentation/pix_payment_event.dart';
import 'package:baber_mobile/features/loyalty/presentation/pix_payment_state.dart';

class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

void main() {
  late MockLoyaltyRepository repository;

  setUp(() {
    repository = MockLoyaltyRepository();
  });

  blocTest<PixPaymentBloc, PixPaymentState>(
    'stays waiting when the status is not a paid status',
    build: () {
      when(() => repository.getPaymentStatus('pay_1')).thenAnswer((_) async => const Right('PENDING'));
      return PixPaymentBloc(repository: repository, paymentId: 'pay_1', pollInterval: const Duration(milliseconds: 10));
    },
    act: (bloc) => bloc.add(const PixPaymentStatusTicked()),
    expect: () => <PixPaymentState>[],
  );

  blocTest<PixPaymentBloc, PixPaymentState>(
    'emits paid when the status is RECEIVED',
    build: () {
      when(() => repository.getPaymentStatus('pay_1')).thenAnswer((_) async => const Right('RECEIVED'));
      return PixPaymentBloc(repository: repository, paymentId: 'pay_1', pollInterval: const Duration(milliseconds: 10));
    },
    act: (bloc) => bloc.add(const PixPaymentStatusTicked()),
    expect: () => [const PixPaymentState(status: PixPaymentStatus.paid)],
  );

  blocTest<PixPaymentBloc, PixPaymentState>(
    'ignores a failed status check and stays waiting',
    build: () {
      when(() => repository.getPaymentStatus('pay_1'))
          .thenAnswer((_) async => const Left(NetworkFailure('timeout')));
      return PixPaymentBloc(repository: repository, paymentId: 'pay_1', pollInterval: const Duration(milliseconds: 10));
    },
    act: (bloc) => bloc.add(const PixPaymentStatusTicked()),
    expect: () => <PixPaymentState>[],
  );

  test('PixPaymentStarted schedules periodic ticks until paid, then stops', () async {
    var callCount = 0;
    when(() => repository.getPaymentStatus('pay_1')).thenAnswer((_) async {
      callCount++;
      return Right(callCount >= 2 ? 'CONFIRMED' : 'PENDING');
    });
    final bloc = PixPaymentBloc(repository: repository, paymentId: 'pay_1', pollInterval: const Duration(milliseconds: 10));

    bloc.add(const PixPaymentStarted());
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(bloc.state.status, PixPaymentStatus.paid);
    expect(callCount, 2);
    await bloc.close();
  });
}
