import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/performance/data/datasources/performance_local_datasource.dart';
import '../../features/performance/data/repositories/performance_repository_impl.dart';
import '../../features/performance/domain/entities/performance_scenario.dart';
import '../../features/performance/domain/repositories/performance_repository.dart';
import 'performance_runtime_metrics_service.dart';

class PerformanceTrackingService {
  PerformanceTrackingService._internal()
    : _repository = PerformanceRepositoryImpl(
        localDataSource: PerformanceLocalDataSource(),
      );

  static final PerformanceTrackingService instance =
      PerformanceTrackingService._internal();

  final PerformanceRepository _repository;
  final PerformanceRuntimeMetricsService _runtimeMetrics =
      PerformanceRuntimeMetricsService.instance;
  final Map<BookingMethodType, _ActiveRun> _activeRuns =
      <BookingMethodType, _ActiveRun>{};
  final Set<String> _voiceOriginBookingIds = <String>{};
  Timer? _samplingTimer;
  final DateFormat _dateTimeFormatter = DateFormat('dd-MM-yyyy, HH:mm:ss');
  late final TimingsCallback _frameTimingsCallback = _onFrameTimings;
  bool _isFrameTimingsAttached = false;

  static const Duration _samplingInterval = Duration(seconds: 2);

  Future<String> startScenario({
    required BookingMethodType method,
    required String scenarioName,
    String? scenarioId,
    Map<String, dynamic>? details,
  }) async {
    final active = _activeRuns[method];
    if (active != null) {
      return active.scenarioId;
    }

    final now = DateTime.now();
    final resolvedScenarioId = scenarioId ?? _buildScenarioId(method);

    final scenario = PerformanceScenario(
      scenarioId: resolvedScenarioId,
      method: method,
      scenarioName: scenarioName,
      startedAt: now,
      status: 'running',
      details: details ?? const <String, dynamic>{},
    );

    await _repository.upsertScenario(scenario);
    _activeRuns[method] = _ActiveRun(
      scenarioId: resolvedScenarioId,
      startedAt: now,
      scenarioName: scenarioName,
    );

    _ensureSamplingTimer();
    _ensureFrameTimingsCallback();
    await _collectSystemSampleFor(method);

    return resolvedScenarioId;
  }

  Future<void> finishScenario({
    required BookingMethodType method,
    String? scenarioId,
    int? latencyMs,
    double? avgCpuPercent,
    double? peakMemoryMb,
    double? sessionCostUsd,
    int? totalTokens,
    int? totalTurns,
    String status = 'completed',
    Map<String, dynamic>? details,
  }) async {
    final active = _activeRuns[method];
    final targetScenarioId = scenarioId ?? active?.scenarioId;

    if (targetScenarioId == null || targetScenarioId.isEmpty) {
      return;
    }

    final existing = await _repository.getScenarioById(targetScenarioId);
    if (existing == null) {
      _activeRuns.remove(method);
      return;
    }

    final now = DateTime.now();
    final startedAt = active?.startedAt ?? existing.startedAt;
    final resolvedLatencyMs =
        latencyMs ?? now.difference(startedAt).inMilliseconds;
    await _collectSystemSampleFor(method);

    final avgCpu = avgCpuPercent ?? active?.averageCpuPercent;
    final peakCpu = active?.peakCpuPercent;
    final avgMemory = active?.averageMemoryMb;
    final peakMemory = peakMemoryMb ?? active?.peakMemoryMb;
    final uiFrameTime = active?.uiFrameTimeStats;
    final rasterFrameTime = active?.rasterFrameTimeStats;

    final updatedScenario = existing.copyWith(
      endedAt: now,
      latencyMs: resolvedLatencyMs,
      avgCpuPercent: avgCpu,
      peakMemoryMb: peakMemory,
      sessionCostUsd: sessionCostUsd,
      totalTokens: totalTokens,
      totalTurns: totalTurns,
      status: status,
      details: _mergeDetails(existing.details, <String, dynamic>{
        if (details != null) ...details,
        'ui_frame_time_ms_avg': uiFrameTime?.avg,
        'ui_frame_time_ms_min': uiFrameTime?.min,
        'ui_frame_time_ms_max': uiFrameTime?.max,
        'raster_frame_time_ms_avg': rasterFrameTime?.avg,
        'raster_frame_time_ms_min': rasterFrameTime?.min,
        'raster_frame_time_ms_max': rasterFrameTime?.max,
        'cpu_peak_percent': peakCpu,
        'memory_avg_mb': avgMemory,
        'runtime_metrics_source': 'android_method_channel',
      }),
    );

    await _repository.upsertScenario(updatedScenario);
    _activeRuns.remove(method);
    _stopSamplingIfIdle();
  }

