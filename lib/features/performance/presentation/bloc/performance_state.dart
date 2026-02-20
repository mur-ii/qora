import 'package:equatable/equatable.dart';

import '../../data/models/performance_summary.dart';

class PerformanceAnalytics extends Equatable {
  final int totalSessions;
  final double averageDurationSeconds;
  final int totalErrors;
  final double completionRate;
  final double errorRate;
  final int guiSessions;
  final int vuiSessions;
  final double bookingSuccessRate;
  final double averageUserInputSeconds;
  final double averageCorrectionCount;
  final double averageInteractionEffort;

  const PerformanceAnalytics({
    required this.totalSessions,
    required this.averageDurationSeconds,
    required this.totalErrors,
    required this.completionRate,
    required this.errorRate,
    required this.guiSessions,
    required this.vuiSessions,
    required this.bookingSuccessRate,
    required this.averageUserInputSeconds,
    required this.averageCorrectionCount,
    required this.averageInteractionEffort,
  });

  @override
  List<Object?> get props => [
    totalSessions,
    averageDurationSeconds,
    totalErrors,
    completionRate,
    errorRate,
    guiSessions,
    vuiSessions,
    bookingSuccessRate,
    averageUserInputSeconds,
    averageCorrectionCount,
    averageInteractionEffort,
  ];
}

abstract class PerformanceState extends Equatable {
  const PerformanceState();

  @override
  List<Object?> get props => [];
}

class PerformanceInitial extends PerformanceState {
  const PerformanceInitial();
}

class PerformanceLoading extends PerformanceState {
  const PerformanceLoading();
}

class PerformanceSessionActive extends PerformanceState {
  final PerformanceSummary session;

  const PerformanceSessionActive(this.session);

  @override
  List<Object?> get props => [session];
}

class PerformanceSessionSaved extends PerformanceState {
  final PerformanceSummary session;

  const PerformanceSessionSaved(this.session);

  @override
  List<Object?> get props => [session];
}

class PerformanceLoadedSessions extends PerformanceState {
  final List<PerformanceSummary> sessions;
  final PerformanceAnalytics analytics;

  const PerformanceLoadedSessions({
    required this.sessions,
    required this.analytics,
  });

  @override
  List<Object?> get props => [sessions, analytics];
}

class PerformanceExported extends PerformanceState {
  final String filePath;

  const PerformanceExported(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class PerformanceCleared extends PerformanceState {
  const PerformanceCleared();
}

class PerformanceError extends PerformanceState {
  final String message;

  const PerformanceError(this.message);

  @override
  List<Object?> get props => [message];
}
