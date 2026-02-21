import 'package:hive/hive.dart';

const int loginSessionTypeId = 33;

class LoginSession {
  final String sessionId;
  final String fullName;
  final DateTime loginAt;
  final DateTime? logoutAt;

  const LoginSession({
    required this.sessionId,
    required this.fullName,
    required this.loginAt,
    this.logoutAt,
  });

  LoginSession copyWith({
    String? fullName,
    DateTime? loginAt,
    DateTime? logoutAt,
  }) {
    return LoginSession(
      sessionId: sessionId,
      fullName: fullName ?? this.fullName,
      loginAt: loginAt ?? this.loginAt,
      logoutAt: logoutAt ?? this.logoutAt,
    );
  }
}

class LoginSessionAdapter extends TypeAdapter<LoginSession> {
  @override
  int get typeId => loginSessionTypeId;

  @override
  LoginSession read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return LoginSession(
      sessionId: fields[0] as String,
      fullName: fields[1] as String,
      loginAt: fields[2] as DateTime,
      logoutAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LoginSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.loginAt)
      ..writeByte(3)
      ..write(obj.logoutAt);
  }
}
