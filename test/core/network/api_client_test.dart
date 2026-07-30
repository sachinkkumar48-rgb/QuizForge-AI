import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizforge_upsc/core/config/app_config.dart';
import 'package:quizforge_upsc/core/network/api_client.dart';

void main() {
  group('ApiClient Core Tests', () {
    test('Successful POST returns QuizGenerateResponse', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://161.118.179.119:8000/api/v1/quiz/generate');
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        const responseJson = '''
        {
          "success": true,
          "quiz": [
            {
              "question": "What is the capital of India?",
              "options": ["Mumbai", "New Delhi", "Kolkata", "Chennai"],
              "answer": 1,
              "explanation": "New Delhi is the official capital of India."
            }
          ],
          "processing_time_ms": 1250
        }
        ''';

        return http.Response(responseJson, 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final request = QuizGenerateRequest(
        text: 'The capital of India is New Delhi.',
        questions: 1,
        difficulty: 'easy',
        language: 'en',
      );

      final response = await apiClient.generateQuiz(request);

      expect(response.success, isTrue);
      expect(response.processingTimeMs, equals(1250));
      expect(response.quiz.length, equals(1));
      expect(response.quiz.first.question, equals('What is the capital of India?'));
      expect(response.quiz.first.answer, equals(1));
      expect(response.quiz.first.options, equals(['Mumbai', 'New Delhi', 'Kolkata', 'Chennai']));
    });

    test('Invalid JSON response throws ParsingException without retry', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response('<html>Internal Server Error</html>', 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final request = QuizGenerateRequest(text: 'Test content');

      await expectLater(
        apiClient.generateQuiz(request),
        throwsA(isA<ParsingException>()),
      );
      expect(attempts, equals(1));
    });

    test('Configurable Base URL and AppConfig are respected', () async {
      const customConfig = AppConfig(
        apiBaseUrl: 'http://custom-backend.internal:9000',
        requestTimeout: Duration(seconds: 15),
        maxRetries: 2,
        initialRetryDelay: Duration.zero,
      );

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://custom-backend.internal:9000/api/v1/quiz/generate');
        return http.Response('{"success": true, "quiz": [], "processing_time_ms": 0}', 200);
      });

      final apiClient = ApiClient(config: customConfig, client: mockClient);
      expect(apiClient.baseUrl, equals('http://custom-backend.internal:9000'));
      expect(apiClient.timeoutDuration, equals(const Duration(seconds: 15)));

      final response = await apiClient.generateQuiz(QuizGenerateRequest(text: 'Test'));
      expect(response.success, isTrue);
    });
  });

  group('ApiClient Retry & Transient Failure Tests', () {
    test('Retries up to maxRetries (3 attempts) on HTTP 500 transient failure', () async {
      int attemptCount = 0;
      final mockClient = MockClient((request) async {
        attemptCount++;
        return http.Response('Internal Server Error', 500);
      });

      final fastConfig = const AppConfig(
        maxRetries: 3,
        initialRetryDelay: Duration.zero,
      );

      final apiClient = ApiClient(config: fastConfig, client: mockClient);
      final request = QuizGenerateRequest(text: 'Test content');

      await expectLater(
        apiClient.generateQuiz(request),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
      expect(attemptCount, equals(3));
    });

    test('Retries transient network error and succeeds on 3rd attempt', () async {
      int attemptCount = 0;
      final mockClient = MockClient((request) async {
        attemptCount++;
        if (attemptCount < 3) {
          throw const SocketException('Transient network glitch');
        }
        return http.Response('{"success": true, "quiz": [], "processing_time_ms": 100}', 200);
      });

      final fastConfig = const AppConfig(
        maxRetries: 3,
        initialRetryDelay: Duration.zero,
      );

      final apiClient = ApiClient(config: fastConfig, client: mockClient);
      final response = await apiClient.generateQuiz(QuizGenerateRequest(text: 'Retry Test'));

      expect(response.success, isTrue);
      expect(attemptCount, equals(3));
    });

    test('Retries transient timeout error and succeeds on 2nd attempt', () async {
      int attemptCount = 0;
      final mockClient = MockClient((request) async {
        attemptCount++;
        if (attemptCount == 1) {
          throw TimeoutException('Request timeout');
        }
        return http.Response('{"success": true, "quiz": [], "processing_time_ms": 200}', 200);
      });

      final fastConfig = const AppConfig(
        maxRetries: 3,
        initialRetryDelay: Duration.zero,
      );

      final apiClient = ApiClient(config: fastConfig, client: mockClient);
      final response = await apiClient.generateQuiz(QuizGenerateRequest(text: 'Timeout Retry'));

      expect(response.success, isTrue);
      expect(attemptCount, equals(2));
    });

    test('NO retry on HTTP 4xx client errors (e.g. 400 Bad Request, 401 Unauthorized)', () async {
      int attemptCount = 0;
      final mockClient = MockClient((request) async {
        attemptCount++;
        return http.Response('{"detail": "Bad Request"}', 400);
      });

      final fastConfig = const AppConfig(
        maxRetries: 3,
        initialRetryDelay: Duration.zero,
      );

      final apiClient = ApiClient(config: fastConfig, client: mockClient);

      await expectLater(
        apiClient.generateQuiz(QuizGenerateRequest(text: 'Invalid Request')),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
      expect(attemptCount, equals(1));
    });

    test('NO retry on HTTP 404 Not Found error', () async {
      int attemptCount = 0;
      final mockClient = MockClient((request) async {
        attemptCount++;
        return http.Response('Not Found', 404);
      });

      final fastConfig = const AppConfig(
        maxRetries: 3,
        initialRetryDelay: Duration.zero,
      );

      final apiClient = ApiClient(config: fastConfig, client: mockClient);

      await expectLater(
        apiClient.generateQuiz(QuizGenerateRequest(text: 'Not Found')),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
      expect(attemptCount, equals(1));
    });
  });
}
