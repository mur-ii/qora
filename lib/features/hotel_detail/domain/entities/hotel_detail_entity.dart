import 'package:equatable/equatable.dart';

class RoomTypeEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double pricePerNight;
  final int maxGuests;
  final int size;
  final String bedType;
  final List<String> amenities;
  final int availableRooms;

  const RoomTypeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerNight,
    required this.maxGuests,
    required this.size,
    required this.bedType,
    required this.amenities,
    this.availableRooms = 0,
  });

  @override
  List<Object?> get props => [
    id, name, description, pricePerNight, maxGuests, size, bedType, amenities, availableRooms,
  ];
}

class FacilityEntity extends Equatable {
  final String name;
  final String icon;

  const FacilityEntity({required this.name, required this.icon});

  @override
  List<Object?> get props => [name, icon];
}

class ReviewEntity extends Equatable {
  final String userName;
  final double rating;
  final String comment;
  final String date;

  const ReviewEntity({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  List<Object?> get props => [userName, rating, comment, date];
}

class PolicyEntity extends Equatable {
  final String checkIn;
  final String checkOut;
  final bool pets;
  final bool smoking;

  const PolicyEntity({
    required this.checkIn,
    required this.checkOut,
    required this.pets,
    required this.smoking,
  });

  @override
  List<Object?> get props => [checkIn, checkOut, pets, smoking];
}

class HotelDetailEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String location;
  final String city;
  final String address;
  final double rating;
  final int reviewCount;
  final int starRating;
  final double pricePerNight;
  final List<FacilityEntity> facilities;
  final PolicyEntity policies;
  final List<RoomTypeEntity> roomTypes;
  final List<ReviewEntity> reviews;

  const HotelDetailEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.city,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.starRating,
    required this.pricePerNight,
    required this.facilities,
    required this.policies,
    required this.roomTypes,
    required this.reviews,
  });

  @override
  List<Object?> get props => [
    id, name, description, location, city, address, rating, reviewCount,
    starRating, pricePerNight, facilities, policies, roomTypes, reviews,
  ];
}
