import '../../data/models/participant_record.dart';

abstract class ParticipantRepository {
  Future<void> saveParticipant(ParticipantRecord participant);
  Future<List<ParticipantRecord>> getAllParticipants();
  Future<String> exportParticipantsToCsv();
}
