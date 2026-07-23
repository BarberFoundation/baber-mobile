import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/loyalty_repository.dart';
import 'pix_payment_event.dart';
import 'pix_payment_state.dart';

const _paidStatuses = {'RECEIVED', 'CONFIRMED', 'RECEIVED_IN_CASH'};

class PixPaymentBloc extends Bloc<PixPaymentEvent, PixPaymentState> {
  final LoyaltyRepository repository;
  final String paymentId;
  final Duration pollInterval;
  Timer? _timer;

  PixPaymentBloc({
    required this.repository,
    required this.paymentId,
    this.pollInterval = const Duration(seconds: 4),
  }) : super(const PixPaymentState()) {
    on<PixPaymentStarted>(_onStarted);
    on<PixPaymentStatusTicked>(_onTicked);
  }

  void _onStarted(PixPaymentStarted event, Emitter<PixPaymentState> emit) {
    _timer = Timer.periodic(pollInterval, (_) => add(const PixPaymentStatusTicked()));
  }

  Future<void> _onTicked(PixPaymentStatusTicked event, Emitter<PixPaymentState> emit) async {
    if (state.status == PixPaymentStatus.paid) return;
    final result = await repository.getPaymentStatus(paymentId);
    result.fold(
      (_) {},
      (status) {
        if (_paidStatuses.contains(status)) {
          _timer?.cancel();
          emit(state.copyWith(status: PixPaymentStatus.paid));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
