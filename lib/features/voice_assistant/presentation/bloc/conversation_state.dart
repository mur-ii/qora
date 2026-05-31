import 'package:equatable/equatable.dart';

import '../../domain/entities/conversation_log.dart';

enum ConversationStatus { initial, loading, success, failure }

class ConversationState extends Equatable {
  const ConversationState({
    this.status = ConversationStatus.initial,
    this.logs = const [],
    this.sessionCostUsd = 0,
    this.error,
  });

  final ConversationStatus status;
  final List<ConversationLog> logs;
  final double sessionCostUsd;
  final String? error;

  ConversationState copyWith({
    ConversationStatus? status,
    List<ConversationLog>? logs,
    double? sessionCostUsd,
    String? error,
  }) {
    return ConversationState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      sessionCostUsd: sessionCostUsd ?? this.sessionCostUsd,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, logs, sessionCostUsd, error];
}
