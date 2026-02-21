import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/performance_repository.dart';
import '../datasources/performance_local_datasource.dart';
import '../models/performance_summary.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  final PerformanceLocalDataSource localDataSource;

  PerformanceRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveSession(PerformanceSummary session) async {
    await localDataSource.saveSession(session);
  }

  @override
  Future<List<PerformanceSummary>> getAllSessions() async {
    final sessions = localDataSource.getAllSessions();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  @override
  Future<String> exportSessionsToCsv() async {
    final sessions = await getAllSessions();
    final rows = <List<String>>[
      [
        'sessionId',
        'testerSessionId',
        'startTime',
        'endTime',
        'durationInSeconds',
        'interactionMethod',
        'totalClicks',
        'totalVoiceCommands',
        'errorsCount',
        'errorTypes',
        'taskCompleted',
        'searchedLocation',
        'selectedHotelName',
        'bookingSuccess',
        'createdAt',
        'searchDurationSeconds',
        'selectionDurationSeconds',
        'paymentDurationSeconds',
        'confirmationDurationSeconds',
        'userInputTimeSeconds',
        'correctionCount',
        'interactionEffort',
      ],
      ...sessions.map((session) => session.toCsvRow()),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${directory.path}${Platform.pathSeparator}performance_summary_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  @override
  Future<void> clearSessions() async {
    await localDataSource.clearSessions();
  }
}
