import 'package:equatable/equatable.dart';

import '../../data/models/research_entry.dart';

abstract class ResearchState extends Equatable {
  const ResearchState();

  @override
  List<Object?> get props => [];
}

class ResearchInitial extends ResearchState {
  const ResearchInitial();
}

class ResearchLoading extends ResearchState {
  const ResearchLoading();
}

class ResearchLoaded extends ResearchState {
  final List<ResearchEntry> entries;

  const ResearchLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

class ResearchExported extends ResearchState {
  final String filePath;

  const ResearchExported(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class ResearchCleared extends ResearchState {
  const ResearchCleared();
}

class ResearchError extends ResearchState {
  final String message;

  const ResearchError(this.message);

  @override
  List<Object?> get props => [message];
}
