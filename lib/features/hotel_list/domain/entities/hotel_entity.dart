import 'package:equatable/equatable.dart';

class HotelEntity extends Equatable {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final double pricePerNight;
  final double rating;
  final bool isPromo;

  const HotelEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.pricePerNight,
    required this.rating,
    required this.isPromo,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    location,
    imageUrl,
    pricePerNight,
    rating,
    isPromo,
  ];
}
