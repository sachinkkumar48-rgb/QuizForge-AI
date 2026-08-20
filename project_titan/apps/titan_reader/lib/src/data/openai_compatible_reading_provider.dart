library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/ai_reading_errors.dart';
import '../domain/ai_reading_prompt_builder.dart';
import '../domain/entities/ai_reading_models.dart';
import 'ai_reading_provider.dart';
import 'ollama_reading_provider.dart';

/// Provider for local or cloud endpoints supporting the OpenAI Chat Completions specification.
class OpenAICompatibleReadingProvider implements AIReadingProvider {
  final AIHttpFetch _fetch;
  final AIHttpStreamingFetch _streamFetch;
  final AIReadingPromptBuilder _promptBuilder;

  OpenAICompatibleReadingProvider({
    AIHttpFetch? fetch,
    AIHttpStreamingFetch? streamFetch,
    AIReadingPromptBuilder? promptBuilder,
  })  : _fetch = fetch ?? _defaultFetch,
        _streamFetch = streamFetch ?? _defaultStreamFetch,
        _promptBuilder = promptBuilder ?? const AIReadingPromptBuilder();

  @override
  String get providerId => 'openai_compatible';

  @override
  String get displayName => 'OpenAI-Compatible Server';

  @override
  bool get isLocal => false;

  @override
  Future<List<AIModelInfo>> listModels() async {
    return const [
      AIModelInfo(
          id: 'gpt-4o-mini',
          displayName: 'GPT-4o Mini',
          providerId: 'openai_compatible',
          isLocal: false),
      AIModelInfo(
          id: 'local-model',
          displayName: 'Local OpenAI Model',
          providerId: 'openai_compatible',
          isLocal: true),
      AIModelInfo(
          id: 'qwen-2.5',
          displayName: 'Qwen 2.5',
          providerId: 'openai_compatible',
          isLocal: true),
    ];
  }

  @override
  Future<AIReadingResponse> generate(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async {
    final baseUrl = config.openAIBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/chat/completions');

    final systemPrompt = _promptBuilder.buildSystemPrompt(request.task);
    final userPrompt = _promptBuilder.buildUserPrompt(request);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.openAIApiKey != null && config.openAIApiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.openAIApiKey!.trim()}';
    }

    final payload = jsonEncode({
      'model': config.activeModelId,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'stream': false,
    });

    try {
      final res = await _fetch(uri, headers: headers, body: payload);
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw const AIAuthenticationException('Invalid or missing API key.');
      }
      if (res.statusCode == 429) {
        throw const AIQuotaExceededException(
            'Rate limit or token quota exceeded.');
      }
      if (res.statusCode != 200) {
        throw AIResponseInvalidException(
            'OpenAI-compatible server returned ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, Object?>) {
        throw const AIResponseInvalidException('Malformed JSON response.');
      }
      final choices = decoded['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const AIResponseInvalidException('No choices returned by model.');
      }
      final first = choices.first as Map<String, Object?>;
      final message = first['message'] as Map<String, Object?>?;
      final content = message?['content'] as String? ?? '';

      return AIReadingResponse(
        text: content,
        task: request.task,
        providerId: providerId,
        modelId: config.activeModelId,
        sources: request.contextChunks,
        createdAt: DateTime.now(),
      );
    } on SocketException catch (e) {
      throw AIProviderUnavailableException('Server unreachable at $baseUrl.',
          providerId: providerId, cause: e);
    } on TimeoutException catch (e) {
      throw AIRequestTimeoutException('Request timed out.', e);
    } catch (e) {
      if (e is AIReadingException) rethrow;
      throw AINetworkException('Request failed: $e', e);
    }
  }

  @override
  Stream<String> generateStream(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async* {
    final baseUrl = config.openAIBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/chat/completions');

    final systemPrompt = _promptBuilder.buildSystemPrompt(request.task);
    final userPrompt = _promptBuilder.buildUserPrompt(request);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.openAIApiKey != null && config.openAIApiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.openAIApiKey!.trim()}';
    }

    final payload = jsonEncode({
      'model': config.activeModelId,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'stream': true,
    });

    try {
      final stream = _streamFetch(uri,
          headers: headers, body: payload, cancelToken: cancelToken);
      await for (final line in stream) {
        if (cancelToken?.isCancelled ?? false) break;
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data == '[DONE]') break;
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, Object?>) {
            final choices = decoded['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = (choices.first as Map<String, Object?>)['delta']
                  as Map<String, Object?>?;
              final text = delta?['content'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      if (e is AIReadingException) rethrow;
      throw AINetworkException('OpenAI streaming error: $e', e);
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
      if (body != null) req.write(body);
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
      if (body != null) req.write(body);
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
