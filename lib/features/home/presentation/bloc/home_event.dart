part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers loading of home screen data (promos, destinations).
class HomeDataRequested extends HomeEvent {
  const HomeDataRequested();
}

class HomeLocationChanged extends HomeEvent {
  const HomeLocationChanged(this.location);

  final String location;

  @override
  List<Object?> get props => [location];
}

class HomeDateRangeChanged extends HomeEvent {
  const HomeDateRangeChanged({
    required this.checkInDate,
    required this.checkOutDate,
  });

  final DateTime checkInDate;
  final DateTime checkOutDate;

  @override
  List<Object?> get props => [checkInDate, checkOutDate];
}

class HomeRoomCountChanged extends HomeEvent {
  const HomeRoomCountChanged(this.roomCount);

  final int roomCount;

  @override
  List<Object?> get props => [roomCount];
}

class HomeGuestCountChanged extends HomeEvent {
  const HomeGuestCountChanged(this.guestCount);

  final int guestCount;

  @override
  List<Object?> get props => [guestCount];
}

class HomeSearchSubmitted extends HomeEvent {
  const HomeSearchSubmitted();
}

class HomeVoiceConstraintsUpdated extends HomeEvent {
  const HomeVoiceConstraintsUpdated({
    this.location,
    this.checkInDate,
    this.checkOutDate,
    this.roomCount,
    this.guestCount,
  });

  final String? location;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? roomCount;
  final int? guestCount;

  @override
  List<Object?> get props => [
    location,
    checkInDate,
    checkOutDate,
    roomCount,
    guestCount,
  ];
}

class HomeStatusReset extends HomeEvent {
  const HomeStatusReset();
}
