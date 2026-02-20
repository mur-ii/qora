import 'package:hive/hive.dart';

import '../models/research_entry.dart';

class ResearchLocalDataSource {
  final Box<ResearchEntry> box;

  ResearchLocalDataSource({required this.box});

  Future<void> saveEntry(ResearchEntry entry) async {
    await box.put(entry.entryId, entry);
  }

  List<ResearchEntry> getAllEntries() {
    return box.values.toList(growable: false);
  }

  Future<void> clearEntries() async {
    await box.clear();
  }
}
