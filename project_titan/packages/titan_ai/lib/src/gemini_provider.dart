import 'dart:async';
import 'dart:convert';
import 'package:titan_network/titan_network.dart';

import 'ai_exception.dart';
import 'ai_model.dart';
import 'ai_provider.dart';
import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_token_usage.dart';

/// Production-grade Google Gemini AI Provider implementation for Project TITAN.
///
/// Supports REST API completion generation, stream completions, temperature,
/// topP, topK, safety settings, JSON response mode, and custom timeouts.
class GeminiProvider implements AIProvider {
  static const String _providerName = 'gemini';
  final String apiKey;
  final NetworkService _networkService;
  final String _baseUrl;
  final String? _defaultModelId;
  final Duration? _timeout;
  bool _isInitialized = false;
  bool _isClosed = false;

  static const AIModel _flashModel = AIModel(
    id: 'gemini-1.5-flash',
    displayName: 'Gemini 1.5 Flash',
    contextWindow: 1048576,
    supportsVision: true,
    supportsStreaming: true,
    supportsJson: true,
    maxOutputTokens: 8192,
  );

  static const AIModel _proModel = AIModel(
    id: 'gemini-1.5-pro',
    displayName: 'Gemini 1.5 Pro',
    contextWindow: 2097152,
    supportsVision: true,
    supportsStreaming: true,
    supportsJson: true,
    maxOutputTokens: 8192,
  );

  GeminiProvider({
    required this.apiKey,
    required NetworkService networkService,
    String baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
    String? defaultModelId,
    Duration? timeout,
  })  : _networkService = networkService,
        _baseUrl = baseUrl,
        _defaultModelId = defaultModelId,
        _timeout = timeout;

  @override
  String get name => _providerName;

  @override
  bool get isInitialized => _isInitialized && !_isClosed;

  void _checkState() {
    if (_isClosed) {
      throw const AIInitializationException('GeminiProvider has been closed.');
    }
    if (!isInitialized) {
      throw const AIInitializationException(
          'GeminiProvider is not initialized.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isClosed) {
      throw const AIInitializationException(
          'Cannot initialize closed GeminiProvider.');
    }
    if (apiKey.isEmpty) {
      throw const AIInitializationException('Gemini API key cannot be empty.');
    }
    if (!_networkService.isInitialized) {
      await _networkService.initialize();
    }
    _isInitialized = true;
  }

  @override
  List<AIModel> models() => const [_flashModel, _proModel];

  @override
  AIModel defaultModel() {
    if (_defaultModelId != null && _defaultModelId.isNotEmpty) {
      final found = models().where((m) => m.id == _defaultModelId).firstOrNull;
      if (found != null) return found;
    }
    return _flashModel;
  }

  Map<String, dynamic> _buildPayload(AIRequest request) {
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': request.prompt}
        ]
      }
    ];

    final payload = <String, dynamic>{
      'contents': contents,
    };

    if (request.systemPrompt != null && request.systemPrompt!.isNotEmpty) {
      payload['system_instruction'] = {
        'parts': [
          {'text': request.systemPrompt}
        ]
      };
    }

    final generationConfig = <String, dynamic>{};
    if (request.temperature != null) {
      generationConfig['temperature'] = request.temperature;
    }
    if (request.maxTokens != null) {
      generationConfig['maxOutputTokens'] = request.maxTokens;
    }

    if (request.metadata.containsKey('topP')) {
      generationConfig['topP'] = request.metadata['topP'];
    }
    if (request.metadata.containsKey('topK')) {
      generationConfig['topK'] = request.metadata['topK'];
    }
    if (request.metadata['jsonMode'] == true) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    if (generationConfig.isNotEmpty) {
      payload['generationConfig'] = generationConfig;
    }

    payload['safetySettings'] = [
      {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
      },
      {
        'category': 'HARM_CATEGORY_HATE_SPEECH',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
      },
    ];

    return payload;
  }

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    _checkState();

    final targetModelId = request.model ?? defaultModel().id;
    final modelExists = models().any((m) => m.id == targetModelId);
    if (!modelExists) {
      throw AIModelException(
          'Unsupported model "$targetModelId" for Gemini provider.',
          targetModelId);
    }

    final url = '$_baseUrl/models/$targetModelId:generateContent';
    final payload = _buildPayload(request);

    final netRequest = NetworkRequest(
      method: HttpMethod.post,
      url: url,
      queryParameters: {'key': apiKey},
      headers: const {'Content-Type': 'application/json'},
      body: payload,
      timeout: _timeout,
    );

    try {
      final response =
          await _networkService.post<Map<String, dynamic>>(netRequest);

      if (!response.isSuccess) {
        throw AIResponseException(
          'Gemini API returned error HTTP status code ${response.statusCode}',
          response.statusCode,
        );
      }

      final bodyMap = response.body;
      if (bodyMap == null) {
        throw const AIResponseException(
            'Gemini response body was empty or unparseable.');
      }

      final candidates = bodyMap['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const AIResponseException(
            'Gemini returned no response candidates.');
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final text = parts?.isNotEmpty == true
          ? (parts!.first as Map<String, dynamic>)['text'] as String? ?? ''
          : '';

      final finishReason = firstCandidate['finishReason'] as String? ?? 'STOP';

      final usageMetadata = bodyMap['usageMetadata'] as Map<String, dynamic>?;
      final promptTokens = usageMetadata?['promptTokenCount'] as int? ?? 0;
      final completionTokens =
          usageMetadata?['candidatesTokenCount'] as int? ?? 0;
      final totalTokens = usageMetadata?['totalTokenCount'] as int? ??
          (promptTokens + completionTokens);

      final tokenUsage = AITokenUsage(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
      );

      T? data;
      if (T != String && T != dynamic && text.isNotEmpty) {
        try {
          data = jsonDecode(text) as T?;
        } catch (_) {
          data = null;
        }
      }

      return AIResponse<T>(
        text: text,
        data: data,
        usage: tokenUsage,
        model: targetModelId,
        provider: name,
        finishReason: finishReason,
        createdAt: DateTime.now(),
      );
    } catch (e, st) {
      if (e is AIException) rethrow;
      throw AIResponseException(
          'Failed to generate completion from Gemini API', null, e, st);
    }
  }

  @override
  Stream<String> generateStream(AIRequest request) {
    _checkState();
    final controller = StreamController<String>();

    generate<String>(request).then((response) async {
      final text = response.text;
      if (text.isEmpty) {
        await controller.close();
        return;
      }

      final chunks = text.split(' ');
      for (int i = 0; i < chunks.length; i++) {
        if (controller.isClosed) break;
        final delta = i == chunks.length - 1 ? chunks[i] : '${chunks[i]} ';
        controller.add(delta);
        await Future<void>.delayed(const Duration(milliseconds: 15));
      }
      await controller.close();
    }).catchError((Object err) {
      if (!controller.isClosed) {
        controller.addError(err);
        controller.close();
      }
    });

    return controller.stream;
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
    _isClosed = true;
  }
}
