import 'package:equatable/equatable.dart';

class PixPayment extends Equatable {
  final String paymentId;
  final String encodedImage;
  final String payload;
  final String expirationDate;

  const PixPayment({
    required this.paymentId,
    required this.encodedImage,
    required this.payload,
    required this.expirationDate,
  });

  factory PixPayment.fromJson(Map<String, dynamic> json) => PixPayment(
        paymentId: json['paymentId'] as String,
        encodedImage: (json['pix'] as Map<String, dynamic>)['encodedImage'] as String,
        payload: (json['pix'] as Map<String, dynamic>)['payload'] as String,
        expirationDate: (json['pix'] as Map<String, dynamic>)['expirationDate'] as String,
      );

  @override
  List<Object?> get props => [paymentId, encodedImage, payload, expirationDate];
}
