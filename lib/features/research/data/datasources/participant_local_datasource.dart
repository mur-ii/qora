import 'package:hive/hive.dart';

import '../models/participant_record.dart';

class ParticipantLocalDataSource {
  final Box<ParticipantRecord> box;

  ParticipantLocalDataSource({required this.box});

  Future<void> saveParticipant(ParticipantRecord participant) async {
    await box.put(participant.participantId, participant);
  }

  List<ParticipantRecord> getAllParticipants() {
    return box.values.toList(growable: false);
  }

  Future<void> clearParticipants() async {
    await box.clear();
  }
}
