import 'package:equatable/equatable.dart';

class BookingRecord extends Equatable {
  final String bookingId;
  final String hotelName;
  final String location;
  final String roomName;
  final String imageUrl;
  final DateTime checkIn;
  final DateTime checkOut;
  final String bookingStatus;
  final String? confirmationNumber;
  final DateTime createdAt;

  const BookingRecord({
    required this.bookingId,
    required this.hotelName,
    required this.location,
    required this.roomName,
    required this.imageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.bookingStatus,
    required this.confirmationNumber,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    bookingId,
    hotelName,
    location,
    roomName,
    imageUrl,
    checkIn,
    checkOut,
    bookingStatus,
    confirmationNumber,
    createdAt,
  ];
}
