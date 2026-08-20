library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/ai_reading_errors.dart';
import '../domain/ai_reading_prompt_builder.dart';
import '../domain/entities/ai_reading_models.dart';
import 'ai_reading_provider.dart';
import 'ollama_reading_provider.dart';

/// Provider connecting directly to Google Gemini REST API.
class GeminiReadingProvider implements AIReadingProvider {
  final AIHttpFetch _fetch;
  final AIReadingPromptBuilder _promptBuilder;

  GeminiReadingProvider({
    AIHttpFetch? fetch,
    AIReadingPromptBuilder? promptBuilder,
  })  : _fetch = fetch ?? _defaultFetch,
        _promptBuilder = promptBuilder ?? const AIReadingPromptBuilder();

  @override
  String get providerId => 'gemini';

  @override
  String get displayName => 'Google Gemini';

  @override
  bool get isLocal => false;

  @override
  Future<List<AIModelInfo>> listModels() async {
    return const [
      AIModelInfo(
          id: 'gemini-1.5-flash',
          displayName: 'Gemini 1.5 Flash (Fast)',
          providerId: 'gemini',
          isLocal: false),
      AIModelInfo(
          id: 'gemini-1.5-pro',
          displayName: 'Gemini 1.5 Pro (Deep Reasoning)',
          providerId: 'gemini',
          isLocal: false),
    ];
  }

  @override
  Future<AIReadingResponse> generate(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async {
    final apiKey = config.geminiApiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIAuthenticationException(
          'Gemini API key is required but not configured.');
    }

    final model = config.activeModelId.contains('gemini')
        ? config.activeModelId
        : 'gemini-1.5-flash';
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final systemPrompt = _promptBuilder.buildSystemPrompt(request.task);
    final userPrompt = _promptBuilder.buildUserPrompt(request);

    final payload = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': config.temperature,
        'maxOutputTokens': config.maxTokens,
      }
    });

    try {
      final res = await _fetch(uri,
          headers: {'Content-Type': 'application/json'}, body: payload);
      if (res.statusCode == 400 || res.statusCode == 403) {
        throw const AIAuthenticationException(
            'Invalid Gemini API Key or project permissions.');
      }
      if (res.statusCode == 429) {
        throw const AIQuotaExceededException('Gemini rate limit exceeded.');
      }
      if (res.statusCode != 200) {
        throw AIResponseInvalidException(
            'Gemini API returned status ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, Object?>) {
        throw const AIResponseInvalidException(
            'Malformed JSON response from Gemini.');
      }

      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const AIResponseInvalidException(
            'No response candidates returned by Gemini.');
      }

      final first = candidates.first as Map<String, Object?>;
      final content = first['content'] as Map<String, Object?>?;
      final parts = content?['parts'] as List?;
      final textPart = parts?.first as Map<String, Object?>?;
      final text = textPart?['text'] as String? ?? '';

      return AIReadingResponse(
        text: text,
        task: request.task,
        providerId: providerId,
        modelId: model,
        sources: request.contextChunks,
        createdAt: DateTime.now(),
      );
    } on SocketException catch (e) {
      throw AINetworkException('Gemini service unreachable.', e);
    } on TimeoutException catch (e) {
      throw AIRequestTimeoutException('Gemini request timed out.', e);
    } catch (e) {
      if (e is AIReadingException) rethrow;
      throw AINetworkException('Gemini generation failed: $e', e);
    }
  }

  @override
  Stream<String> generateStream(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async* {
    // Non-streaming fallback for Gemini REST
    final response =
        await generate(request, config: config, cancelToken: cancelToken);
    yield response.text;
  }

  static Future<AIHttpResponse> _defaultFetch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final client = HttpClient();
    try {
      final req =
          await client.postUrl(uri).timeout(const Duration(seconds: 45));
      headers?.forEach((k, v) => req.headers.set(k, v));
      if (body != null) req.write(body);
      final res = await req.close().timeout(const Duration(seconds: 45));
      final text = await res.transform(utf8.decoder).join();
      return AIHttpResponse(res.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }
}
