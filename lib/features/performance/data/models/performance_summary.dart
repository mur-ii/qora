import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'performance_summary.g.dart';

const int performanceSummaryTypeId = 30;
const int interactionMethodTypeId = 31;

@HiveType(typeId: interactionMethodTypeId)
enum InteractionMethod { gui, vui }

@HiveType(typeId: performanceSummaryTypeId)
class PerformanceSummary extends Equatable {
  @HiveField(0)
  final String sessionId;
  @HiveField(1)
  final DateTime startTime;
  @HiveField(2)
  final DateTime endTime;
  @HiveField(3)
  final int durationInSeconds;
  @HiveField(4)
  final InteractionMethod interactionMethod;
  @HiveField(5)
  final int totalClicks;
  @HiveField(6)
  final int totalVoiceCommands;
  @HiveField(7)
  final int errorsCount;
  @HiveField(8)
  final bool taskCompleted;
  @HiveField(9)
  final String searchedLocation;
  @HiveField(10)
  final String? selectedHotelName;
  @HiveField(11)
  final bool bookingSuccess;
  @HiveField(12)
  final DateTime createdAt;

  const PerformanceSummary({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationInSeconds,
    required this.interactionMethod,
    required this.totalClicks,
    required this.totalVoiceCommands,
    required this.errorsCount,
    required this.taskCompleted,
    required this.searchedLocation,
    required this.selectedHotelName,
    required this.bookingSuccess,
    required this.createdAt,
  });

  PerformanceSummary copyWith({
    DateTime? endTime,
    int? durationInSeconds,
    int? totalClicks,
    int? totalVoiceCommands,
    int? errorsCount,
    bool? taskCompleted,
    String? searchedLocation,
    String? selectedHotelName,
    bool? bookingSuccess,
  }) {
    return PerformanceSummary(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      interactionMethod: interactionMethod,
      totalClicks: totalClicks ?? this.totalClicks,
      totalVoiceCommands: totalVoiceCommands ?? this.totalVoiceCommands,
      errorsCount: errorsCount ?? this.errorsCount,
      taskCompleted: taskCompleted ?? this.taskCompleted,
      searchedLocation: searchedLocation ?? this.searchedLocation,
      selectedHotelName: selectedHotelName ?? this.selectedHotelName,
      bookingSuccess: bookingSuccess ?? this.bookingSuccess,
      createdAt: createdAt,
    );
  }

  List<String> toCsvRow() {
    return [
      sessionId,
      startTime.toIso8601String(),
      endTime.toIso8601String(),
      durationInSeconds.toString(),
      interactionMethod.name.toUpperCase(),
      totalClicks.toString(),
      totalVoiceCommands.toString(),
      errorsCount.toString(),
      taskCompleted.toString(),
      searchedLocation,
      selectedHotelName ?? '',
      bookingSuccess.toString(),
      createdAt.toIso8601String(),
    ];
  }

  @override
  List<Object?> get props => [
    sessionId,
    startTime,
    endTime,
    durationInSeconds,
    interactionMethod,
    totalClicks,
    totalVoiceCommands,
    errorsCount,
    taskCompleted,
    searchedLocation,
    selectedHotelName,
    bookingSuccess,
    createdAt,
  ];
}
