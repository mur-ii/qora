import 'package:equatable/equatable.dart';

class PromoEntity extends Equatable {
  const PromoEntity({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colorKey,
    required this.iconKey,
  });

  final String title;
  final String subtitle;
  final String badge;

  /// Maps to a colour in the presentation layer (e.g. 'primary', 'success').
  final String colorKey;

  /// Maps to an icon in the presentation layer (e.g. 'fire', 'weekend').
  final String iconKey;

  @override
  List<Object?> get props => [title, subtitle, badge, colorKey, iconKey];
}

class DestinationEntity extends Equatable {
  const DestinationEntity({required this.name, required this.iconKey});

  final String name;

  /// Maps to an icon in the presentation layer (e.g. 'beach', 'city').
  final String iconKey;

  @override
  List<Object?> get props => [name, iconKey];
}

class HomeEntity extends Equatable {
  const HomeEntity({required this.promos, required this.popularDestinations});

  final List<PromoEntity> promos;
  final List<DestinationEntity> popularDestinations;

  @override
  List<Object?> get props => [promos, popularDestinations];
}
