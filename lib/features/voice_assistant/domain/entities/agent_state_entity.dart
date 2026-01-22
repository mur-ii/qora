import 'package:equatable/equatable.dart';

/// Represents the agentic AI's internal state
class AgentStateEntity extends Equatable {
  final BookingStep currentStep;
  final Map<String, dynamic> userConstraints;
  final Map<String, dynamic> appState;
  final String? currentScreen;
  final List<String> conversationHistory;

  const AgentStateEntity({
    this.currentStep = BookingStep.idle,
    this.userConstraints = const {},
    this.appState = const {},
    this.currentScreen,
    this.conversationHistory = const [],
  });

  AgentStateEntity copyWith({
    BookingStep? currentStep,
    Map<String, dynamic>? userConstraints,
    Map<String, dynamic>? appState,
    String? currentScreen,
    List<String>? conversationHistory,
  }) {
    return AgentStateEntity(
      currentStep: currentStep ?? this.currentStep,
      userConstraints: userConstraints ?? this.userConstraints,
      appState: appState ?? this.appState,
      currentScreen: currentScreen ?? this.currentScreen,
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    userConstraints,
    appState,
    currentScreen,
    conversationHistory,
  ];
}

enum BookingStep {
  idle,
  searching,
  selecting,
  viewingDetails,
  confirmingBooking,
  bookingCompleted,
}
