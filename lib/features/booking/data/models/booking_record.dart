import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'booking_record.g.dart';

const int bookingRecordTypeId = 32;

@HiveType(typeId: bookingRecordTypeId)
class BookingRecord extends Equatable {
  @HiveField(0)
  final String bookingId;
  @HiveField(1)
  final String hotelName;
  @HiveField(2)
  final String location;
  @HiveField(3)
  final String roomName;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final DateTime checkIn;
  @HiveField(6)
  final DateTime checkOut;
  @HiveField(7)
  final String bookingStatus;
  @HiveField(8)
  final String? confirmationNumber;
  @HiveField(9)
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
