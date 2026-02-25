import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/alpha_test_logger.dart';
import '../../../research_log/domain/repositories/login_session_repository.dart';
import '../../data/models/performance_summary.dart';
import '../../domain/repositories/performance_repository.dart';
import 'performance_event.dart';
import 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceRepository repository;
  final LoginSessionRepository loginSessionRepository;
  final AlphaTestLogger _logger = AlphaTestLogger.instance;

  PerformanceSummary? _activeSession;
  final Map<PerformanceStep, DateTime> _stepStarts = {};

  PerformanceBloc({
    required this.repository,
    required this.loginSessionRepository,
  }) : super(const PerformanceInitial()) {
    on<StartSession>(_onStartSession);
    on<AddClick>(_onAddClick);
    on<AddScroll>(_onAddScroll);
    on<AddVoiceCommand>(_onAddVoiceCommand);
    on<AddCorrection>(_onAddCorrection);
    on<AddError>(_onAddError);
    on<StartStep>(_onStartStep);
    on<EndStep>(_onEndStep);
    on<CompleteTask>(_onCompleteTask);
    on<EndSession>(_onEndSession);
    on<UpdateSearchedLocation>(_onUpdateSearchedLocation);
    on<LoadAllSessions>(_onLoadAllSessions);
    on<ExportSessionsToCsv>(_onExportSessionsToCsv);
    on<ClearSessions>(_onClearSessions);
  }

  void _onStartSession(StartSession event, Emitter<PerformanceState> emit) {
    if (_activeSession != null) {
      if (event.searchedLocation != null &&
          event.searchedLocation!.isNotEmpty) {
        _activeSession = _activeSession!.copyWith(
          searchedLocation: event.searchedLocation,
        );
        _logger.updateSearchedLocation(event.searchedLocation!);
      }
      emit(PerformanceSessionActive(_activeSession!));
      return;
    }

    final now = DateTime.now();
    final testerSessionId = loginSessionRepository.getActiveSessionId();
    final session = PerformanceSummary(
      sessionId: now.microsecondsSinceEpoch.toString(),
      testerSessionId: testerSessionId,
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
      searchDurationSeconds: 0,
      selectionDurationSeconds: 0,
      paymentDurationSeconds: 0,
      confirmationDurationSeconds: 0,
      errorTypes: const [],
    );

    _activeSession = session;
    _logger.startSession(
      method: event.method,
      searchedLocation: event.searchedLocation,
      scenarioId: event.scenarioId,
      testerSessionId: testerSessionId,
    );
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
    _logger.logInteraction('tap');
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onAddScroll(AddScroll event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      totalClicks: _activeSession!.totalClicks + 1,
    );
    _logger.logInteraction('scroll');
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
    _logger.logInteraction('voice_command');
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onAddCorrection(AddCorrection event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    final updatedErrorTypes = List<String>.from(_activeSession!.errorTypes);
    updatedErrorTypes.add(
      'correction_${_activeSession!.interactionMethod.name}',
    );

    _activeSession = _activeSession!.copyWith(errorTypes: updatedErrorTypes);
    _logger.logError(type: 'correction', message: event.toString());
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onAddError(AddError event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    final updatedErrorTypes = List<String>.from(_activeSession!.errorTypes);
    updatedErrorTypes.add(event.errorType ?? 'unknown');

    _activeSession = _activeSession!.copyWith(
      errorsCount: _activeSession!.errorsCount + 1,
      errorTypes: updatedErrorTypes,
    );
    _logger.logError(type: event.errorType ?? 'unknown');
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onStartStep(StartStep event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _stepStarts[event.step] = DateTime.now();
    _logger.logStepStart(event.step.name);
    emit(PerformanceSessionActive(_activeSession!));
  }

  void _onEndStep(EndStep event, Emitter<PerformanceState> emit) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    final start = _stepStarts[event.step];
    if (start == null) {
      emit(const PerformanceError('Step was not started'));
      return;
    }

    final duration = DateTime.now().difference(start).inSeconds;
    _stepStarts.remove(event.step);

    switch (event.step) {
      case PerformanceStep.search:
        _activeSession = _activeSession!.copyWith(
          searchDurationSeconds:
              _activeSession!.searchDurationSeconds + duration,
        );
        break;
      case PerformanceStep.selection:
        _activeSession = _activeSession!.copyWith(
          selectionDurationSeconds:
              _activeSession!.selectionDurationSeconds + duration,
        );
        break;
      case PerformanceStep.payment:
        _activeSession = _activeSession!.copyWith(
          paymentDurationSeconds:
              _activeSession!.paymentDurationSeconds + duration,
        );
        break;
      case PerformanceStep.confirmation:
        _activeSession = _activeSession!.copyWith(
          confirmationDurationSeconds:
              _activeSession!.confirmationDurationSeconds + duration,
        );
        break;
    }

    _logger.logStepEnd(event.step.name, duration);
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
      await _logger.endSession(summary: finalized);
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

  Future<void> _onClearSessions(
    ClearSessions event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(const PerformanceLoading());

    try {
      await repository.clearSessions();
      _activeSession = null;
      _stepStarts.clear();
      emit(const PerformanceCleared());

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

  void _onUpdateSearchedLocation(
    UpdateSearchedLocation event,
    Emitter<PerformanceState> emit,
  ) {
    if (_activeSession == null) {
      emit(const PerformanceError('No active session to update'));
      return;
    }

    _activeSession = _activeSession!.copyWith(
      searchedLocation: event.searchedLocation,
    );
    _logger.updateSearchedLocation(event.searchedLocation);
    emit(PerformanceSessionActive(_activeSession!));
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
        averageUserInputSeconds: 0,
        averageCorrectionCount: 0,
        averageInteractionEffort: 0,
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
    final totalUserInputSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.userInputTimeSeconds,
    );
    final totalCorrectionCount = sessions.fold<int>(
      0,
      (sum, session) => sum + session.correctionCount,
    );
    final totalInteractionEffort = sessions.fold<int>(
      0,
      (sum, session) => sum + session.interactionEffortCount,
    );

    return PerformanceAnalytics(
      totalSessions: sessions.length,
      averageDurationSeconds: totalDuration / sessions.length,
      totalErrors: totalErrors,
      completionRate: completedSessions / sessions.length,
      errorRate: errorSessions / sessions.length,
      guiSessions: guiSessions,
      vuiSessions: vuiSessions,
      bookingSuccessRate: successfulBookings / sessions.length,
      averageUserInputSeconds: totalUserInputSeconds / sessions.length,
      averageCorrectionCount: totalCorrectionCount / sessions.length,
      averageInteractionEffort: totalInteractionEffort / sessions.length,
    );
  }
}
