import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../domain/loyalty_repository.dart';
import 'pix_payment_event.dart';
import 'pix_payment_state.dart';

const _paidStatuses = {'RECEIVED', 'CONFIRMED', 'RECEIVED_IN_CASH'};

class PixPaymentBloc extends Bloc<PixPaymentEvent, PixPaymentState> {
  final LoyaltyRepository repository;
  final String paymentId;
  final Duration pollInterval;
  final Duration maxPollInterval;
  final int maxAttempts;
  Timer? _timer;
  int _attempts = 0;
  Duration _currentInterval;

  PixPaymentBloc({
    required this.repository,
    required this.paymentId,
    this.pollInterval = const Duration(seconds: 4),
    this.maxPollInterval = const Duration(seconds: 30),
    // ~10 min worst case at the base interval — a PIX QR code isn't valid
    // forever either, so polling past this point is pointless.
    this.maxAttempts = 150,
  })  : _currentInterval = pollInterval,
        super(const PixPaymentState()) {
    on<PixPaymentStarted>(_onStarted);
    on<PixPaymentStatusTicked>(_onTicked);
  }

  void _onStarted(PixPaymentStarted event, Emitter<PixPaymentState> emit) {
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    _timer = Timer(_currentInterval, () => add(const PixPaymentStatusTicked()));
  }

  Future<void> _onTicked(PixPaymentStatusTicked event, Emitter<PixPaymentState> emit) async {
    if (state.status != PixPaymentStatus.waiting) return;

    _attempts++;
    if (_attempts > maxAttempts) {
      emit(state.copyWith(status: PixPaymentStatus.timedOut));
      return;
    }

    final result = await repository.getPaymentStatus(paymentId);
    result.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          emit(state.copyWith(status: PixPaymentStatus.sessionExpired));
          return;
        }
        // Back off on repeated failures instead of hammering the API forever
        // at a fixed 4s cadence.
        final doubled = _currentInterval * 2;
        _currentInterval = doubled > maxPollInterval ? maxPollInterval : doubled;
        _scheduleNextTick();
      },
      (status) {
        _currentInterval = pollInterval;
        if (_paidStatuses.contains(status)) {
          emit(state.copyWith(status: PixPaymentStatus.paid));
          return;
        }
        _scheduleNextTick();
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
