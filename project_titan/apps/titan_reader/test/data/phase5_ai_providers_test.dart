import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/ai_reading_provider.dart';
import 'package:titan_reader/src/data/gemini_reading_provider.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/data/ollama_reading_provider.dart';
import 'package:titan_reader/src/data/openai_compatible_reading_provider.dart';
import 'package:titan_reader/src/domain/ai_reading_errors.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';

void main() {
  group('Phase 5: Mock AI Reading Provider', () {
    test('Generates deterministic response and key terms', () async {
      final provider = MockAIReadingProvider();
      const config = AIConfig(activeModelId: 'mock-llama-3');
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Newtonian mechanics describes motion of bodies under forces.',
      );

      final res = await provider.generate(req, config: config);
      expect(res.task, AIReadingTask.explain);
      expect(res.text, contains('Explanation:'));
      expect(res.extractedKeyTerms, isNotEmpty);
      expect(res.providerId, 'mock');
    });

    test('Streams token by token with cancellation support', () async {
      final provider = MockAIReadingProvider(
        scriptedResponse: 'Word1 Word2 Word3 Word4',
      );
      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.simplify,
        text: 'Complex text.',
      );

      final cancelToken = AICancellationToken();
      final chunks = <String>[];

      await for (final chunk in provider.generateStream(req,
          config: config, cancelToken: cancelToken)) {
        chunks.add(chunk);
        if (chunks.length == 2) {
          cancelToken.cancel();
        }
      }

      expect(chunks.length, 2);
      expect(cancelToken.isCancelled, isTrue);
    });

    test('Parses generated flashcards', () async {
      final provider = MockAIReadingProvider();
      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.generateFlashcards,
        text: 'Concept text for flashcard creation.',
      );

      final res = await provider.generate(req, config: config);
      expect(res.flashcards, isNotEmpty);
      expect(res.flashcards.first.front, isNotEmpty);
      expect(res.flashcards.first.back, isNotEmpty);
    });

    test('Throws error when errorToThrow is configured', () async {
      final provider = MockAIReadingProvider(
        errorToThrow: const AIProviderUnavailableException('Service down',
            providerId: 'mock'),
      );
      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.summarize,
        text: 'Text to summarize.',
      );

      expect(
        () => provider.generate(req, config: config),
        throwsA(isA<AIProviderUnavailableException>()),
      );
    });
  });

  group('Phase 5: Ollama Reading Provider', () {
    test('Parses Ollama JSON response successfully', () async {
      final provider = OllamaReadingProvider(
        fetch: (uri, {headers, body}) async {
          return AIHttpResponse(
            200,
            jsonEncode({'response': 'Ollama generated explanation.'}),
          );
        },
      );

      const config = AIConfig(activeModelId: 'llama3.2');
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Target text',
      );

      final res = await provider.generate(req, config: config);
      expect(res.text, 'Ollama generated explanation.');
      expect(res.modelId, 'llama3.2');
    });

    test('Parses NDJSON streaming chunks', () async {
      final provider = OllamaReadingProvider(
        streamFetch: (uri, {headers, body, cancelToken}) async* {
          yield jsonEncode({'response': 'Hello '});
          yield jsonEncode({'response': 'from '});
          yield jsonEncode({'response': 'Ollama!'});
        },
      );

      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Hello world',
      );

      final collected =
          await provider.generateStream(req, config: config).join();
      expect(collected, 'Hello from Ollama!');
    });

    test('Maps SocketException to AIProviderUnavailableException', () async {
      final provider = OllamaReadingProvider(
        fetch: (uri, {headers, body}) async {
          throw const SocketException('Connection refused');
        },
      );

      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Text',
      );

      expect(
        () => provider.generate(req, config: config),
        throwsA(isA<AIProviderUnavailableException>()),
      );
    });
  });

  group('Phase 5: OpenAI-Compatible Reading Provider', () {
    test('Parses Chat Completions standard payload', () async {
      final provider = OpenAICompatibleReadingProvider(
        fetch: (uri, {headers, body}) async {
          return AIHttpResponse(
            200,
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OpenAI completion result.'
                  }
                }
              ]
            }),
          );
        },
      );

      const config = AIConfig(activeModelId: 'gpt-4o-mini');
      const req = AIReadingRequest(
        task: AIReadingTask.summarize,
        text: 'Long document text.',
      );

      final res = await provider.generate(req, config: config);
      expect(res.text, 'OpenAI completion result.');
    });

    test('Maps HTTP 401 to AIAuthenticationException', () async {
      final provider = OpenAICompatibleReadingProvider(
        fetch: (uri, {headers, body}) async {
          return const AIHttpResponse(401, 'Unauthorized');
        },
      );

      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.summarize,
        text: 'Doc',
      );

      expect(
        () => provider.generate(req, config: config),
        throwsA(isA<AIAuthenticationException>()),
      );
    });

    test('Maps HTTP 429 to AIQuotaExceededException', () async {
      final provider = OpenAICompatibleReadingProvider(
        fetch: (uri, {headers, body}) async {
          return const AIHttpResponse(429, 'Rate limit exceeded');
        },
      );

      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.summarize,
        text: 'Doc',
      );

      expect(
        () => provider.generate(req, config: config),
        throwsA(isA<AIQuotaExceededException>()),
      );
    });

    test('Parses SSE data stream', () async {
      final provider = OpenAICompatibleReadingProvider(
        streamFetch: (uri, {headers, body, cancelToken}) async* {
          yield 'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'Chunk 1 '}
                  }
                ]
              })}';
          yield 'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'Chunk 2'}
                  }
                ]
              })}';
          yield 'data: [DONE]';
        },
      );

      const config = AIConfig();
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Text',
      );

      final result = await provider.generateStream(req, config: config).join();
      expect(result, 'Chunk 1 Chunk 2');
    });
  });

  group('Phase 5: Gemini Reading Provider', () {
    test('Requires API key', () async {
      final provider = GeminiReadingProvider();
      const config = AIConfig(geminiApiKey: null);
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Text',
      );

      expect(
        () => provider.generate(req, config: config),
        throwsA(isA<AIAuthenticationException>()),
      );
    });

    test('Parses Gemini generateContent candidate response', () async {
      final provider = GeminiReadingProvider(
        fetch: (uri, {headers, body}) async {
          return AIHttpResponse(
            200,
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Gemini generated insight.'}
                    ]
                  }
                }
              ]
            }),
          );
        },
      );

      const config = AIConfig(geminiApiKey: 'test-gemini-key');
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Text',
      );

      final res = await provider.generate(req, config: config);
      expect(res.text, 'Gemini generated insight.');
      expect(res.providerId, 'gemini');
    });
  });
}
