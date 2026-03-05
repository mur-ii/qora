import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.username,
    required super.currentLevel,
    required super.currentXP,
    required super.xpToNextLevel,
    required super.phoneNumber,
    required super.joinedDate,
    super.bio,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      currentLevel: json['currentLevel'] as int? ?? 1,
      currentXP: json['currentXP'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'fullName': fullName, 'email': email, 'username': username,
    'currentLevel': currentLevel, 'currentXP': currentXP,
    'xpToNextLevel': xpToNextLevel, 'phoneNumber': phoneNumber,
    'joinedDate': joinedDate.toIso8601String(), 'bio': bio,
  };
}
