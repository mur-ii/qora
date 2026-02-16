import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/research_entry.dart';
import '../../domain/repositories/research_repository.dart';
import 'research_state.dart';

class ResearchCubit extends Cubit<ResearchState> {
  final ResearchRepository repository;

  ResearchCubit({required this.repository}) : super(const ResearchInitial());

  Future<void> loadEntries() async {
    emit(const ResearchLoading());

    try {
      final entries = await repository.getAllEntries();
      emit(ResearchLoaded(entries));
    } catch (e) {
      emit(ResearchError(e.toString()));
    }
  }

  Future<void> saveEntry(ResearchEntry entry) async {
    emit(const ResearchLoading());

    try {
      await repository.saveEntry(entry);
      final entries = await repository.getAllEntries();
      emit(ResearchLoaded(entries));
    } catch (e) {
      emit(ResearchError(e.toString()));
    }
  }

  Future<void> exportEntries() async {
    emit(const ResearchLoading());

    try {
      final filePath = await repository.exportEntriesToCsv();
      emit(ResearchExported(filePath));
      final entries = await repository.getAllEntries();
      emit(ResearchLoaded(entries));
    } catch (e) {
      emit(ResearchError(e.toString()));
    }
  }
}
