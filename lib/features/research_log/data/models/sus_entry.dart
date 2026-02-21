import 'package:hive/hive.dart';

const int susEntryTypeId = 34;

class SusEntry {
  final String entryId;
  final String testerSessionId;
  final String fullName;
  final List<int> answers;
  final double score;
  final DateTime createdAt;

  const SusEntry({
    required this.entryId,
    required this.testerSessionId,
    required this.fullName,
    required this.answers,
    required this.score,
    required this.createdAt,
  });
}

class SusEntryAdapter extends TypeAdapter<SusEntry> {
  @override
  int get typeId => susEntryTypeId;

  @override
  SusEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return SusEntry(
      entryId: fields[0] as String,
      testerSessionId: fields[1] as String,
      fullName: fields[2] as String,
      answers: (fields[3] as List).cast<int>(),
      score: fields[4] as double,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SusEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.entryId)
      ..writeByte(1)
      ..write(obj.testerSessionId)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.answers)
      ..writeByte(4)
      ..write(obj.score)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
