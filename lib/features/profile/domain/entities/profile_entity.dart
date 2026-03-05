import 'package:equatable/equatable.dart';

/// User profile entity
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.currentLevel,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.phoneNumber,
    required this.joinedDate,
    this.bio,
  });

  final String id;
  final String fullName;
  final String email;
  final String username;
  final int currentLevel;
  final int currentXP;
  final int xpToNextLevel;
  final String phoneNumber;
  final DateTime joinedDate;
  final String? bio;

  double get levelProgress => xpToNextLevel > 0 ? currentXP / xpToNextLevel : 0;

  String get levelTitle {
    if (currentLevel < 5) return 'Explorer';
    if (currentLevel < 10) return 'Adventurer';
    if (currentLevel < 20) return 'Traveler';
    if (currentLevel < 30) return 'Voyager';
    return 'Elite Traveler';
  }

  @override
  List<Object?> get props => [
    id, fullName, email, username, currentLevel, currentXP,
    xpToNextLevel, phoneNumber, joinedDate, bio,
  ];
}
