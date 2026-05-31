import 'package:equatable/equatable.dart';

class HotelEntity extends Equatable {
  final String id;
  final String name;
  final String location;
  final double pricePerNight;
  final double rating;
  final List<String> amenities;

  const HotelEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerNight,
    required this.rating,
    required this.amenities,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    location,
    pricePerNight,
    rating,
    amenities,
  ];
}
