import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.username,
    required super.avatarUrl,
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
      avatarUrl: json['avatarUrl'] as String,
      currentLevel: json['currentLevel'] as int,
      currentXP: json['currentXP'] as int,
      xpToNextLevel: json['xpToNextLevel'] as int,
      phoneNumber: json['phoneNumber'] as String,
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'currentLevel': currentLevel,
      'currentXP': currentXP,
      'xpToNextLevel': xpToNextLevel,
      'phoneNumber': phoneNumber,
      'joinedDate': joinedDate.toIso8601String(),
      'bio': bio,
    };
  }
}
