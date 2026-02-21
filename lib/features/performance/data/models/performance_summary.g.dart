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
      testerSessionId: fields[18] as String?,
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
      searchDurationSeconds: (fields[13] as int?) ?? 0,
      selectionDurationSeconds: (fields[14] as int?) ?? 0,
      paymentDurationSeconds: (fields[15] as int?) ?? 0,
      confirmationDurationSeconds: (fields[16] as int?) ?? 0,
      errorTypes: (fields[17] as List?)?.cast<String>() ?? <String>[],
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceSummary obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(18)
      ..write(obj.testerSessionId)
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
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.searchDurationSeconds)
      ..writeByte(14)
      ..write(obj.selectionDurationSeconds)
      ..writeByte(15)
      ..write(obj.paymentDurationSeconds)
      ..writeByte(16)
      ..write(obj.confirmationDurationSeconds)
      ..writeByte(17)
      ..write(obj.errorTypes);
  }
}
