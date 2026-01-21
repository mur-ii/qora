import '../../domain/entities/booking_entity.dart';

class BookingModel {
  final String bookingId;
  final String? confirmationNumber;
  final String bookingStatus;
  final DateTime? bookingDate;
  final HotelInfoModel hotel;
  final RoomInfoModel room;
  final BookingDetailsModel bookingDetails;
  final GuestInfoModel guestInfo;
  final PricingModel pricing;
  final PaymentModel? payment;
  final CancellationPolicyModel? cancellationPolicy;

  BookingModel({
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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] as String,
      confirmationNumber: json['confirmationNumber'] as String?,
      bookingStatus: json['bookingStatus'] as String,
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'] as String)
          : null,
      hotel: HotelInfoModel.fromJson(json['hotel'] as Map<String, dynamic>),
      room: RoomInfoModel.fromJson(json['room'] as Map<String, dynamic>),
      bookingDetails: BookingDetailsModel.fromJson(
        json['bookingDetails'] as Map<String, dynamic>,
      ),
      guestInfo: GuestInfoModel.fromJson(
        json['guestInfo'] as Map<String, dynamic>,
      ),
      pricing: PricingModel.fromJson(json['pricing'] as Map<String, dynamic>),
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      cancellationPolicy: json['cancellationPolicy'] != null
          ? CancellationPolicyModel.fromJson(
              json['cancellationPolicy'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'confirmationNumber': confirmationNumber,
      'bookingStatus': bookingStatus,
      'bookingDate': bookingDate?.toIso8601String(),
      'hotel': hotel.toJson(),
      'room': room.toJson(),
      'bookingDetails': bookingDetails.toJson(),
      'guestInfo': guestInfo.toJson(),
      'pricing': pricing.toJson(),
      'payment': payment?.toJson(),
      'cancellationPolicy': cancellationPolicy?.toJson(),
    };
  }

  BookingEntity toEntity() {
    return BookingEntity(
      bookingId: bookingId,
      confirmationNumber: confirmationNumber,
      bookingStatus: bookingStatus,
      bookingDate: bookingDate,
      hotel: hotel.toEntity(),
      room: room.toEntity(),
      bookingDetails: bookingDetails.toEntity(),
      guestInfo: guestInfo.toEntity(),
      pricing: pricing.toEntity(),
      payment: payment?.toEntity(),
      cancellationPolicy: cancellationPolicy?.toEntity(),
    );
  }
}

class HotelInfoModel {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String imageUrl;
  final String phone;
  final String email;

  HotelInfoModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    required this.phone,
    required this.email,
  });

  factory HotelInfoModel.fromJson(Map<String, dynamic> json) {
    return HotelInfoModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'imageUrl': imageUrl,
      'phone': phone,
      'email': email,
    };
  }

  HotelInfoEntity toEntity() {
    return HotelInfoEntity(
      id: id,
      name: name,
      address: address,
      rating: rating,
      imageUrl: imageUrl,
      phone: phone,
      email: email,
    );
  }
}

class RoomInfoModel {
  final String id;
  final String name;
  final String imageUrl;
  final String bedType;
  final int maxGuests;
  final String? roomNumber;

  RoomInfoModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.bedType,
    required this.maxGuests,
    this.roomNumber,
  });

  factory RoomInfoModel.fromJson(Map<String, dynamic> json) {
    return RoomInfoModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      bedType: json['bedType'] as String,
      maxGuests: json['maxGuests'] as int,
      roomNumber: json['roomNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bedType': bedType,
      'maxGuests': maxGuests,
      'roomNumber': roomNumber,
    };
  }

  RoomInfoEntity toEntity() {
    return RoomInfoEntity(
      id: id,
      name: name,
      imageUrl: imageUrl,
      bedType: bedType,
      maxGuests: maxGuests,
      roomNumber: roomNumber,
    );
  }
}

class BookingDetailsModel {
  final String checkIn;
  final String checkOut;
  final String checkInTime;
  final String checkOutTime;
  final int nights;
  final int guests;
  final int rooms;

