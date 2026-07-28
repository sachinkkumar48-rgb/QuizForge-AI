import '../ai_exception.dart';
import '../ai_model.dart';
import '../ai_provider.dart';
import '../ai_request.dart';
import '../ai_response.dart';

/// Contract stub for OpenAI LLM Provider.
class OpenAIProvider implements AIProvider {
  final String apiKey;
  bool _isInitialized = false;

  OpenAIProvider({required this.apiKey});

  @override
  String get name => 'openai';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  List<AIModel> models() => const [
        AIModel(
          id: 'gpt-4o',
          displayName: 'GPT-4o',
          contextWindow: 128000,
          supportsVision: true,
          supportsStreaming: true,
          supportsJson: true,
          maxOutputTokens: 4096,
        ),
      ];

  @override
  AIModel defaultModel() => models().first;

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    throw const AIUnsupportedException(
        'OpenAIProvider is a future provider stub.');
  }

  @override
  Stream<String> generateStream(AIRequest request) async* {
    throw const AIUnsupportedException(
        'OpenAIProvider streaming is not enabled.');
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }
}

/// Contract stub for Azure OpenAI LLM Provider.
class AzureOpenAIProvider implements AIProvider {
  final String apiKey;
  final String endpoint;
  bool _isInitialized = false;

  AzureOpenAIProvider({required this.apiKey, required this.endpoint});

  @override
  String get name => 'azure_openai';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  List<AIModel> models() => const [
        AIModel(
          id: 'azure-gpt4o',
          displayName: 'Azure GPT-4o',
          contextWindow: 128000,
          supportsVision: true,
          supportsStreaming: true,
          supportsJson: true,
          maxOutputTokens: 4096,
        ),
      ];

  @override
  AIModel defaultModel() => models().first;

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    throw const AIUnsupportedException(
        'AzureOpenAIProvider is a future provider stub.');
  }

  @override
  Stream<String> generateStream(AIRequest request) async* {
    throw const AIUnsupportedException(
        'AzureOpenAIProvider streaming is not enabled.');
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }
}

/// Contract stub for Anthropic Claude LLM Provider.
class AnthropicProvider implements AIProvider {
  final String apiKey;
  bool _isInitialized = false;

  AnthropicProvider({required this.apiKey});

  @override
  String get name => 'anthropic';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  List<AIModel> models() => const [
        AIModel(
          id: 'claude-3-5-sonnet',
          displayName: 'Claude 3.5 Sonnet',
          contextWindow: 200000,
          supportsVision: true,
          supportsStreaming: true,
          supportsJson: true,
          maxOutputTokens: 8192,
        ),
      ];

  @override
  AIModel defaultModel() => models().first;

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    throw const AIUnsupportedException(
        'AnthropicProvider is a future provider stub.');
  }

  @override
  Stream<String> generateStream(AIRequest request) async* {
    throw const AIUnsupportedException(
        'AnthropicProvider streaming is not enabled.');
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }
}
