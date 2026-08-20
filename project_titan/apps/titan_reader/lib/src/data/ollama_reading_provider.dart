library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/ai_reading_errors.dart';
import '../domain/ai_reading_prompt_builder.dart';
import '../domain/entities/ai_reading_models.dart';
import 'ai_reading_provider.dart';

/// HTTP Client function signature for injection in tests.
typedef AIHttpFetch = Future<AIHttpResponse> Function(
  Uri uri, {
  Map<String, String>? headers,
  String? body,
});

/// HTTP Stream function signature for injection in tests.
typedef AIHttpStreamingFetch = Stream<String> Function(
  Uri uri, {
  Map<String, String>? headers,
  String? body,
  AICancellationToken? cancelToken,
});

class AIHttpResponse {
  final int statusCode;
  final String body;
  const AIHttpResponse(this.statusCode, this.body);
}

/// Local AI Reading Provider interfacing with Ollama (`http://127.0.0.1:11434`).
class OllamaReadingProvider implements AIReadingProvider {
  final AIHttpFetch _fetch;
  final AIHttpStreamingFetch _streamFetch;
  final AIReadingPromptBuilder _promptBuilder;

  OllamaReadingProvider({
    AIHttpFetch? fetch,
    AIHttpStreamingFetch? streamFetch,
    AIReadingPromptBuilder? promptBuilder,
  })  : _fetch = fetch ?? _defaultFetch,
        _streamFetch = streamFetch ?? _defaultStreamFetch,
        _promptBuilder = promptBuilder ?? const AIReadingPromptBuilder();

  @override
  String get providerId => 'local.ollama';

  @override
  String get displayName => 'Local Ollama';

  @override
  bool get isLocal => true;

  @override
  Future<List<AIModelInfo>> listModels() async {
    try {
      final uri = Uri.parse('http://127.0.0.1:11434/api/tags');
      final res = await _fetch(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, Object?> && decoded['models'] is List) {
          final models = (decoded['models'] as List)
              .whereType<Map<String, Object?>>()
              .map((m) {
            final name = m['name'] as String? ?? 'unknown';
            return AIModelInfo(
              id: name,
              displayName: name,
              providerId: providerId,
              isLocal: true,
              contextWindow: 8192,
            );
          }).toList();
          if (models.isNotEmpty) return models;
        }
      }
    } catch (_) {}
    return const [
      AIModelInfo(
          id: 'llama3.2',
          displayName: 'Llama 3.2 (3B/8B)',
          providerId: 'local.ollama',
          isLocal: true),
      AIModelInfo(
          id: 'qwen2.5:7b',
          displayName: 'Qwen 2.5 7B',
          providerId: 'local.ollama',
          isLocal: true),
      AIModelInfo(
          id: 'mistral',
          displayName: 'Mistral 7B',
          providerId: 'local.ollama',
          isLocal: true),
      AIModelInfo(
          id: 'gemma2',
          displayName: 'Gemma 2',
          providerId: 'local.ollama',
          isLocal: true),
    ];
  }

  @override
  Future<AIReadingResponse> generate(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async {
    final baseUrl = config.ollamaBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/api/generate');

    final systemPrompt = _promptBuilder.buildSystemPrompt(request.task);
    final userPrompt = _promptBuilder.buildUserPrompt(request);

    final payload = jsonEncode({
      'model': config.activeModelId,
      'system': systemPrompt,
      'prompt': userPrompt,
      'stream': false,
      'options': {
        'temperature': config.temperature,
        'num_predict': config.maxTokens,
      },
    });

    try {
      final res = await _fetch(uri,
          headers: {'Content-Type': 'application/json'}, body: payload);
      if (res.statusCode != 200) {
        throw AIResponseInvalidException(
            'Ollama returned status ${res.statusCode}: ${res.body}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, Object?>) {
        throw const AIResponseInvalidException(
            'Ollama response was not a JSON object.');
      }
      final responseText = decoded['response'] as String? ?? '';
      return AIReadingResponse(
        text: responseText,
        task: request.task,
        providerId: providerId,
        modelId: config.activeModelId,
        sources: request.contextChunks,
        createdAt: DateTime.now(),
      );
    } on SocketException catch (e) {
      throw AIProviderUnavailableException(
          'Ollama is not reachable at $baseUrl. Ensure Ollama is running.',
          providerId: providerId,
          cause: e);
    } on TimeoutException catch (e) {
      throw AIRequestTimeoutException('Ollama request timed out.', e);
    } catch (e) {
      if (e is AIReadingException) rethrow;
      throw AINetworkException('Ollama generation failed: $e', e);
    }
  }

  @override
  Stream<String> generateStream(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async* {
    final baseUrl = config.ollamaBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/api/generate');

    final systemPrompt = _promptBuilder.buildSystemPrompt(request.task);
    final userPrompt = _promptBuilder.buildUserPrompt(request);

    final payload = jsonEncode({
      'model': config.activeModelId,
      'system': systemPrompt,
      'prompt': userPrompt,
      'stream': true,
      'options': {
        'temperature': config.temperature,
        'num_predict': config.maxTokens,
      },
    });

    try {
      final stream = _streamFetch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
        cancelToken: cancelToken,
      );

      await for (final line in stream) {
        if (cancelToken?.isCancelled ?? false) break;
        if (line.trim().isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, Object?>) {
            final chunk = decoded['response'] as String?;
            if (chunk != null && chunk.isNotEmpty) {
              yield chunk;
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      if (e is AIReadingException) rethrow;
      throw AINetworkException('Ollama streaming error: $e', e);
    }
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
      if (body != null) {
        req.write(body);
      }
      final res = await req.close().timeout(const Duration(seconds: 45));
      final text = await res.transform(utf8.decoder).join();
      return AIHttpResponse(res.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  static Stream<String> _defaultStreamFetch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
    AICancellationToken? cancelToken,
  }) async* {
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      headers?.forEach((k, v) => req.headers.set(k, v));
      if (body != null) {
        req.write(body);
      }
      final res = await req.close();
      final lines = res.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (cancelToken?.isCancelled ?? false) break;
        yield line;
      }
    } finally {
      client.close(force: true);
    }
  }
}
