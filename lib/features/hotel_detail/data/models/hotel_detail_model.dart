import '../../domain/entities/hotel_detail_entity.dart';

class RoomTypeModel extends RoomTypeEntity {
  const RoomTypeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.pricePerNight,
    required super.maxGuests,
    required super.size,
    required super.bedType,
    required super.amenities,
    super.availableRooms,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      maxGuests: json['maxGuests'] as int? ?? 2,
      size: json['size'] as int? ?? 20,
      bedType: json['bedType'] as String? ?? 'Double',
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      availableRooms: json['availableRooms'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'pricePerNight': pricePerNight, 'maxGuests': maxGuests,
    'size': size, 'bedType': bedType, 'amenities': amenities,
    'availableRooms': availableRooms,
  };
}

class FacilityModel extends FacilityEntity {
  const FacilityModel({required super.name, required super.icon});

  factory FacilityModel.fromJson(Map<String, dynamic> json) =>
      FacilityModel(
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'check',
      );

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon};
}

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.userName,
    required super.rating,
    required super.comment,
    required super.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    userName: json['userName'] as String? ?? 'Anonymous',
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'] as String? ?? '',
    date: json['date'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'userName': userName, 'rating': rating,
    'comment': comment, 'date': date,
  };
}

class PolicyModel extends PolicyEntity {
  const PolicyModel({
    required super.checkIn,
    required super.checkOut,
    required super.pets,
    required super.smoking,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) => PolicyModel(
    checkIn: json['checkIn'] as String? ?? '14:00',
    checkOut: json['checkOut'] as String? ?? '12:00',
    pets: json['pets'] as bool? ?? false,
    smoking: json['smoking'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() =>
      {'checkIn': checkIn, 'checkOut': checkOut, 'pets': pets, 'smoking': smoking};
}

class HotelDetailModel extends HotelDetailEntity {
  const HotelDetailModel({
    required super.id,
    required super.name,
    required super.description,
    required super.location,
    required super.city,
    required super.address,
    required super.rating,
    required super.reviewCount,
    required super.starRating,
    required super.pricePerNight,
    required super.facilities,
    required super.policies,
    required super.roomTypes,
    required super.reviews,
  });

  factory HotelDetailModel.fromJson(Map<String, dynamic> json) {
    return HotelDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      starRating: json['starRating'] as int? ?? 3,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      policies: PolicyModel.fromJson(
          json['policies'] as Map<String, dynamic>? ?? {}),
      roomTypes: (json['roomTypes'] as List<dynamic>?)
              ?.map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'location': location,
    'city': city, 'address': address, 'rating': rating,
    'reviewCount': reviewCount, 'starRating': starRating,
    'pricePerNight': pricePerNight,
    'facilities': facilities.map((f) => (f as FacilityModel).toJson()).toList(),
    'policies': (policies as PolicyModel).toJson(),
    'roomTypes': roomTypes.map((r) => (r as RoomTypeModel).toJson()).toList(),
    'reviews': reviews.map((r) => (r as ReviewModel).toJson()).toList(),
  };
}
