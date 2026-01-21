import 'package:equatable/equatable.dart';

class PaymentMethodEntity extends Equatable {
  const PaymentMethodEntity({
    required this.id,
    required this.type,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.isDefault,
  });

  final String id;
  final String type; // 'visa', 'mastercard', 'paypal', etc.
  final String cardNumber; // Last 4 digits
  final String cardHolderName;
  final String expiryDate;
  final bool isDefault;

  String get maskedCardNumber => '**** **** **** $cardNumber';

  @override
  List<Object?> get props => [
    id,
    type,
    cardNumber,
    cardHolderName,
    expiryDate,
    isDefault,
  ];
}
