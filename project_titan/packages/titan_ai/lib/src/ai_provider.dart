import 'ai_model.dart';
import 'ai_request.dart';
import 'ai_response.dart';

/// Abstract vendor-agnostic AI Provider contract for Project TITAN.
abstract class AIProvider {
  /// Unique provider identifier (e.g. "gemini", "openai").
  String get name;

  /// Initializes the provider instance.
  Future<void> initialize();

  /// Returns true if the provider is initialized.
  bool get isInitialized;

  /// Generates an AI completion for the given [request].
  Future<AIResponse<T>> generate<T>(AIRequest request);

  /// Generates a real-time streaming AI completion for the given [request].
  Stream<String> generateStream(AIRequest request);

  /// Returns list of models supported by this provider.
  List<AIModel> models();

  /// Returns the default model for this provider.
  AIModel defaultModel();

  /// Closes provider and releases resources.
  Future<void> close();
}
