import '../../data/models/research_entry.dart';

abstract class ResearchRepository {
  Future<void> saveEntry(ResearchEntry entry);
  Future<List<ResearchEntry>> getAllEntries();
  Future<String> exportEntriesToCsv();
}
