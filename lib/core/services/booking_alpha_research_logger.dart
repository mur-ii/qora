import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BookingAlphaSessionLog {
  const BookingAlphaSessionLog({
    required this.sessionId,
    required this.runId,
    required this.loopIndex,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.status,
    required this.successfulSteps,
    required this.totalSteps,
    required this.networkRequestCount,
    required this.networkTotalDurationMs,
    required this.networkRequests,
    required this.performance,
    this.error,
  });

  final String sessionId;
  final String runId;
  final int loopIndex;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMs;
  final String status;
  final int successfulSteps;
  final int totalSteps;
  final int networkRequestCount;
  final int networkTotalDurationMs;
  final List<Map<String, dynamic>> networkRequests;
  final Map<String, dynamic> performance;
  final String? error;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session_id': sessionId,
      'run_id': runId,
      'loop_index': loopIndex,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_ms': durationMs,
      'status': status,
      'successful_steps': successfulSteps,
      'total_steps': totalSteps,
      'error': error,
      'network_request_count': networkRequestCount,
      'network_total_duration_ms': networkTotalDurationMs,
      'network_requests': networkRequests,
      'performance': performance,
    };
  }
}

class BookingAlphaLogArtifacts {
  const BookingAlphaLogArtifacts({
    required this.rawLogPath,
    required this.summaryLogPath,
  });

  final String rawLogPath;
  final String summaryLogPath;
}

class BookingAlphaResearchLogger {
  BookingAlphaResearchLogger();

  Future<BookingAlphaLogArtifacts> writeRunLogs({
    required String runId,
    required DateTime runStartedAt,
    required DateTime runEndedAt,
    required int plannedLoops,
    required List<BookingAlphaSessionLog> sessions,
  }) async {
    final rawCsv = _buildRawCsv(sessions);
    final summaryPayload = _buildSummaryPayload(
      runId: runId,
      runStartedAt: runStartedAt,
      runEndedAt: runEndedAt,
      plannedLoops: plannedLoops,
      sessions: sessions,
    );

    final primaryBaseDir = await _resolvePrimaryBaseDirectory();
    final mirrorBaseDirs = await _resolveMirrorBaseDirectories(primaryBaseDir);

    final rawFilePath = await _writeRawCsvForRun(
      baseDir: primaryBaseDir,
      runId: runId,
      content: rawCsv,
    );
    final summaryFilePath = await _writeSummaryJsonForRun(
      baseDir: primaryBaseDir,
      runId: runId,
      payload: <String, dynamic>{
        ...summaryPayload,
        'export_info': <String, dynamic>{
          'primary_directory': primaryBaseDir.path,
          'mirror_directories': mirrorBaseDirs
              .map((Directory dir) => dir.path)
              .toList(growable: false),
        },
      },
    );

    for (final mirrorBaseDir in mirrorBaseDirs) {
      await _writeRawCsvForRun(
        baseDir: mirrorBaseDir,
        runId: runId,
        content: rawCsv,
      );
      await _writeSummaryJsonForRun(
        baseDir: mirrorBaseDir,
        runId: runId,
        payload: <String, dynamic>{
          ...summaryPayload,
          'export_info': <String, dynamic>{
            'primary_directory': primaryBaseDir.path,
            'mirror_directories': mirrorBaseDirs
                .map((Directory dir) => dir.path)
                .toList(growable: false),
          },
        },
      );
    }

    return BookingAlphaLogArtifacts(
      rawLogPath: rawFilePath,
      summaryLogPath: summaryFilePath,
    );
  }

  Future<String> _writeRawCsvForRun({
    required Directory baseDir,
    required String runId,
    required String content,
  }) async {
    final runDir = await _ensureRunDirectory(baseDir, runId);
    final filePath = p.join(runDir.path, 'booking_alpha_raw_$runId.csv');
    await File(filePath).writeAsString(content, flush: true);
    return filePath;
  }

  Future<String> _writeSummaryJsonForRun({
    required Directory baseDir,
    required String runId,
    required Map<String, dynamic> payload,
  }) async {
    final runDir = await _ensureRunDirectory(baseDir, runId);
    final filePath = p.join(runDir.path, 'booking_alpha_summary_$runId.json');
    final pretty = const JsonEncoder.withIndent('  ').convert(payload);
    await File(filePath).writeAsString(pretty, flush: true);
    return filePath;
  }