  Future<List<PerformanceScenario>> getAllScenarios() {
    return _repository.getAllScenarios();
  }

  void markVoiceOriginBooking(String bookingId) {
    final normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) {
      return;
    }
    _voiceOriginBookingIds.add(normalizedBookingId);
  }

  bool isVoiceOriginBooking(String bookingId) {
    final normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) {
      return false;
    }
    return _voiceOriginBookingIds.contains(normalizedBookingId);
  }

  void clearVoiceOriginBooking(String bookingId) {
    final normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) {
      return;
    }
    _voiceOriginBookingIds.remove(normalizedBookingId);
  }

  Future<void> deleteScenario(String scenarioId) async {
    await _repository.deleteScenario(scenarioId);

    final activeEntry = _activeRuns.entries
        .where((entry) => entry.value.scenarioId == scenarioId)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final method in activeEntry) {
      _activeRuns.remove(method);
    }

    _stopSamplingIfIdle();
  }

  Future<String> exportScenarioToJson(String scenarioId) async {
    final scenario = await _repository.getScenarioById(scenarioId);
    if (scenario == null) {
      throw Exception('Scenario tidak ditemukan');
    }

    final voiceSessionData = _extractVoiceSessionData(scenario);
    final performanceData = _buildPerformanceData(scenario);
    final aiAnalysis = _buildAiAnalysis(scenario, voiceSessionData);
    final sessionIdFromDetails = scenario.details['session_id']?.toString();

    final exportDirectory = await _resolveExportDirectory();
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final safeScenarioId = _sanitizeFileName(scenario.scenarioId);
    final fileName =
        'qora_performance_${scenario.method.value}_${safeScenarioId}_$timestamp.json';
    final outputFile = File(p.join(exportDirectory.path, fileName));

    final payload = <String, dynamic>{
      'meta': <String, dynamic>{
        'app': 'Qora',
        'exported_at': _formatDateTime(now),
        'format_version': 3,
      },
      'skenario': <String, dynamic>{
        'id': scenario.scenarioId,
        'session_id': sessionIdFromDetails ?? scenario.scenarioId,
        'name': scenario.scenarioName,
        'method': scenario.method.value,
        'status': scenario.status,
        'started_at': _formatDateTime(scenario.startedAt),
        'ended_at': _formatNullableDateTime(scenario.endedAt),
        'latency_ms': scenario.latencyMs,
      },
      'performance': performanceData,
      'ai_analysis': aiAnalysis,
      'voice_session': voiceSessionData,
    };

    final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
    await outputFile.writeAsString(prettyJson, flush: true);

    return outputFile.path;
  }

  String _buildScenarioId(BookingMethodType method) {
    final now = DateTime.now().toUtc();
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return '${method.value}_${date}_$time';
  }

  Map<String, dynamic> _mergeDetails(
    Map<String, dynamic> source,
    Map<String, dynamic>? patch,
  ) {
    if (patch == null || patch.isEmpty) {
      return source;
    }

    final merged = <String, dynamic>{...source};
    merged.addAll(patch);
    return merged;
  }

  Future<Directory> _resolveExportDirectory() async {
    if (Platform.isAndroid) {
      final externalDirectory = await getExternalStorageDirectory();
      if (externalDirectory != null) {
        final sharedDownload = await _trySharedDownloadDir(externalDirectory);
        if (sharedDownload != null) {
          return sharedDownload;
        }

        final appDownload = Directory(
          p.join(externalDirectory.path, 'downloads', 'qora_performance'),
        );
        if (!await appDownload.exists()) {
          await appDownload.create(recursive: true);
        }
        return appDownload;
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(docs.path, 'qora_performance'));
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  Future<Directory?> _trySharedDownloadDir(Directory externalDirectory) async {
    try {
      final normalized = externalDirectory.path.replaceAll('\\', '/');
      final marker = '/Android/';
      final markerIndex = normalized.indexOf(marker);
      if (markerIndex < 0) {
        return null;
      }

      final rootPath = normalized.substring(0, markerIndex);
      final sharedDir = Directory(
        p.join(rootPath, 'Download', 'qora_performance'),
      );

      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }

      return sharedDir;
    } catch (_) {
      return null;
    }
  }

  String _sanitizeFileName(String input) {
    final replaced = input.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return replaced.isEmpty ? 'scenario' : replaced;
  }

  String _formatDateTime(DateTime value) {
    return _dateTimeFormatter.format(value.toLocal());
  }

  String? _formatNullableDateTime(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _formatDateTime(value);
  }

  double _roundMetric(double? value) {
    final resolved = value ?? 0;
    return double.parse(resolved.toStringAsFixed(2));
  }

  // Token/cost values can be very small; keep 6 decimals to avoid flattening to 0.0.
  double _roundCost(double? value) {
    final resolved = value ?? 0;
    return double.parse(resolved.toStringAsFixed(6));
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _formatDynamicTimestamp(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is DateTime) {
      return _formatDateTime(raw);
    }

    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _formatDateTime(parsed);
      }
      return raw;
    }

    return raw.toString();
  }

  Map<String, dynamic> _buildPerformanceData(PerformanceScenario scenario) {
    final details = scenario.details;

    final uiAvg = _parseDouble(details['ui_frame_time_ms_avg']);
    final uiMin = _parseDouble(details['ui_frame_time_ms_min']);
    final uiMax = _parseDouble(details['ui_frame_time_ms_max']);

    final rasterAvg = _parseDouble(details['raster_frame_time_ms_avg']);
    final rasterMin = _parseDouble(details['raster_frame_time_ms_min']);
    final rasterMax = _parseDouble(details['raster_frame_time_ms_max']);

    final avgCpu = scenario.avgCpuPercent;
    final peakCpu = _parseDouble(details['cpu_peak_percent']) ?? avgCpu;

    final avgMemory =
        _parseDouble(details['memory_avg_mb']) ?? scenario.peakMemoryMb;
    final peakMemory = scenario.peakMemoryMb;

    return <String, dynamic>{
      'ui_frame_time_ms': <String, dynamic>{
        'avg': _roundMetric(uiAvg),
        'min': _roundMetric(uiMin),
        'max': _roundMetric(uiMax),
      },
      'raster_frame_time_ms': <String, dynamic>{
        'avg': _roundMetric(rasterAvg),
        'min': _roundMetric(rasterMin),
        'max': _roundMetric(rasterMax),
      },
      'cpu_profile': <String, dynamic>{
        'avg_cpu_percent': _roundMetric(avgCpu),
        'peak_cpu_percent': _roundMetric(peakCpu),
      },
      'memory': <String, dynamic>{
        'avg_memory_mb': _roundMetric(avgMemory),
        'peak_memory_mb': _roundMetric(peakMemory),
      },
    };
  }

  Map<String, dynamic> _buildAiAnalysis(
    PerformanceScenario scenario,
    Map<String, dynamic> voiceSessionData,
  ) {
    final tokenUsage = voiceSessionData['token_usage'];
    final costCalculation = voiceSessionData['cost_calculation'];

    final inputTokens = tokenUsage is Map
        ? _parseInt(tokenUsage['input_tokens'])
        : 0;
    final outputTokens = tokenUsage is Map
        ? _parseInt(tokenUsage['output_tokens'])
        : 0;
    final cachedTokens = tokenUsage is Map
        ? _parseInt(tokenUsage['cached_tokens'])
        : 0;
    final totalTokensFromUsage = tokenUsage is Map
        ? _parseInt(tokenUsage['total_tokens'])
        : 0;
    final totalTokens = scenario.totalTokens > 0
        ? scenario.totalTokens
        : totalTokensFromUsage;

    final totalCostFromVoice = costCalculation is Map
        ? _parseDouble(costCalculation['total_cost_usd'])
        : null;
    final totalCost = scenario.sessionCostUsd > 0
        ? scenario.sessionCostUsd
        : (totalCostFromVoice ?? 0);

    final turnsDetail = voiceSessionData['turns_detail'];
    final fallbackTurns = turnsDetail is List ? turnsDetail.length : 0;

    return <String, dynamic>{
      'total_tokens': totalTokens,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'cached_tokens': cachedTokens,
      'total_cost_usd': _roundCost(totalCost),
      'total_turns': scenario.totalTurns > 0
          ? scenario.totalTurns
          : fallbackTurns,
    };
  }

  Map<String, dynamic> _extractVoiceSessionData(PerformanceScenario scenario) {
    final voiceSessionRaw = scenario.details['voice_session'];
    if (voiceSessionRaw is Map<String, dynamic>) {
      final rawTurns = voiceSessionRaw['turns_detail'];
      final rawTokenUsage = voiceSessionRaw['token_usage'];
      final rawCostCalculation = voiceSessionRaw['cost_calculation'];

      final turns = rawTurns is List
          ? rawTurns
                .whereType<Map>()
                .map((rawTurn) => _normalizeVoiceTurn(rawTurn))
                .toList(growable: false)
          : const <Map<String, dynamic>>[];

      final tokenUsage = rawTokenUsage is Map
          ? <String, dynamic>{
              'input_tokens': _parseInt(rawTokenUsage['input_tokens']),
              'output_tokens': _parseInt(rawTokenUsage['output_tokens']),
              'cached_tokens': _parseInt(rawTokenUsage['cached_tokens']),
              'total_tokens': _parseInt(rawTokenUsage['total_tokens']),
            }
          : <String, dynamic>{
              'input_tokens': 0,
              'output_tokens': 0,
              'cached_tokens': 0,
              'total_tokens': scenario.totalTokens,
            };

      final costCalculation = rawCostCalculation is Map
          ? <String, dynamic>{
              'input_cost_usd': _roundCost(
                _parseDouble(rawCostCalculation['input_cost_usd']),
              ),
              'output_cost_usd': _roundCost(
                _parseDouble(rawCostCalculation['output_cost_usd']),
              ),
              'cached_cost_usd': _roundCost(
                _parseDouble(rawCostCalculation['cached_cost_usd']),
              ),
              'total_cost_usd': _roundCost(
                _parseDouble(rawCostCalculation['total_cost_usd']) ??
                    scenario.sessionCostUsd,
              ),
            }
          : <String, dynamic>{
              'input_cost_usd': 0.0,
              'output_cost_usd': 0.0,
              'cached_cost_usd': 0.0,
              'total_cost_usd': _roundCost(scenario.sessionCostUsd),
            };

      final normalized = <String, dynamic>{...voiceSessionRaw};
      normalized['turns_detail'] = turns;
      normalized['token_usage'] = tokenUsage;
      normalized['cost_calculation'] = costCalculation;

      final transcriptRaw = voiceSessionRaw['conversation_transcript'];
      if (transcriptRaw is List) {
        normalized['conversation_transcript'] = transcriptRaw
            .whereType<Map>()
            .map((entry) {
              final mapped = Map<String, dynamic>.from(entry);
              mapped['timestamp'] = _formatDynamicTimestamp(
                mapped['timestamp'],
              );
              return mapped;
            })
            .toList(growable: false);
      }

      return normalized;
    }

    return <String, dynamic>{
      'turns_detail': const <Map<String, dynamic>>[],
      'token_usage': <String, dynamic>{
        'input_tokens': 0,
        'output_tokens': 0,
        'cached_tokens': 0,
        'total_tokens': scenario.totalTokens,
      },
      'cost_calculation': <String, dynamic>{
        'input_cost_usd': 0.0,
        'output_cost_usd': 0.0,
        'cached_cost_usd': 0.0,
        'total_cost_usd': _roundCost(scenario.sessionCostUsd),
      },
    };
  }

  Map<String, dynamic> _normalizeVoiceTurn(Map rawTurn) {
    final turn = Map<String, dynamic>.from(rawTurn);
    return <String, dynamic>{
      'turn': _parseInt(turn['turn']),
      'timestamp': _formatDynamicTimestamp(turn['timestamp']),
      'user_message': turn['user_message']?.toString() ?? '',
      'assistant_message': turn['assistant_message']?.toString() ?? '',
      'input_tokens': _parseInt(turn['input_tokens']),
      'output_tokens': _parseInt(turn['output_tokens']),
      'cached_tokens': _parseInt(turn['cached_tokens']),
      'total_tokens': _parseInt(turn['total_tokens']),
      'input_cost_usd': _roundCost(_parseDouble(turn['input_cost_usd'])),
      'output_cost_usd': _roundCost(_parseDouble(turn['output_cost_usd'])),
      'cached_cost_usd': _roundCost(_parseDouble(turn['cached_cost_usd'])),
      'total_cost_usd': _roundCost(_parseDouble(turn['total_cost_usd'])),
    };
  }

  void _ensureSamplingTimer() {
    if (_samplingTimer != null) {
      return;
    }

    _samplingTimer = Timer.periodic(_samplingInterval, (_) {
      if (_activeRuns.isEmpty) {
        _stopSamplingIfIdle();
        return;
      }

      for (final method in _activeRuns.keys.toList(growable: false)) {
        unawaited(_collectSystemSampleFor(method));
      }
    });
  }

  void _stopSamplingIfIdle() {
    if (_activeRuns.isNotEmpty) {
      return;
    }

    _samplingTimer?.cancel();
    _samplingTimer = null;

    if (_isFrameTimingsAttached) {
      SchedulerBinding.instance.removeTimingsCallback(_frameTimingsCallback);
      _isFrameTimingsAttached = false;
    }
  }

  void _ensureFrameTimingsCallback() {
    if (_isFrameTimingsAttached) {
      return;
    }

    SchedulerBinding.instance.addTimingsCallback(_frameTimingsCallback);
    _isFrameTimingsAttached = true;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty || _activeRuns.isEmpty) {
      return;
    }

    for (final run in _activeRuns.values) {
      run.addFrameTimings(timings);
    }
  }

  Future<void> _collectSystemSampleFor(BookingMethodType method) async {
    final active = _activeRuns[method];
    if (active == null) {
      return;
    }

    final metrics = await _runtimeMetrics.getSystemMetrics();
    active.addSystemSample(
      cpuPercent: metrics.cpuPercent,
      memoryMb: metrics.memoryMb,
    );
  }
}

