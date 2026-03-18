import 'dart:convert';

enum BookingMethodType { gui, vui }

extension BookingMethodTypeX on BookingMethodType {
  String get value => name;

  String get label {
    switch (this) {
      case BookingMethodType.gui:
        return 'GUI';
      case BookingMethodType.vui:
        return 'VUI';
    }
  }

  static BookingMethodType fromValue(String value) {
    return BookingMethodType.values.firstWhere(
      (method) => method.value == value,
      orElse: () => BookingMethodType.gui,
    );
  }
}

class PerformanceScenario {
  const PerformanceScenario({
    this.id,
    required this.scenarioId,
    required this.method,
    required this.scenarioName,
    required this.startedAt,
    this.endedAt,
    this.latencyMs,
    this.avgCpuPercent,
    this.peakMemoryMb,
    this.sessionCostUsd = 0,
    this.totalTokens = 0,
    this.totalTurns = 0,
    this.status = 'running',
    this.details = const <String, dynamic>{},
  });

  final int? id;
  final String scenarioId;
  final BookingMethodType method;
  final String scenarioName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? latencyMs;
  final double? avgCpuPercent;
  final double? peakMemoryMb;
  final double sessionCostUsd;
  final int totalTokens;
  final int totalTurns;
  final String status;
  final Map<String, dynamic> details;

  bool get isCompleted => status == 'completed';

  PerformanceScenario copyWith({
    int? id,
    String? scenarioId,
    BookingMethodType? method,
    String? scenarioName,
    DateTime? startedAt,
    DateTime? endedAt,
    int? latencyMs,
    double? avgCpuPercent,
    double? peakMemoryMb,
    double? sessionCostUsd,
    int? totalTokens,
    int? totalTurns,
    String? status,
    Map<String, dynamic>? details,
  }) {
    return PerformanceScenario(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      method: method ?? this.method,
      scenarioName: scenarioName ?? this.scenarioName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      latencyMs: latencyMs ?? this.latencyMs,
      avgCpuPercent: avgCpuPercent ?? this.avgCpuPercent,
      peakMemoryMb: peakMemoryMb ?? this.peakMemoryMb,
      sessionCostUsd: sessionCostUsd ?? this.sessionCostUsd,
      totalTokens: totalTokens ?? this.totalTokens,
      totalTurns: totalTurns ?? this.totalTurns,
      status: status ?? this.status,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'scenario_id': scenarioId,
      'method': method.value,
      'scenario_name': scenarioName,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'latency_ms': latencyMs,
      'avg_cpu_percent': avgCpuPercent,
      'peak_memory_mb': peakMemoryMb,
      'session_cost_usd': sessionCostUsd,
      'total_tokens': totalTokens,
      'total_turns': totalTurns,
      'status': status,
      'details_json': jsonEncode(details),
    };
  }

  factory PerformanceScenario.fromMap(Map<String, dynamic> map) {
    final detailsJson = map['details_json']?.toString();

    return PerformanceScenario(
      id: map['id'] as int?,
      scenarioId: map['scenario_id'] as String,
      method: BookingMethodTypeX.fromValue(map['method'] as String),
      scenarioName: map['scenario_name'] as String,
      startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.parse(map['ended_at'] as String).toLocal(),
      latencyMs: map['latency_ms'] as int?,
      avgCpuPercent: _parseDouble(map['avg_cpu_percent']),
      peakMemoryMb: _parseDouble(map['peak_memory_mb']),
      sessionCostUsd: _parseDouble(map['session_cost_usd']) ?? 0,
      totalTokens: _parseInt(map['total_tokens']) ?? 0,
      totalTurns: _parseInt(map['total_turns']) ?? 0,
      status: map['status']?.toString() ?? 'running',
      details: _parseDetails(detailsJson),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Map<String, dynamic> _parseDetails(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const <String, dynamic>{};
    }

    final parsed = jsonDecode(jsonString);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    }

    return const <String, dynamic>{};
  }
}
