import '../../../../core/services/booking_alpha_research_logger.dart';
import '../../../../core/services/booking_network_metrics_tracker.dart';
import '../../../../core/services/performance_tracking_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../performance/domain/entities/performance_scenario.dart';
import '../entities/booking_entity.dart';
import '../entities/guest_form_entity.dart';
import 'confirm_booking.dart';
import 'get_booking_summary.dart';
import 'submit_guest_info.dart';

class BookingAlphaLoopConfig {
  const BookingAlphaLoopConfig({
    this.loopCount = recommendedLoopCount,
    this.hotelId = '1',
    this.roomId = 'room-001',
    this.guests = 2,
    this.rooms = 1,
    this.paymentMethod = 'credit_card',
    this.pauseBetweenLoops = recommendedPauseBetweenLoops,
  });

  static const int recommendedLoopCount = 100;
  static const Duration recommendedPauseBetweenLoops = Duration(
    milliseconds: 100,
  );

  final int loopCount;
  final String hotelId;
  final String roomId;
  final int guests;
  final int rooms;
  final String paymentMethod;
  final Duration pauseBetweenLoops;
}

class BookingAlphaLoopResult {
  const BookingAlphaLoopResult({
    required this.runId,
    required this.totalSessions,
    required this.successSessions,
    required this.failedSessions,
    required this.rawLogPath,
    required this.summaryLogPath,
    required this.totalDuration,
  });

  final String runId;
  final int totalSessions;
  final int successSessions;
  final int failedSessions;
  final String rawLogPath;
  final String summaryLogPath;
  final Duration totalDuration;
}

class RunBookingAlphaLoop {
  RunBookingAlphaLoop({
    required this.getBookingSummary,
    required this.submitGuestInfo,
    required this.confirmBooking,
    BookingAlphaResearchLogger? logger,
    BookingNetworkMetricsTracker? networkMetricsTracker,
    PerformanceTrackingService? performanceTrackingService,
  }) : _logger = logger ?? BookingAlphaResearchLogger(),
       _networkMetricsTracker =
           networkMetricsTracker ?? BookingNetworkMetricsTracker.instance,
       _performanceTrackingService =
           performanceTrackingService ?? PerformanceTrackingService.instance;

  final GetBookingSummary getBookingSummary;
  final SubmitGuestInfo submitGuestInfo;
  final ConfirmBooking confirmBooking;

  final BookingAlphaResearchLogger _logger;
  final BookingNetworkMetricsTracker _networkMetricsTracker;
  final PerformanceTrackingService _performanceTrackingService;

  static const int _totalFlowSteps = 3;

  Future<BookingAlphaLoopResult> call({
    BookingAlphaLoopConfig config = const BookingAlphaLoopConfig(),
  }) async {
    final runId = _buildRunId();
    final runStartedAt = DateTime.now();
    final sessions = <BookingAlphaSessionLog>[];

    for (var index = 0; index < config.loopCount; index++) {
      final loopIndex = index + 1;
      final session = await _runSingleLoop(
        runId: runId,
        loopIndex: loopIndex,
        config: config,
      );
      sessions.add(session);

      if (loopIndex < config.loopCount &&
          config.pauseBetweenLoops.inMilliseconds > 0) {
        await Future<void>.delayed(config.pauseBetweenLoops);
      }
    }

    final runEndedAt = DateTime.now();
    final artifacts = await _logger.writeRunLogs(
      runId: runId,
      runStartedAt: runStartedAt,
      runEndedAt: runEndedAt,
      plannedLoops: config.loopCount,
      sessions: sessions,
    );

    final successSessions = sessions
        .where((BookingAlphaSessionLog session) => session.status == 'success')
        .length;

    return BookingAlphaLoopResult(
      runId: runId,
      totalSessions: sessions.length,
      successSessions: successSessions,
      failedSessions: sessions.length - successSessions,
      rawLogPath: artifacts.rawLogPath,
      summaryLogPath: artifacts.summaryLogPath,
      totalDuration: runEndedAt.difference(runStartedAt),
    );
  }

  Future<BookingAlphaSessionLog> _runSingleLoop({
    required String runId,
    required int loopIndex,
    required BookingAlphaLoopConfig config,
  }) async {
    final sessionId = '${runId}_s$loopIndex';
    final sessionStartedAt = DateTime.now();
    final checkInDate = _buildCheckInDate(loopIndex);
    final checkOutDate = checkInDate.add(const Duration(days: 1));

    _networkMetricsTracker.startSession(sessionId);

    final stepDurationsMs = <String, int>{};
    var sessionNetworkRequests = <Map<String, dynamic>>[];
    var networkTotalDurationMs = 0;
    var successfulSteps = 0;
    var status = 'success';
    String? error;
    var scenarioStarted = false;

    BookingEntity? booking;

    try {
      await _performanceTrackingService.startScenario(
        method: BookingMethodType.gui,
        scenarioId: sessionId,
        scenarioName: 'GUI alpha booking loop',
        details: <String, dynamic>{
          'source': 'alpha_automation',
          'run_id': runId,
          'loop_index': loopIndex,
          'hotel_id': config.hotelId,
          'room_id': config.roomId,
        },
      );
      scenarioStarted = true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'BookingAlphaLoop',
        'Gagal memulai performance scenario untuk $sessionId',
        error: exception,
        stackTrace: stackTrace,
      );
    }