class _ActiveRun {
  _ActiveRun({
    required this.scenarioId,
    required this.startedAt,
    required this.scenarioName,
  });

  final String scenarioId;
  final DateTime startedAt;
  final String scenarioName;

  double _cpuTotal = 0;
  int _cpuSamples = 0;
  double _peakCpuPercent = 0;
  double _memoryTotal = 0;
  int _memorySamples = 0;
  double _peakMemoryMb = 0;
  final _MetricAccumulator _uiFrameTime = _MetricAccumulator();
  final _MetricAccumulator _rasterFrameTime = _MetricAccumulator();

  double? get averageCpuPercent {
    if (_cpuSamples <= 0) return null;
    return _cpuTotal / _cpuSamples;
  }

  double? get peakCpuPercent {
    if (_cpuSamples <= 0) return null;
    return _peakCpuPercent;
  }

  double? get averageMemoryMb {
    if (_memorySamples <= 0) return null;
    return _memoryTotal / _memorySamples;
  }

  double? get peakMemoryMb {
    if (_peakMemoryMb <= 0) return null;
    return _peakMemoryMb;
  }

  _MetricSummary? get uiFrameTimeStats => _uiFrameTime.summary;

  _MetricSummary? get rasterFrameTimeStats => _rasterFrameTime.summary;

