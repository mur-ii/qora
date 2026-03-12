import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_log.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/usecases/calculate_session_cost.dart';
import '../../domain/usecases/log_conversation.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc({
    required this.logConversation,
    required this.calculateSessionCost,
    required this.repository,
  }) : super(const ConversationState()) {
    on<LogConversationRequested>(_onLogConversationRequested);
    on<LoadSessionConversationRequested>(_onLoadSessionConversationRequested);
    on<CalculateSessionCostRequested>(_onCalculateSessionCostRequested);
    on<ClearSessionConversationRequested>(_onClearSessionConversationRequested);
  }

  final LogConversation logConversation;
  final CalculateSessionCost calculateSessionCost;
  final ConversationRepository repository;

  Future<void> _onLogConversationRequested(
    LogConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await logConversation(event.conversationLog);
      final refreshed = await repository.getConversationLogsBySession(
        event.conversationLog.sessionId,
      );
      final cost = await calculateSessionCost(event.conversationLog.sessionId);
      emit(
        state.copyWith(
          status: ConversationStatus.success,
          logs: refreshed,
          sessionCostUsd: cost,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ConversationStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onLoadSessionConversationRequested(
    LoadSessionConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(status: ConversationStatus.loading, error: null));
    try {
      final logs = await repository.getConversationLogsBySession(
        event.sessionId,
      );
      emit(
        state.copyWith(
          status: ConversationStatus.success,
          logs: logs,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ConversationStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onCalculateSessionCostRequested(
    CalculateSessionCostRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final totalCost = await calculateSessionCost(event.sessionId);
      emit(
        state.copyWith(
          status: ConversationStatus.success,
          sessionCostUsd: totalCost,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ConversationStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onClearSessionConversationRequested(
    ClearSessionConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(status: ConversationStatus.loading, error: null));
    try {
      await repository.clearSessionLogs(event.sessionId);
      emit(
        state.copyWith(
          status: ConversationStatus.success,
          logs: const <ConversationLog>[],
          sessionCostUsd: 0,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ConversationStatus.failure, error: e.toString()),
      );
    }
  }
}
