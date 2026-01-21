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
    required super.imageUrl,
    required super.amenities,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      maxGuests: json['maxGuests'] as int,
      size: json['size'] as int,
      bedType: json['bedType'] as String,
      imageUrl: json['imageUrl'] as String,
      amenities: (json['amenities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerNight': pricePerNight,
      'maxGuests': maxGuests,
      'size': size,
      'bedType': bedType,
      'imageUrl': imageUrl,
      'amenities': amenities,
    };
  }
}

class FacilityModel extends FacilityEntity {
  const FacilityModel({required super.name, required super.icon});

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'icon': icon};
  }
}

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.userName,
    required super.userAvatar,
    required super.rating,
    required super.comment,
    required super.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }
}

class PolicyModel extends PolicyEntity {
  const PolicyModel({
    required super.checkIn,
    required super.checkOut,
    required super.pets,
    required super.smoking,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      checkIn: json['checkIn'] as String,
      checkOut: json['checkOut'] as String,
      pets: json['pets'] as bool,
      smoking: json['smoking'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'pets': pets,
      'smoking': smoking,
    };
  }
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
    required super.imageUrl,
    required super.gallery,
    required super.facilities,
    required super.policies,
    required super.roomTypes,
    required super.reviews,
  });

  factory HotelDetailModel.fromJson(Map<String, dynamic> json) {
    return HotelDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      city: json['city'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      starRating: json['starRating'] as int,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      gallery: (json['gallery'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      facilities: (json['facilities'] as List<dynamic>)
          .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      policies: PolicyModel.fromJson(json['policies'] as Map<String, dynamic>),
      roomTypes: (json['roomTypes'] as List<dynamic>)
          .map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'city': city,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'starRating': starRating,
      'pricePerNight': pricePerNight,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'facilities': facilities
          .map((f) => (f as FacilityModel).toJson())
          .toList(),
      'policies': (policies as PolicyModel).toJson(),
      'roomTypes': roomTypes.map((r) => (r as RoomTypeModel).toJson()).toList(),
      'reviews': reviews.map((r) => (r as ReviewModel).toJson()).toList(),
    };
  }
}