  BookingDetailsModel({
    required this.checkIn,
    required this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.nights,
    required this.guests,
    required this.rooms,
  });

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailsModel(
      checkIn: json['checkIn'] as String,
      checkOut: json['checkOut'] as String,
      checkInTime: json['checkInTime'] as String,
      checkOutTime: json['checkOutTime'] as String,
      nights: json['nights'] as int,
      guests: json['guests'] as int,
      rooms: json['rooms'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'nights': nights,
      'guests': guests,
      'rooms': rooms,
    };
  }

  BookingDetailsEntity toEntity() {
    return BookingDetailsEntity(
      checkIn: checkIn,
      checkOut: checkOut,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      nights: nights,
      guests: guests,
      rooms: rooms,
    );
  }
}

class GuestInfoModel {
  final PrimaryGuestModel primaryGuest;
  final String? specialRequests;

  GuestInfoModel({
    required this.primaryGuest,
    this.specialRequests,
  });

  factory GuestInfoModel.fromJson(Map<String, dynamic> json) {
    return GuestInfoModel(
      primaryGuest: PrimaryGuestModel.fromJson(
        json['primaryGuest'] as Map<String, dynamic>,
      ),
      specialRequests: json['specialRequests'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryGuest': primaryGuest.toJson(),
      'specialRequests': specialRequests,
    };
  }

  GuestInfoEntity toEntity() {
    return GuestInfoEntity(
      primaryGuest: primaryGuest.toEntity(),
      specialRequests: specialRequests,
    );
  }
}

class PrimaryGuestModel {
  final String title;
  final String fullName;
  final String email;
  final String phone;

  PrimaryGuestModel({
    required this.title,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory PrimaryGuestModel.fromJson(Map<String, dynamic> json) {
    return PrimaryGuestModel(
      title: json['title'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fullName': fullName,
      'email': email,
      'phone': phone,
    };
  }

  PrimaryGuestEntity toEntity() {
    return PrimaryGuestEntity(
      title: title,
      fullName: fullName,
      email: email,
      phone: phone,
    );
  }
}

class PricingModel {
  final double subtotal;
  final double taxes;
  final double fees;
  final double discount;
  final double grandTotal;
  final String currency;
  final double? dueNow;
  final double? dueAtProperty;

  PricingModel({
    required this.subtotal,
    required this.taxes,
    required this.fees,
    required this.discount,
    required this.grandTotal,
    required this.currency,
    this.dueNow,
    this.dueAtProperty,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      subtotal: (json['subtotal'] as num).toDouble(),
      taxes: (json['taxes'] as num).toDouble(),
      fees: (json['fees'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      currency: json['currency'] as String,
      dueNow: json['dueNow'] != null ? (json['dueNow'] as num).toDouble() : null,
      dueAtProperty: json['dueAtProperty'] != null
          ? (json['dueAtProperty'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'taxes': taxes,
      'fees': fees,
      'discount': discount,
      'grandTotal': grandTotal,
      'currency': currency,
      'dueNow': dueNow,
      'dueAtProperty': dueAtProperty,
    };
  }

  PricingEntity toEntity() {
    return PricingEntity(
      subtotal: subtotal,
      taxes: taxes,
      fees: fees,
      discount: discount,
      grandTotal: grandTotal,
      currency: currency,
      dueNow: dueNow,
      dueAtProperty: dueAtProperty,
    );
  }
}

class PaymentModel {
  final String transactionId;
  final String paymentMethod;
  final DateTime paymentDate;
  final double amount;
  final String status;

  PaymentModel({
    required this.transactionId,
    required this.paymentMethod,
    required this.paymentDate,
    required this.amount,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      transactionId: json['transactionId'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'status': status,
    };
  }

  PaymentEntity toEntity() {
    return PaymentEntity(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      amount: amount,
      status: status,
    );
  }
}

class CancellationPolicyModel {
  final String type;
  final String description;
  final bool refundable;
  final DateTime? deadline;

  CancellationPolicyModel({
    required this.type,
    required this.description,
    required this.refundable,
    this.deadline,
  });

  factory CancellationPolicyModel.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyModel(
      type: json['type'] as String,
      description: json['description'] as String,
      refundable: json['refundable'] as bool,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'refundable': refundable,
      'deadline': deadline?.toIso8601String(),
    };
  }

  CancellationPolicyEntity toEntity() {
    return CancellationPolicyEntity(
      type: type,
      description: description,
      refundable: refundable,
      deadline: deadline,
    );
  }
}
