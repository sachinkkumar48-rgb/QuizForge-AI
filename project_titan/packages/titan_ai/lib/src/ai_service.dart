import 'ai_model.dart';
import 'ai_request.dart';
import 'ai_response.dart';

/// Single top-level entry point interface for AI generation in Project TITAN applications.
abstract class AIService {
  /// Initializes the AI service and its underlying providers.
  Future<void> initialize();

  /// Returns true if the service is initialized.
  bool get isInitialized;

  /// Generates an AI completion using the active provider.
  Future<AIResponse<T>> generate<T>(AIRequest request);

  /// Returns list of available models supported by current AI providers.
  List<AIModel> availableModels();

  /// Returns default AI model.
  AIModel defaultModel();

  /// Closes AI service and releases resources.
  Future<void> close();
}
