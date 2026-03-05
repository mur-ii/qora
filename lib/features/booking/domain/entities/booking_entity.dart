import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String bookingId;
  final String? confirmationNumber;
  final String bookingStatus;
  final DateTime? bookingDate;
  final HotelInfoEntity hotel;
  final RoomInfoEntity room;
  final BookingDetailsEntity bookingDetails;
  final GuestInfoEntity guestInfo;
  final PricingEntity pricing;
  final PaymentEntity? payment;
  final CancellationPolicyEntity? cancellationPolicy;

  const BookingEntity({
    required this.bookingId,
    this.confirmationNumber,
    required this.bookingStatus,
    this.bookingDate,
    required this.hotel,
    required this.room,
    required this.bookingDetails,
    required this.guestInfo,
    required this.pricing,
    this.payment,
    this.cancellationPolicy,
  });

  @override
  List<Object?> get props => [
    bookingId,
    confirmationNumber,
    bookingStatus,
    bookingDate,
    hotel,
    room,
    bookingDetails,
    guestInfo,
    pricing,
    payment,
    cancellationPolicy,
  ];
}

class HotelInfoEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String phone;
  final String email;

  const HotelInfoEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.phone,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, address, rating, phone, email];
}

class RoomInfoEntity extends Equatable {
  final String id;
  final String name;
  final String bedType;
  final int maxGuests;
  final String? roomNumber;

  const RoomInfoEntity({
    required this.id,
    required this.name,
    required this.bedType,
    required this.maxGuests,
    this.roomNumber,
  });

  @override
  List<Object?> get props => [id, name, bedType, maxGuests, roomNumber];
}

class BookingDetailsEntity extends Equatable {
  final String checkIn;
  final String checkOut;
  final String checkInTime;
  final String checkOutTime;
  final int nights;
  final int guests;
  final int rooms;

  const BookingDetailsEntity({
    required this.checkIn,
    required this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.nights,
    required this.guests,
    required this.rooms,
  });

  @override
  List<Object?> get props => [
    checkIn,
    checkOut,
    checkInTime,
    checkOutTime,
    nights,
    guests,
    rooms,
  ];
}

class GuestInfoEntity extends Equatable {
  final PrimaryGuestEntity primaryGuest;
  final String? specialRequests;

  const GuestInfoEntity({required this.primaryGuest, this.specialRequests});

  @override
  List<Object?> get props => [primaryGuest, specialRequests];
}

class PrimaryGuestEntity extends Equatable {
  final String title;
  final String fullName;
  final String email;
  final String phone;

  const PrimaryGuestEntity({
    required this.title,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  @override
  List<Object?> get props => [title, fullName, email, phone];
}

class PricingEntity extends Equatable {
  final double subtotal;
  final double taxes;
  final double fees;
  final double discount;
  final double grandTotal;
  final String currency;
  final double? dueNow;
  final double? dueAtProperty;

  const PricingEntity({
    required this.subtotal,
    required this.taxes,
    required this.fees,
    required this.discount,
    required this.grandTotal,
    required this.currency,
    this.dueNow,
    this.dueAtProperty,
  });

  @override
  List<Object?> get props => [
    subtotal,
    taxes,
    fees,
    discount,
    grandTotal,
    currency,
    dueNow,
    dueAtProperty,
  ];
}

class PaymentEntity extends Equatable {
  final String transactionId;
  final String paymentMethod;
  final DateTime paymentDate;
  final double amount;
  final String status;

  const PaymentEntity({
    required this.transactionId,
    required this.paymentMethod,
    required this.paymentDate,
    required this.amount,
    required this.status,
  });

  @override
  List<Object?> get props => [
    transactionId,
    paymentMethod,
    paymentDate,
    amount,
    status,
  ];
}

class CancellationPolicyEntity extends Equatable {
  final String type;
  final String description;
  final bool refundable;
  final DateTime? deadline;

  const CancellationPolicyEntity({
    required this.type,
    required this.description,
    required this.refundable,
    this.deadline,
  });

  @override
  List<Object?> get props => [type, description, refundable, deadline];
}
