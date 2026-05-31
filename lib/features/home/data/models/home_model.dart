import '../../domain/entities/home_entity.dart';

class PromoModel extends PromoEntity {
  const PromoModel({
    required super.title,
    required super.subtitle,
    required super.badge,
    required super.colorKey,
    required super.iconKey,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      badge: json['badge'] as String,
      colorKey: json['colorKey'] as String,
      iconKey: json['iconKey'] as String,
    );
  }
}

class DestinationModel extends DestinationEntity {
  const DestinationModel({required super.name, required super.iconKey});

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      name: json['name'] as String,
      iconKey: json['iconKey'] as String,
    );
  }
}

class HomeModel extends HomeEntity {
  const HomeModel({required super.promos, required super.popularDestinations});

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return HomeModel(
      promos: (data['promos'] as List<dynamic>)
          .map((e) => PromoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularDestinations: (data['popularDestinations'] as List<dynamic>)
          .map((e) => DestinationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
