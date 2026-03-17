import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    final networkSnapshot = _runtimeMetrics.getNetworkSnapshot();

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
      startTxBytes: networkSnapshot.totalTxBytes,
      startRxBytes: networkSnapshot.totalRxBytes,
    );

    _ensureSamplingTimer();
    await _collectSystemSampleFor(method);

    return resolvedScenarioId;
  }

  Future<void> finishScenario({
    required BookingMethodType method,
    String? scenarioId,
    int? latencyMs,
    double? avgCpuPercent,
    double? peakMemoryMb,
    double? networkTxKb,
    double? networkRxKb,
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
    final peakMemory = peakMemoryMb ?? active?.peakMemoryMb;
    final networkSnapshot = _runtimeMetrics.getNetworkSnapshot();
    final resolvedNetworkTxKb =
        networkTxKb ??
        _bytesToKb(
          (networkSnapshot.totalTxBytes - (active?.startTxBytes ?? 0)),
        );
    final resolvedNetworkRxKb =
        networkRxKb ??
        _bytesToKb(
          (networkSnapshot.totalRxBytes - (active?.startRxBytes ?? 0)),
        );

    final updatedScenario = existing.copyWith(
      endedAt: now,
      latencyMs: resolvedLatencyMs,
      avgCpuPercent: avgCpu,
      peakMemoryMb: peakMemory,
      networkTxKb: resolvedNetworkTxKb,
      networkRxKb: resolvedNetworkRxKb,
      sessionCostUsd: sessionCostUsd,
      totalTokens: totalTokens,
      totalTurns: totalTurns,
      status: status,
      details: _mergeDetails(existing.details, <String, dynamic>{
        if (details != null) ...details,
        'http_tx_kb': _bytesToKb(networkSnapshot.httpTxBytes),
        'http_rx_kb': _bytesToKb(networkSnapshot.httpRxBytes),
        'webrtc_tx_kb': _bytesToKb(networkSnapshot.webRtcTxBytes),
        'webrtc_rx_kb': _bytesToKb(networkSnapshot.webRtcRxBytes),
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
    final networkMetrics = _extractNetworkMetrics(scenario);
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
        'exported_at': now.toUtc().toIso8601String(),
        'format_version': 2,
      },
      'skenario': <String, dynamic>{
        'id': scenario.scenarioId,
        'session_id': sessionIdFromDetails ?? scenario.scenarioId,
        'name': scenario.scenarioName,
        'method': scenario.method.value,
        'status': scenario.status,
        'started_at': scenario.startedAt.toUtc().toIso8601String(),
        'ended_at': scenario.endedAt?.toUtc().toIso8601String(),
        'latency_ms': scenario.latencyMs,
      },
      'performance': <String, dynamic>{
        'avg_cpu_percent': scenario.avgCpuPercent,
        'peak_memory_mb': scenario.peakMemoryMb,
        'network_tx_kb': scenario.networkTxKb,
        'network_rx_kb': scenario.networkRxKb,
        'session_cost_usd': scenario.sessionCostUsd,
        'total_tokens': scenario.totalTokens,
        'total_turns': scenario.totalTurns,
      },
      'voice_session': voiceSessionData,
      'network_metrics': networkMetrics,
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

  Map<String, dynamic> _extractVoiceSessionData(PerformanceScenario scenario) {
    final voiceSessionRaw = scenario.details['voice_session'];
    if (voiceSessionRaw is Map<String, dynamic>) {
      final rawTurns = voiceSessionRaw['turns_detail'];
      final rawTokenUsage = voiceSessionRaw['token_usage'];
      final rawCostCalculation = voiceSessionRaw['cost_calculation'];

      return <String, dynamic>{
        'turns_detail': rawTurns is List
            ? List<dynamic>.from(rawTurns)
            : const <Map<String, dynamic>>[],
        'token_usage': rawTokenUsage is Map
            ? Map<String, dynamic>.from(rawTokenUsage)
            : <String, dynamic>{
                'input_tokens': null,
                'output_tokens': null,
                'cached_tokens': null,
                'total_tokens': scenario.totalTokens,
              },
        'cost_calculation': rawCostCalculation is Map
            ? Map<String, dynamic>.from(rawCostCalculation)
            : <String, dynamic>{
                'input_cost_usd': null,
                'output_cost_usd': null,
                'cached_cost_usd': null,
                'total_cost_usd': scenario.sessionCostUsd,
              },
      };
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
        'total_cost_usd': scenario.sessionCostUsd,
      },
    };
  }

  Map<String, dynamic> _extractNetworkMetrics(PerformanceScenario scenario) {
    final details = scenario.details;

    return <String, dynamic>{
      'http': <String, dynamic>{
        'tx_kb': details['http_tx_kb'],
        'rx_kb': details['http_rx_kb'],
      },
      'webrtc': <String, dynamic>{
        'tx_kb': details['webrtc_tx_kb'],
        'rx_kb': details['webrtc_rx_kb'],
      },
      'runtime_metrics_source':
          details['runtime_metrics_source'] ?? 'android_method_channel',
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

  double _bytesToKb(int bytes) {
    if (bytes <= 0) return 0;
    return bytes / 1024;
  }
}

class _ActiveRun {
  _ActiveRun({
    required this.scenarioId,
    required this.startedAt,
    required this.scenarioName,
    required this.startTxBytes,
    required this.startRxBytes,
  });

  final String scenarioId;
  final DateTime startedAt;
  final String scenarioName;
  final int startTxBytes;
  final int startRxBytes;

  double _cpuTotal = 0;
  int _cpuSamples = 0;
  double _peakMemoryMb = 0;

  double? get averageCpuPercent {
    if (_cpuSamples <= 0) return null;
    return _cpuTotal / _cpuSamples;
  }

  double? get peakMemoryMb {
    if (_peakMemoryMb <= 0) return null;
    return _peakMemoryMb;
  }

  void addSystemSample({double? cpuPercent, double? memoryMb}) {
    if (cpuPercent != null && cpuPercent >= 0) {
      _cpuTotal += cpuPercent;
      _cpuSamples += 1;
    }

    if (memoryMb != null && memoryMb > _peakMemoryMb) {
      _peakMemoryMb = memoryMb;
    }
  }
}
