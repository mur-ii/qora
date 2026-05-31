import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../entities/agent_state_entity.dart';
import '../entities/function_call_entity.dart';
import 'agentic_action_usecases.dart';
import 'agentic_ai_context.dart';
import 'agentic_function_definitions_usecase.dart';

/// Facade that coordinates focused agentic booking usecases.
class AgenticAiUseCase {
  final NavigationService navigationService;
  final AgenticAiContext _context = AgenticAiContext();
  final AgenticFunctionDefinitionsUseCase _functionDefinitionsUseCase =
      AgenticFunctionDefinitionsUseCase();

  late final SearchHotelsUseCase _searchHotelsUseCase;
  late final HotelDetailsUseCase _hotelDetailsUseCase;
  late final SelectRoomUseCase _selectRoomUseCase;
  late final PricingUseCase _pricingUseCase;
  late final CreateBookingUseCase _createBookingUseCase;
  late final ConfirmBookingUseCase _confirmBookingUseCase;
  late final NavigateToScreenUseCase _navigateToScreenUseCase;
  late final UpdateBookingStepUseCase _updateBookingStepUseCase;

  AgenticAiUseCase({required this.navigationService}) {
    _searchHotelsUseCase = SearchHotelsUseCase(
      context: _context,
      navigationService: navigationService,
    );
    _hotelDetailsUseCase = HotelDetailsUseCase(
      context: _context,
      navigationService: navigationService,
    );
    _selectRoomUseCase = SelectRoomUseCase(context: _context);
    _pricingUseCase = PricingUseCase();
    _createBookingUseCase = CreateBookingUseCase(
      context: _context,
      navigationService: navigationService,
    );
    _confirmBookingUseCase = ConfirmBookingUseCase(context: _context);
    _navigateToScreenUseCase = NavigateToScreenUseCase(
      context: _context,
      navigationService: navigationService,
    );
    _updateBookingStepUseCase = UpdateBookingStepUseCase(context: _context);
  }

  AgentStateEntity get agentState => _context.agentState;

  void reset() {
    _context.reset();
  }

  void previewUserConstraints(Map<String, dynamic> args) {
    _context.previewUserConstraints(args);
  }

  List<Map<String, dynamic>> getFunctionDefinitions() {
    return _functionDefinitionsUseCase.call();
  }

  Future<FunctionResultEntity> executeFunction(
    FunctionCallEntity functionCall,
  ) async {
    AppLogger.info('AgenticAI', 'Executing function: ${functionCall.name}');

    try {
      dynamic result;

      switch (functionCall.name) {
        case 'search_hotels':
          result = await _searchHotelsUseCase.call(functionCall.arguments);
          break;

        case 'get_hotel_details':
          result = await _hotelDetailsUseCase.call(functionCall.arguments);
          break;

        case 'get_pricing':
          result = await _pricingUseCase.call(functionCall.arguments);
          break;

        case 'select_room':
          result = await _selectRoomUseCase.call(functionCall.arguments);
          break;

        case 'create_booking':
          result = await _createBookingUseCase.call(functionCall.arguments);
          break;

        case 'confirm_booking':
          result = await _confirmBookingUseCase.call(functionCall.arguments);
          break;

        case 'navigate_to_screen':
          result = await _navigateToScreenUseCase.call(functionCall.arguments);
          break;

        case 'update_booking_step':
          result = await _updateBookingStepUseCase.call(functionCall.arguments);
          break;

        default:
          result = {'error': 'Unknown function: ${functionCall.name}'};
      }

      return FunctionResultEntity(callId: functionCall.callId, result: result);
    } catch (e, stackTrace) {
      AppLogger.error(
        'AgenticAI',
        'Function execution error',
        error: e,
        stackTrace: stackTrace,
      );
      return FunctionResultEntity(
        callId: functionCall.callId,
        error: e.toString(),
      );
    }
  }

  String getSystemInstructions() {
    return _context.getSystemInstructions();
  }
}
