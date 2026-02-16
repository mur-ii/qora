// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_record.dart';

class ParticipantRecordAdapter extends TypeAdapter<ParticipantRecord> {
  @override
  int get typeId => participantRecordTypeId;

  @override
  ParticipantRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ParticipantRecord(
      participantId: fields[0] as String,
      age: fields[1] as int,
      gender: fields[2] as String,
      techFamiliarity: fields[3] as int,
      voiceFamiliarity: fields[4] as int,
      guiFirst: fields[5] as bool,
      notes: fields[6] as String,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ParticipantRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.participantId)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.techFamiliarity)
      ..writeByte(4)
      ..write(obj.voiceFamiliarity)
      ..writeByte(5)
      ..write(obj.guiFirst)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}
