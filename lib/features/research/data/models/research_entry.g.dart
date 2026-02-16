// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_entry.dart';

class ResearchPreferenceAdapter extends TypeAdapter<ResearchPreference> {
  @override
  int get typeId => researchPreferenceTypeId;

  @override
  ResearchPreference read(BinaryReader reader) {
    final index = reader.readByte();
    return ResearchPreference.values[index];
  }

  @override
  void write(BinaryWriter writer, ResearchPreference obj) {
    writer.writeByte(obj.index);
  }
}

class ResearchEntryAdapter extends TypeAdapter<ResearchEntry> {
  @override
  int get typeId => researchEntryTypeId;

  @override
  ResearchEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ResearchEntry(
      entryId: fields[0] as String,
      participantId: fields[1] as String,
      sessionId: fields[2] as String,
      method: fields[3] as String,
      taskOrder: fields[4] as int,
      susScore: fields[5] as double,
      umuxScore: fields[6] as double,
      satisfactionScore: fields[7] as int,
      trustScore: fields[8] as int,
      preference: fields[9] as ResearchPreference,
      notes: fields[10] as String,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ResearchEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.entryId)
      ..writeByte(1)
      ..write(obj.participantId)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.taskOrder)
      ..writeByte(5)
      ..write(obj.susScore)
      ..writeByte(6)
      ..write(obj.umuxScore)
      ..writeByte(7)
      ..write(obj.satisfactionScore)
      ..writeByte(8)
      ..write(obj.trustScore)
      ..writeByte(9)
      ..write(obj.preference)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt);
  }
}
