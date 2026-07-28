import 'dart:async';

import '../ai_model.dart';
import '../ai_provider.dart';
import '../ai_request.dart';
import '../ai_response.dart';
import '../ai_token_usage.dart';

/// Comprehensive Mock AI Provider for offline testing, local fallback, and unit testing.
class MockAIProvider implements AIProvider {
  final String _providerName;
  bool _isInitialized = true;
  bool _isClosed = false;
  final bool shouldFail;
  final String customResponse;
  final Duration chunkDelay;

  static const AIModel _mockModel = AIModel(
    id: 'mock-v1',
    displayName: 'Mock AI Engine',
    contextWindow: 128000,
    supportsVision: true,
    supportsStreaming: true,
    supportsJson: true,
    maxOutputTokens: 4096,
  );

  MockAIProvider({
    String name = 'mock',
    this.shouldFail = false,
    String customResponse = '',
    String? fixedResponseText,
    this.chunkDelay = const Duration(milliseconds: 15),
  })  : _providerName = name,
        customResponse = fixedResponseText ?? customResponse;

  @override
  String get name => _providerName;

  @override
  bool get isInitialized => _isInitialized && !_isClosed;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    _isClosed = false;
  }

  @override
  List<AIModel> models() => const [_mockModel];

  @override
  AIModel defaultModel() => _mockModel;

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    if (shouldFail) {
      throw Exception('Simulated MockAIProvider failure.');
    }

    final responseText = customResponse.isNotEmpty
        ? customResponse
        : 'Mock AI response for prompt: "${request.prompt}"';

    final promptTokens = (request.prompt.length / 4).ceil();
    final completionTokens = (responseText.length / 4).ceil();

    return AIResponse<T>(
      text: responseText,
      usage: AITokenUsage(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: promptTokens + completionTokens,
      ),
      model: _mockModel.id,
      provider: name,
      finishReason: 'STOP',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<String> generateStream(AIRequest request) async* {
    if (shouldFail) {
      throw Exception('Simulated MockAIProvider streaming failure.');
    }

    final fullText =
        customResponse.isNotEmpty ? customResponse : 'Mock AI answer for TITAN';

    final words = fullText.split(' ');
    for (int i = 0; i < words.length; i++) {
      final chunk = i == words.length - 1 ? words[i] : '${words[i]} ';
      await Future<void>.delayed(chunkDelay);
      yield chunk;
    }
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    _isInitialized = false;
  }
}
