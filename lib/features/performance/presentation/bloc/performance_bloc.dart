import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/performance_summary.dart';
import '../../domain/repositories/performance_repository.dart';
import 'performance_event.dart';
import 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceRepository repository;

  PerformanceSummary? _activeSession;

  PerformanceBloc({required this.repository})
    : super(const PerformanceInitial()) {
    on<StartSession>(_onStartSession);
    on<AddClick>(_onAddClick);
    on<AddVoiceCommand>(_onAddVoiceCommand);
    on<AddError>(_onAddError);
    on<CompleteTask>(_onCompleteTask);
    on<EndSession>(_onEndSession);
    on<LoadAllSessions>(_onLoadAllSessions);
    on<ExportSessionsToCsv>(_onExportSessionsToCsv);
  }

  void _onStartSession(StartSession event, Emitter<PerformanceState> emit) {
    final now = DateTime.now();
    final session = PerformanceSummary(
      sessionId: now.microsecondsSinceEpoch.toString(),
      startTime: now,
      endTime: now,
      durationInSeconds: 0,
      interactionMethod: event.method,
      totalClicks: 0,
      totalVoiceCommands: 0,
      errorsCount: 0,
      taskCompleted: false,
      searchedLocation: event.searchedLocation ?? '',
      selectedHotelName: null,
      bookingSuccess: false,
      createdAt: now,
    );

    _activeSession = session;
    emit(PerformanceSessionActive(session));
  }

  void _onAddClick(AddClick event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      totalClicks: _activeSession!.totalClicks + 1,
    );
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onAddVoiceCommand(
    AddVoiceCommand event,
    Emitter<PerformanceState> emit,
  ) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      totalVoiceCommands: _activeSession!.totalVoiceCommands + 1,
    );
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onAddError(AddError event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      errorsCount: _activeSession!.errorsCount + 1,
    );
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onCompleteTask(CompleteTask event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to complete'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      taskCompleted: true,
      bookingSuccess: event.bookingSuccess,
      selectedHotelName: event.selectedHotelName,
    );
    emit(PerformanceSessionActive(_activeSession!));
  }

  Future<void> _onEndSession(
    EndSession event,
    Emitter<PerformanceState> emit,
  ) async {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to end'));
      return;
    }

    final now = DateTime.now();
    final duration = now.difference(_activeSession!.startTime).inSeconds;
    final finalized = _activeSession!.copyWith(
      endTime: now,
      durationInSeconds: duration < 0 ? 0 : duration,
    );

    emit(const PerformanceLoading());

    try {
      await repository.saveSession(finalized);
      _activeSession = null;
      emit(PerformanceSessionSaved(finalized));

      final sessions = await repository.getAllSessions();
      emit(
        PerformanceLoadedSessions(
          sessions: sessions,
          analytics: _computeAnalytics(sessions),
        ),
      );
    } catch (e) {
      emit(PerformanceError(e.toString()));
    }
  }

  Future<void> _onLoadAllSessions(
    LoadAllSessions event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(const PerformanceLoading());

    try {
      final sessions = await repository.getAllSessions();
      emit(
        PerformanceLoadedSessions(
          sessions: sessions,
          analytics: _computeAnalytics(sessions),
        ),
      );
    } catch (e) {
      emit(PerformanceError(e.toString()));
    }
  }

  Future<void> _onExportSessionsToCsv(
    ExportSessionsToCsv event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(const PerformanceLoading());

    try {
      final filePath = await repository.exportSessionsToCsv();
      emit(PerformanceExported(filePath));

      final sessions = await repository.getAllSessions();
      emit(
        PerformanceLoadedSessions(
          sessions: sessions,
          analytics: _computeAnalytics(sessions),
        ),
      );
    } catch (e) {
      emit(PerformanceError(e.toString()));
    }
  }

  PerformanceAnalytics _computeAnalytics(List<PerformanceSummary> sessions) {
    if (sessions.isEmpty) {
      return const PerformanceAnalytics(
        totalSessions: 0,
        averageDurationSeconds: 0,
        totalErrors: 0,
        completionRate: 0,
        errorRate: 0,
        guiSessions: 0,
        vuiSessions: 0,
        bookingSuccessRate: 0,
      );
    }

    final totalDuration = sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationInSeconds,
    );
    final totalErrors = sessions.fold<int>(
      0,
      (sum, session) => sum + session.errorsCount,
    );
    final completedSessions = sessions.where((s) => s.taskCompleted).length;
    final errorSessions = sessions.where((s) => s.errorsCount > 0).length;
    final guiSessions = sessions
        .where((s) => s.interactionMethod == InteractionMethod.gui)
        .length;
    final vuiSessions = sessions
        .where((s) => s.interactionMethod == InteractionMethod.vui)
        .length;
    final successfulBookings = sessions.where((s) => s.bookingSuccess).length;

    return PerformanceAnalytics(
      totalSessions: sessions.length,
      averageDurationSeconds: totalDuration / sessions.length,
      totalErrors: totalErrors,
      completionRate: completedSessions / sessions.length,
      errorRate: errorSessions / sessions.length,
      guiSessions: guiSessions,
      vuiSessions: vuiSessions,
      bookingSuccessRate: successfulBookings / sessions.length,
    );
  }
}
