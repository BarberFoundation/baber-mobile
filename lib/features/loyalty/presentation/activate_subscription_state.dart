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
