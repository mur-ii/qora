import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/participant_repository.dart';
import '../datasources/participant_local_datasource.dart';
import '../models/participant_record.dart';

class ParticipantRepositoryImpl implements ParticipantRepository {
  final ParticipantLocalDataSource localDataSource;

  ParticipantRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveParticipant(ParticipantRecord participant) async {
    await localDataSource.saveParticipant(participant);
  }

  @override
  Future<List<ParticipantRecord>> getAllParticipants() async {
    final participants = localDataSource.getAllParticipants();
    participants.sort((a, b) => a.participantId.compareTo(b.participantId));
    return participants;
  }

  @override
  Future<String> exportParticipantsToCsv() async {
    final participants = await getAllParticipants();
    final rows = <List<String>>[
      [
        'participantId',
        'age',
        'gender',
        'techFamiliarity',
        'voiceFamiliarity',
        'counterbalanceOrder',
        'notes',
        'createdAt',
      ],
      ...participants.map((participant) => participant.toCsvRow()),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${directory.path}${Platform.pathSeparator}participants_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  @override
  Future<void> clearParticipants() async {
    await localDataSource.clearParticipants();
  }
}
