import 'package:equatable/equatable.dart';

enum PixPaymentStatus { waiting, paid }

class PixPaymentState extends Equatable {
  final PixPaymentStatus status;

  const PixPaymentState({this.status = PixPaymentStatus.waiting});

  PixPaymentState copyWith({PixPaymentStatus? status}) {
    return PixPaymentState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
