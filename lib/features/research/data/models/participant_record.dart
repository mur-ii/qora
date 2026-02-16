import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'participant_record.g.dart';

const int participantRecordTypeId = 35;

@HiveType(typeId: participantRecordTypeId)
class ParticipantRecord extends Equatable {
  @HiveField(0)
  final String participantId;
  @HiveField(1)
  final int age;
  @HiveField(2)
  final String gender;
  @HiveField(3)
  final int techFamiliarity;
  @HiveField(4)
  final int voiceFamiliarity;
  @HiveField(5)
  final bool guiFirst;
  @HiveField(6)
  final String notes;
  @HiveField(7)
  final DateTime createdAt;

  const ParticipantRecord({
    required this.participantId,
    required this.age,
    required this.gender,
    required this.techFamiliarity,
    required this.voiceFamiliarity,
    required this.guiFirst,
    required this.notes,
    required this.createdAt,
  });

  ParticipantRecord copyWith({
    int? age,
    String? gender,
    int? techFamiliarity,
    int? voiceFamiliarity,
    bool? guiFirst,
    String? notes,
  }) {
    return ParticipantRecord(
      participantId: participantId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      techFamiliarity: techFamiliarity ?? this.techFamiliarity,
      voiceFamiliarity: voiceFamiliarity ?? this.voiceFamiliarity,
      guiFirst: guiFirst ?? this.guiFirst,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  List<String> toCsvRow() {
    return [
      participantId,
      age.toString(),
      gender,
      techFamiliarity.toString(),
      voiceFamiliarity.toString(),
      guiFirst ? 'GUI' : 'VUI',
      notes,
      createdAt.toIso8601String(),
    ];
  }

  @override
  List<Object?> get props => [
    participantId,
    age,
    gender,
    techFamiliarity,
    voiceFamiliarity,
    guiFirst,
    notes,
    createdAt,
  ];
}
