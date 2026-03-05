import 'package:equatable/equatable.dart';

class SearchHotelEntity extends Equatable {
  final String id;
  final String name;
  final String location;
  final String city;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final bool isPromo;
  final List<String> amenities;

  const SearchHotelEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.city,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.isPromo,
    required this.amenities,
  });

  @override
  List<Object?> get props => [
    id, name, location, city, pricePerNight, rating, reviewCount, isPromo, amenities,
  ];
}