  void addSystemSample({double? cpuPercent, double? memoryMb}) {
    if (cpuPercent != null && cpuPercent >= 0) {
      _cpuTotal += cpuPercent;
      _cpuSamples += 1;
      if (cpuPercent > _peakCpuPercent) {
        _peakCpuPercent = cpuPercent;
      }
    }

    if (memoryMb != null && memoryMb >= 0) {
      _memoryTotal += memoryMb;
      _memorySamples += 1;
      if (memoryMb > _peakMemoryMb) {
        _peakMemoryMb = memoryMb;
      }
    }
  }

  void addFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final uiMs = timing.buildDuration.inMicroseconds / 1000;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000;
      _uiFrameTime.add(uiMs);
      _rasterFrameTime.add(rasterMs);
    }
  }
}

class _MetricAccumulator {
  double _sum = 0;
  int _count = 0;
  double? _min;
  double? _max;

  void add(double value) {
    if (value.isNaN || value.isInfinite || value < 0) {
      return;
    }

    _sum += value;
    _count += 1;

    if (_min == null || value < _min!) {
      _min = value;
    }

    if (_max == null || value > _max!) {
      _max = value;
    }
  }

  _MetricSummary? get summary {
    if (_count <= 0 || _min == null || _max == null) {
      return null;
    }

    return _MetricSummary(avg: _sum / _count, min: _min!, max: _max!);
  }
}

class _MetricSummary {
  const _MetricSummary({
    required this.avg,
    required this.min,
    required this.max,
  });

  final double avg;
  final double min;
  final double max;
}
