import '../services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

/// Represents a parsed AI command with action and parameters.
class AiCommandResult {
  final String action;
  final Map<String, dynamic> params;
  final String response;

  const AiCommandResult({
    required this.action,
    required this.params,
    required this.response,
  });

  factory AiCommandResult.fromJson(Map<String, dynamic> json) {
    return AiCommandResult(
      action: json['action']?.toString() ?? 'answer',
      params: (json['params'] as Map<String, dynamic>?) ?? {},
      response: json['response']?.toString() ?? 'Done.',
    );
  }

  factory AiCommandResult.error(String message) {
    return AiCommandResult(
      action: 'answer',
      params: {},
      response: message,
    );
  }
}

/// Service that processes global voice commands through the AI.
class AiCommandService {
  final SupabaseService _supabase;

  AiCommandService(this._supabase);

  /// Process a voice transcript with business context.
  /// Returns a structured AI command to execute.
  Future<AiCommandResult> processCommand(
    String transcript, {
    required Map<String, dynamic> context,
  }) async {
    try {
      ErrorHandler.debug('AI command processing', {
        'transcriptLength': transcript.length,
        'hasContext': context.isNotEmpty,
      });

      final response = await _supabase.invokeFunction(
        functionName: 'process_voice_command',
        body: {
          'transcript': transcript,
          'context': context,
        },
      );

      // Handle wrapped response
      final data = response.containsKey('result') && response['result'] is Map
          ? response['result'] as Map<String, dynamic>
          : response;

      final result = AiCommandResult.fromJson(data);

      ErrorHandler.debug('AI command result', {
        'action': result.action,
        'response': result.response,
      });

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return AiCommandResult.error(
        'Sorry, I had trouble processing that. Please try again.',
      );
    }
  }
}
