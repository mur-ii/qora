import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/participant_record.dart';
import '../../domain/repositories/participant_repository.dart';
import 'participant_state.dart';

class ParticipantCubit extends Cubit<ParticipantState> {
  final ParticipantRepository repository;

  ParticipantCubit({required this.repository})
    : super(const ParticipantInitial());

  Future<void> loadParticipants() async {
    emit(const ParticipantLoading());

    try {
      var participants = await repository.getAllParticipants();
      if (participants.isEmpty) {
        final now = DateTime.now();
        final seeded = _seedParticipants(now);
        for (final participant in seeded) {
          await repository.saveParticipant(participant);
        }
        participants = await repository.getAllParticipants();
      }
      emit(ParticipantLoaded(participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> saveParticipant(ParticipantRecord participant) async {
    emit(const ParticipantLoading());

    try {
      await repository.saveParticipant(participant);
      final participants = await repository.getAllParticipants();
      emit(ParticipantLoaded(participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> exportParticipants() async {
    emit(const ParticipantLoading());

    try {
      final filePath = await repository.exportParticipantsToCsv();
      emit(ParticipantExported(filePath));
      final participants = await repository.getAllParticipants();
      emit(ParticipantLoaded(participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  List<ParticipantRecord> _seedParticipants(DateTime now) {
    final participants = <ParticipantRecord>[];
    for (var i = 1; i <= 30; i++) {
      final id = 'P${i.toString().padLeft(2, '0')}';
      final guiFirst = i.isOdd;
      participants.add(
        ParticipantRecord(
          participantId: id,
          age: 0,
          gender: 'Unspecified',
          techFamiliarity: 3,
          voiceFamiliarity: 3,
          guiFirst: guiFirst,
          notes: '',
          createdAt: now,
        ),
      );
    }
    return participants;
  }
}
