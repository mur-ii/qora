import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'research_entry.g.dart';

const int researchEntryTypeId = 33;
const int researchPreferenceTypeId = 34;

@HiveType(typeId: researchPreferenceTypeId)
enum ResearchPreference { gui, vui, noPreference }

@HiveType(typeId: researchEntryTypeId)
class ResearchEntry extends Equatable {
  @HiveField(0)
  final String entryId;
  @HiveField(1)
  final String participantId;
  @HiveField(2)
  final String sessionId;
  @HiveField(3)
  final String method;
  @HiveField(4)
  final int taskOrder;
  @HiveField(5)
  final double susScore;
  @HiveField(6)
  final double umuxScore;
  @HiveField(7)
  final int satisfactionScore;
  @HiveField(8)
  final int trustScore;
  @HiveField(9)
  final ResearchPreference preference;
  @HiveField(10)
  final String notes;
  @HiveField(11)
  final DateTime createdAt;

  const ResearchEntry({
    required this.entryId,
    required this.participantId,
    required this.sessionId,
    required this.method,
    required this.taskOrder,
    required this.susScore,
    required this.umuxScore,
    required this.satisfactionScore,
    required this.trustScore,
    required this.preference,
    required this.notes,
    required this.createdAt,
  });

  ResearchEntry copyWith({
    String? participantId,
    String? sessionId,
    String? method,
    int? taskOrder,
    double? susScore,
    double? umuxScore,
    int? satisfactionScore,
    int? trustScore,
    ResearchPreference? preference,
    String? notes,
  }) {
    return ResearchEntry(
      entryId: entryId,
      participantId: participantId ?? this.participantId,
      sessionId: sessionId ?? this.sessionId,
      method: method ?? this.method,
      taskOrder: taskOrder ?? this.taskOrder,
      susScore: susScore ?? this.susScore,
      umuxScore: umuxScore ?? this.umuxScore,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
      trustScore: trustScore ?? this.trustScore,
      preference: preference ?? this.preference,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  List<String> toCsvRow() {
    return [
      entryId,
      participantId,
      sessionId,
      method,
      taskOrder.toString(),
      susScore.toStringAsFixed(1),
      umuxScore.toStringAsFixed(1),
      satisfactionScore.toString(),
      trustScore.toString(),
      preference.name,
      notes,
      createdAt.toIso8601String(),
    ];
  }

  @override
  List<Object?> get props => [
    entryId,
    participantId,
    sessionId,
    method,
    taskOrder,
    susScore,
    umuxScore,
    satisfactionScore,
    trustScore,
    preference,
    notes,
    createdAt,
  ];
}
