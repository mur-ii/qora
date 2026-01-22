import 'package:flutter/material.dart';

import '../../domain/entities/agent_state_entity.dart';

class AgentStatusBar extends StatelessWidget {
  final AgentStateEntity agentState;
  final bool isProcessing;

  const AgentStatusBar({
    super.key,
    required this.agentState,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          if (isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(_getStepIcon(), size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (agentState.currentScreen != null)
                  Text(
                    'Screen: ${agentState.currentScreen}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          if (agentState.userConstraints.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${agentState.userConstraints.length} filters',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (agentState.currentStep) {
      case BookingStep.idle:
        return Icons.home;
      case BookingStep.searching:
        return Icons.search;
      case BookingStep.selecting:
        return Icons.list;
      case BookingStep.viewingDetails:
        return Icons.info;
      case BookingStep.confirmingBooking:
        return Icons.check_circle;
      case BookingStep.bookingCompleted:
        return Icons.done_all;
    }
  }

  String _getStepLabel() {
    switch (agentState.currentStep) {
      case BookingStep.idle:
        return 'Ready';
      case BookingStep.searching:
        return 'Searching Hotels...';
      case BookingStep.selecting:
        return 'Selecting Hotel';
      case BookingStep.viewingDetails:
        return 'Viewing Details';
      case BookingStep.confirmingBooking:
        return 'Confirming Booking';
      case BookingStep.bookingCompleted:
        return 'Booking Complete!';
    }
  }
}
