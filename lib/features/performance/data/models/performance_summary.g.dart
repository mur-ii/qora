// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_summary.dart';

class InteractionMethodAdapter extends TypeAdapter<InteractionMethod> {
  @override
  int get typeId => interactionMethodTypeId;

  @override
  InteractionMethod read(BinaryReader reader) {
    final index = reader.readByte();
    return InteractionMethod.values[index];
  }

  @override
  void write(BinaryWriter writer, InteractionMethod obj) {
    writer.writeByte(obj.index);
  }
}

class PerformanceSummaryAdapter extends TypeAdapter<PerformanceSummary> {
  @override
  int get typeId => performanceSummaryTypeId;

  @override
  PerformanceSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return PerformanceSummary(
      sessionId: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      durationInSeconds: fields[3] as int,
      interactionMethod: fields[4] as InteractionMethod,
      totalClicks: fields[5] as int,
      totalVoiceCommands: fields[6] as int,
      errorsCount: fields[7] as int,
      taskCompleted: fields[8] as bool,
      searchedLocation: fields[9] as String,
      selectedHotelName: fields[10] as String?,
      bookingSuccess: fields[11] as bool,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceSummary obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationInSeconds)
      ..writeByte(4)
      ..write(obj.interactionMethod)
      ..writeByte(5)
      ..write(obj.totalClicks)
      ..writeByte(6)
      ..write(obj.totalVoiceCommands)
      ..writeByte(7)
      ..write(obj.errorsCount)
      ..writeByte(8)
      ..write(obj.taskCompleted)
      ..writeByte(9)
      ..write(obj.searchedLocation)
      ..writeByte(10)
      ..write(obj.selectedHotelName)
      ..writeByte(11)
      ..write(obj.bookingSuccess)
      ..writeByte(12)
      ..write(obj.createdAt);
  }
}
