import 'package:equatable/equatable.dart';

sealed class PixPaymentEvent extends Equatable {
  const PixPaymentEvent();
  @override
  List<Object?> get props => [];
}

class PixPaymentStarted extends PixPaymentEvent {
  const PixPaymentStarted();
}

class PixPaymentStatusTicked extends PixPaymentEvent {
  const PixPaymentStatusTicked();
}