  Future<Directory> _ensureRunDirectory(Directory baseDir, String runId) async {
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final runsDir = Directory(p.join(baseDir.path, 'runs'));
    if (!await runsDir.exists()) {
      await runsDir.create(recursive: true);
    }

    final runDir = Directory(p.join(runsDir.path, runId));
    if (!await runDir.exists()) {
      await runDir.create(recursive: true);
    }

    return runDir;
  }

  String _buildRawCsv(List<BookingAlphaSessionLog> sessions) {
    final buffer = StringBuffer();
    const headers = <String>[
      'session_id',
      'run_id',
      'loop_index',
      'started_at',
      'ended_at',
      'duration_ms',
      'status',
      'successful_steps',
      'total_steps',
      'error',
      'network_request_count',
      'network_total_duration_ms',
      'latency_ms',
      'avg_cpu_percent',
      'peak_memory_mb',
      'ui_frame_time_ms_avg',
      'ui_frame_time_ms_max',
      'raster_frame_time_ms_avg',
      'raster_frame_time_ms_max',
    ];

    buffer.writeln(headers.join(','));

    for (final session in sessions) {
      final perf = session.performance;
      final row = <String>[
        session.sessionId,
        session.runId,
        session.loopIndex.toString(),
        session.startedAt.toIso8601String(),
        session.endedAt.toIso8601String(),
        session.durationMs.toString(),
        session.status,
        session.successfulSteps.toString(),
        session.totalSteps.toString(),
        session.error ?? '',
        session.networkRequestCount.toString(),
        session.networkTotalDurationMs.toString(),
        _csvValue(perf['latency_ms']),
        _csvValue(perf['avg_cpu_percent']),
        _csvValue(perf['peak_memory_mb']),
        _csvValue(perf['ui_frame_time_ms_avg']),
        _csvValue(perf['ui_frame_time_ms_max']),
        _csvValue(perf['raster_frame_time_ms_avg']),
        _csvValue(perf['raster_frame_time_ms_max']),
      ].map(_escapeCsv).toList(growable: false);

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _csvValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  String _escapeCsv(String input) {
    if (!input.contains(',') && !input.contains('"') && !input.contains('\n')) {
      return input;
    }

    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  Map<String, dynamic> _buildSummaryPayload({
    required String runId,
    required DateTime runStartedAt,
    required DateTime runEndedAt,
    required int plannedLoops,
    required List<BookingAlphaSessionLog> sessions,
  }) {
    final totalSessions = sessions.length;
    final successSessions = sessions
        .where((BookingAlphaSessionLog session) => session.status == 'success')
        .length;
    final failedSessions = totalSessions - successSessions;

    final totalDurationMs = sessions.fold<int>(
      0,
      (int sum, BookingAlphaSessionLog session) => sum + session.durationMs,
    );
    final totalNetworkDurationMs = sessions.fold<int>(
      0,
      (int sum, BookingAlphaSessionLog session) =>
          sum + session.networkTotalDurationMs,
    );
    final totalNetworkRequests = sessions.fold<int>(
      0,
      (int sum, BookingAlphaSessionLog session) =>
          sum + session.networkRequestCount,
    );

    final avgDurationMs = totalSessions == 0
        ? 0
        : (totalDurationMs / totalSessions).round();

    final avgNetworkDurationMs = totalSessions == 0
        ? 0
        : (totalNetworkDurationMs / totalSessions).round();

    final sessionDurations = sessions
        .map((BookingAlphaSessionLog session) => session.durationMs)
        .toList(growable: false);
    final networkDurations = sessions
        .map((BookingAlphaSessionLog session) => session.networkTotalDurationMs)
        .toList(growable: false);

    final completedSteps = sessions.fold<int>(
      0,
      (int sum, BookingAlphaSessionLog session) =>
          sum + session.successfulSteps,
    );
    final totalExpectedSteps = sessions.fold<int>(
      0,
      (int sum, BookingAlphaSessionLog session) => sum + session.totalSteps,
    );

    return <String, dynamic>{
      'run': <String, dynamic>{
        'run_id': runId,
        'planned_loops': plannedLoops,
        'executed_sessions': totalSessions,
        'started_at': runStartedAt.toIso8601String(),
        'ended_at': runEndedAt.toIso8601String(),
        'duration_ms': runEndedAt.difference(runStartedAt).inMilliseconds,
      },
      'summary': <String, dynamic>{
        'success_sessions': successSessions,
        'failed_sessions': failedSessions,
        'success_rate': totalSessions == 0
            ? 0
            : double.parse(
                (successSessions / totalSessions).toStringAsFixed(4),
              ),
        'avg_session_duration_ms': avgDurationMs,
        'avg_network_duration_ms': avgNetworkDurationMs,
        'total_network_requests': totalNetworkRequests,
        'completed_steps': completedSteps,
        'total_expected_steps': totalExpectedSteps,
        'session_duration_distribution_ms': _buildDistributionStats(
          sessionDurations,
        ),
        'network_duration_distribution_ms': _buildDistributionStats(
          networkDurations,
        ),
        'research_profile': <String, dynamic>{
          'recommended_min_loops': 100,
          'is_conference_ready': plannedLoops >= 100,
        },
      },
      'failed_sessions': sessions
          .where(
            (BookingAlphaSessionLog session) => session.status != 'success',
          )
          .map(
            (BookingAlphaSessionLog session) => <String, dynamic>{
              'session_id': session.sessionId,
              'loop_index': session.loopIndex,
              'error': session.error,
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _buildDistributionStats(List<int> values) {
    if (values.isEmpty) {
      return <String, dynamic>{
        'min': 0,
        'max': 0,
        'p50': 0.0,
        'p90': 0.0,
        'p95': 0.0,
        'p99': 0.0,
        'std_dev': 0.0,
      };
    }

    final sorted = List<int>.from(values)..sort();
    final mean = values.reduce((int a, int b) => a + b) / values.length;
    final variance =
        values.fold<double>(0, (double acc, int value) {
          final diff = value - mean;
          return acc + (diff * diff);
        }) /
        values.length;

    return <String, dynamic>{
      'min': sorted.first,
      'max': sorted.last,
      'p50': _roundDouble(_percentile(sorted, 0.50)),
      'p90': _roundDouble(_percentile(sorted, 0.90)),
      'p95': _roundDouble(_percentile(sorted, 0.95)),
      'p99': _roundDouble(_percentile(sorted, 0.99)),
      'std_dev': _roundDouble(variance <= 0 ? 0 : math.sqrt(variance)),
    };
  }

  double _percentile(List<int> sortedValues, double p) {
    if (sortedValues.isEmpty) {
      return 0;
    }
    if (sortedValues.length == 1) {
      return sortedValues.first.toDouble();
    }

    final rank = p * (sortedValues.length - 1);
    final lowerIndex = rank.floor();
    final upperIndex = rank.ceil();

    if (lowerIndex == upperIndex) {
      return sortedValues[lowerIndex].toDouble();
    }

    final lower = sortedValues[lowerIndex].toDouble();
    final upper = sortedValues[upperIndex].toDouble();
    final weight = rank - lowerIndex;
    return lower + ((upper - lower) * weight);
  }

  double _roundDouble(double value, {int digits = 2}) {
    return double.parse(value.toStringAsFixed(digits));
  }

  Future<Directory> _resolvePrimaryBaseDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(docs.path, 'qora_alpha_testing'));
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  Future<List<Directory>> _resolveMirrorBaseDirectories(
    Directory primaryBaseDir,
  ) async {
    if (!Platform.isAndroid) {
      return const <Directory>[];
    }

    final mirrors = <Directory>[];
    final externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory == null) {
      return mirrors;
    }

    final sharedDownload = await _trySharedDownloadDir(externalDirectory);
    if (sharedDownload != null) {
      mirrors.add(sharedDownload);
    }

    final appExternal = Directory(
      p.join(externalDirectory.path, 'qora_alpha_testing'),
    );
    mirrors.add(appExternal);

    final normalizedPrimary = p.normalize(primaryBaseDir.path);
    final seen = <String>{normalizedPrimary};
    final uniqueMirrors = <Directory>[];

    for (final mirror in mirrors) {
      final normalized = p.normalize(mirror.path);
      if (seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      if (!await mirror.exists()) {
        await mirror.create(recursive: true);
      }
      uniqueMirrors.add(mirror);
    }

    return uniqueMirrors;
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
        p.join(rootPath, 'Download', 'qora_alpha_testing'),
      );

      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }

      return sharedDir;
    } catch (_) {
      return null;
    }
  }
}
