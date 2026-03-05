import '../../domain/entities/search_hotel_entity.dart';

class SearchHotelModel extends SearchHotelEntity {
  const SearchHotelModel({
    required super.id,
    required super.name,
    required super.location,
    required super.city,
    required super.pricePerNight,
    required super.rating,
    required super.reviewCount,
    required super.isPromo,
    required super.amenities,
  });

  factory SearchHotelModel.fromJson(Map<String, dynamic> json) {
    return SearchHotelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      city: json['city'] as String? ?? '',
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      isPromo: json['isPromo'] as bool? ?? false,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'location': location, 'city': city,
    'pricePerNight': pricePerNight, 'rating': rating,
    'reviewCount': reviewCount, 'isPromo': isPromo, 'amenities': amenities,
  };
}
