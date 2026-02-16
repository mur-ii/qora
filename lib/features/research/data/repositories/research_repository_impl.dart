import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/research_repository.dart';
import '../datasources/research_local_datasource.dart';
import '../models/research_entry.dart';

class ResearchRepositoryImpl implements ResearchRepository {
  final ResearchLocalDataSource localDataSource;

  ResearchRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveEntry(ResearchEntry entry) async {
    await localDataSource.saveEntry(entry);
  }

  @override
  Future<List<ResearchEntry>> getAllEntries() async {
    final entries = localDataSource.getAllEntries();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<String> exportEntriesToCsv() async {
    final entries = await getAllEntries();
    final rows = <List<String>>[
      [
        'entryId',
        'participantId',
        'sessionId',
        'method',
        'taskOrder',
        'susScore',
        'umuxScore',
        'satisfactionScore',
        'trustScore',
        'preference',
        'notes',
        'createdAt',
      ],
      ...entries.map((entry) => entry.toCsvRow()),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${directory.path}${Platform.pathSeparator}research_entries_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }
}
