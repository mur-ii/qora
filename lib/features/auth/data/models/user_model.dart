import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'photoUrl': photoUrl};
  }

  User toEntity() {
    return User(id: id, email: email, name: name, photoUrl: photoUrl);
  }
}