    try {
      final summaryWatch = Stopwatch()..start();
      booking = await getBookingSummary(
        hotelId: config.hotelId,
        roomId: config.roomId,
        checkIn: checkInDate.toIso8601String(),
        checkOut: checkOutDate.toIso8601String(),
        guests: config.guests,
        rooms: config.rooms,
      );
      summaryWatch.stop();
      stepDurationsMs['get_booking_summary'] = summaryWatch.elapsedMilliseconds;
      successfulSteps += 1;

      final guestWatch = Stopwatch()..start();
      booking = await submitGuestInfo(
        bookingId: booking.bookingId,
        guestInfo: _buildGuestForm(loopIndex),
      );
      guestWatch.stop();
      stepDurationsMs['submit_guest_info'] = guestWatch.elapsedMilliseconds;
      successfulSteps += 1;

      final confirmWatch = Stopwatch()..start();
      booking = await confirmBooking(
        bookingId: booking.bookingId,
        paymentMethod: config.paymentMethod,
      );
      confirmWatch.stop();
      stepDurationsMs['confirm_booking'] = confirmWatch.elapsedMilliseconds;
      successfulSteps += 1;
    } catch (exception, stackTrace) {
      status = 'failed';
      error = exception.toString();
      AppLogger.error(
        'BookingAlphaLoop',
        'Loop gagal pada sesi $sessionId',
        error: exception,
        stackTrace: stackTrace,
      );
    } finally {
      final networkRequests = _networkMetricsTracker
          .consumeSessionMetricsAsJson(sessionId);

      networkTotalDurationMs = networkRequests.fold<int>(
        0,
        (int sum, Map<String, dynamic> request) =>
            sum + ((request['duration_ms'] as num?)?.toInt() ?? 0),
      );
      sessionNetworkRequests = networkRequests;

      if (scenarioStarted) {
        try {
          await _performanceTrackingService.finishScenario(
            method: BookingMethodType.gui,
            scenarioId: sessionId,
            status: status == 'success' ? 'completed' : 'failed',
            details: <String, dynamic>{
              'source': 'alpha_automation',
              'run_id': runId,
              'loop_index': loopIndex,
              'steps_successful': successfulSteps,
              'steps_total': _totalFlowSteps,
              'step_durations_ms': stepDurationsMs,
              'network_request_count': sessionNetworkRequests.length,
              'network_total_duration_ms': networkTotalDurationMs,
              'network_requests': sessionNetworkRequests,
              if (booking != null) 'booking_id': booking.bookingId,
              if (error != null) 'error': error,
            },
          );
        } catch (exception, stackTrace) {
          AppLogger.error(
            'BookingAlphaLoop',
            'Gagal menyelesaikan performance scenario untuk $sessionId',
            error: exception,
            stackTrace: stackTrace,
          );
        }
      }
    }

    final sessionEndedAt = DateTime.now();
    final scenario = await _performanceTrackingService.getScenarioById(
      sessionId,
    );
    final performancePayload = _buildPerformancePayload(scenario);

    _networkMetricsTracker.endSession(sessionId);

    return BookingAlphaSessionLog(
      sessionId: sessionId,
      runId: runId,
      loopIndex: loopIndex,
      startedAt: sessionStartedAt,
      endedAt: sessionEndedAt,
      durationMs: sessionEndedAt.difference(sessionStartedAt).inMilliseconds,
      status: status,
      successfulSteps: successfulSteps,
      totalSteps: _totalFlowSteps,
      error: error,
      networkRequestCount: sessionNetworkRequests.length,
      networkTotalDurationMs: networkTotalDurationMs,
      networkRequests: sessionNetworkRequests,
      performance: performancePayload,
    );
  }

  GuestFormEntity _buildGuestForm(int loopIndex) {
    final suffix = loopIndex.toString().padLeft(2, '0');
    return GuestFormEntity(
      title: 'Mr',
      firstName: 'Alpha$suffix',
      lastName: 'Tester',
      email: 'alpha$suffix@qora.test',
      phone: '+628110000$suffix',
      specialRequests: 'Automated alpha booking session #$loopIndex',
    );
  }

  DateTime _buildCheckInDate(int loopIndex) {
    final now = DateTime.now();
    final offset = loopIndex;
    return DateTime(now.year, now.month, now.day + offset);
  }

  String _buildRunId() {
    final now = DateTime.now().toUtc();
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'gui_alpha_${date}_$time';
  }

  Map<String, dynamic> _buildPerformancePayload(PerformanceScenario? scenario) {
    if (scenario == null) {
      return const <String, dynamic>{};
    }

    final details = scenario.details;
    return <String, dynamic>{
      'latency_ms': scenario.latencyMs,
      'avg_cpu_percent': scenario.avgCpuPercent,
      'peak_memory_mb': scenario.peakMemoryMb,
      'ui_frame_time_ms_avg': details['ui_frame_time_ms_avg'],
      'ui_frame_time_ms_max': details['ui_frame_time_ms_max'],
      'raster_frame_time_ms_avg': details['raster_frame_time_ms_avg'],
      'raster_frame_time_ms_max': details['raster_frame_time_ms_max'],
    };
  }
}
