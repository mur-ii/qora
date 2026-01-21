import 'package:equatable/equatable.dart';

class GuestFormEntity extends Equatable {
  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? specialRequests;

  const GuestFormEntity({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.specialRequests,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    title,
    firstName,
    lastName,
    email,
    phone,
    specialRequests,
  ];
}
