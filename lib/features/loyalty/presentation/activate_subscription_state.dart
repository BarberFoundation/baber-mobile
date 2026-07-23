import 'package:equatable/equatable.dart';
import '../domain/pix_payment.dart';

class ActivateSubscriptionState extends Equatable {
  final bool isLoading;
  final bool activated;
  final PixPayment? pixPayment;
  final String? errorMessage;

  const ActivateSubscriptionState({
    this.isLoading = false,
    this.activated = false,
    this.pixPayment,
    this.errorMessage,
  });

  ActivateSubscriptionState copyWith({
    bool? isLoading,
    bool? activated,
    PixPayment? pixPayment,
    String? errorMessage,
  }) {
    return ActivateSubscriptionState(
      isLoading: isLoading ?? false,
      activated: activated ?? false,
      pixPayment: pixPayment,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, activated, pixPayment, errorMessage];
}
