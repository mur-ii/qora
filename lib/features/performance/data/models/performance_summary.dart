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
  @HiveField(13)
  final int searchDurationSeconds;
  @HiveField(14)
  final int selectionDurationSeconds;
  @HiveField(15)
  final int paymentDurationSeconds;
  @HiveField(16)
  final int confirmationDurationSeconds;
  @HiveField(17)
  final List<String> errorTypes;

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
    required this.searchDurationSeconds,
    required this.selectionDurationSeconds,
    required this.paymentDurationSeconds,
    required this.confirmationDurationSeconds,
    required this.errorTypes,
  });

  int get userInputTimeSeconds => searchDurationSeconds;

  int get correctionCount =>
      errorTypes.where((entry) => entry.startsWith('correction')).length;

  int get interactionEffortCount => interactionMethod == InteractionMethod.gui
      ? totalClicks
      : totalVoiceCommands;

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
    int? searchDurationSeconds,
    int? selectionDurationSeconds,
    int? paymentDurationSeconds,
    int? confirmationDurationSeconds,
    List<String>? errorTypes,
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
      searchDurationSeconds:
          searchDurationSeconds ?? this.searchDurationSeconds,
      selectionDurationSeconds:
          selectionDurationSeconds ?? this.selectionDurationSeconds,
      paymentDurationSeconds:
          paymentDurationSeconds ?? this.paymentDurationSeconds,
      confirmationDurationSeconds:
          confirmationDurationSeconds ?? this.confirmationDurationSeconds,
      errorTypes: errorTypes ?? this.errorTypes,
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
      errorTypes.join('|'),
      taskCompleted.toString(),
      searchedLocation,
      selectedHotelName ?? '',
      bookingSuccess.toString(),
      createdAt.toIso8601String(),
      searchDurationSeconds.toString(),
      selectionDurationSeconds.toString(),
      paymentDurationSeconds.toString(),
      confirmationDurationSeconds.toString(),
      userInputTimeSeconds.toString(),
      correctionCount.toString(),
      interactionEffortCount.toString(),
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
    errorTypes,
    taskCompleted,
    searchedLocation,
    selectedHotelName,
    bookingSuccess,
    createdAt,
    searchDurationSeconds,
    selectionDurationSeconds,
    paymentDurationSeconds,
    confirmationDurationSeconds,
  ];
}
