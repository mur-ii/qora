import 'package:equatable/equatable.dart';

/// Represents a function call from OpenAI Realtime API
class FunctionCallEntity extends Equatable {
  final String callId;
  final String name;
  final Map<String, dynamic> arguments;

  const FunctionCallEntity({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  @override
  List<Object?> get props => [callId, name, arguments];
}

/// Represents the result of a function call
class FunctionResultEntity extends Equatable {
  final String callId;
  final dynamic result;
  final String? error;

  const FunctionResultEntity({required this.callId, this.result, this.error});

  @override
  List<Object?> get props => [callId, result, error];
}
