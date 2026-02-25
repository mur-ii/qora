import 'package:equatable/equatable.dart';

import '../../data/models/performance_summary.dart';

abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();

  @override
  List<Object?> get props => [];
}

enum PerformanceStep { search, selection, payment, confirmation }

class StartSession extends PerformanceEvent {
  final InteractionMethod method;
  final String? searchedLocation;
  final String? scenarioId;

  const StartSession({
    required this.method,
    this.searchedLocation,
    this.scenarioId,
  });

  @override
  List<Object?> get props => [method, searchedLocation, scenarioId];
}

class AddClick extends PerformanceEvent {
  const AddClick();
}

class AddScroll extends PerformanceEvent {
  const AddScroll();
}

class AddVoiceCommand extends PerformanceEvent {
  const AddVoiceCommand();
}

class AddCorrection extends PerformanceEvent {
  const AddCorrection();
}

class AddError extends PerformanceEvent {
  final String? errorType;

  const AddError({this.errorType});

  @override
  List<Object?> get props => [errorType];
}

class StartStep extends PerformanceEvent {
  final PerformanceStep step;

  const StartStep(this.step);

  @override
  List<Object?> get props => [step];
}

class EndStep extends PerformanceEvent {
  final PerformanceStep step;

  const EndStep(this.step);

  @override
  List<Object?> get props => [step];
}

class CompleteTask extends PerformanceEvent {
  final bool bookingSuccess;
  final String? selectedHotelName;

  const CompleteTask({this.bookingSuccess = true, this.selectedHotelName});

  @override
  List<Object?> get props => [bookingSuccess, selectedHotelName];
}

class EndSession extends PerformanceEvent {
  const EndSession();
}

class UpdateSearchedLocation extends PerformanceEvent {
  final String searchedLocation;

  const UpdateSearchedLocation(this.searchedLocation);

  @override
  List<Object?> get props => [searchedLocation];
}

class LoadAllSessions extends PerformanceEvent {
  const LoadAllSessions();
}

class ExportSessionsToCsv extends PerformanceEvent {
  const ExportSessionsToCsv();
}

class ClearSessions extends PerformanceEvent {
  const ClearSessions();
}
