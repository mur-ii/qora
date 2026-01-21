import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    required this.description,
    this.hotelName,
  });

  final String id;
  final String type; // 'payment', 'refund', 'reward'
  final double amount;
  final DateTime date;
  final String status; // 'completed', 'pending', 'failed'
  final String description;
  final String? hotelName;

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    date,
    status,
    description,
    hotelName,
  ];
}
