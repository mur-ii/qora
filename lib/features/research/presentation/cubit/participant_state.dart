import 'package:equatable/equatable.dart';

import '../../data/models/participant_record.dart';

abstract class ParticipantState extends Equatable {
  const ParticipantState();

  @override
  List<Object?> get props => [];
}

class ParticipantInitial extends ParticipantState {
  const ParticipantInitial();
}

class ParticipantLoading extends ParticipantState {
  const ParticipantLoading();
}

class ParticipantLoaded extends ParticipantState {
  final List<ParticipantRecord> participants;

  const ParticipantLoaded(this.participants);

  @override
  List<Object?> get props => [participants];
}

class ParticipantExported extends ParticipantState {
  final String filePath;

  const ParticipantExported(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class ParticipantCleared extends ParticipantState {
  const ParticipantCleared();
}

class ParticipantError extends ParticipantState {
  final String message;

  const ParticipantError(this.message);

  @override
  List<Object?> get props => [message];
}
