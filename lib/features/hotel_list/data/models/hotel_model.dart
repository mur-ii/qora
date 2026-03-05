import '../../domain/entities/hotel_entity.dart';

class HotelModel extends HotelEntity {
  const HotelModel({
    required super.id,
    required super.name,
    required super.location,
    required super.pricePerNight,
    required super.rating,
    required super.isPromo,
    required super.amenities,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      isPromo: json['isPromo'] as bool? ?? false,
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((amenity) => amenity.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'pricePerNight': pricePerNight,
      'rating': rating,
      'isPromo': isPromo,
      'amenities': amenities,
    };
  }
}
