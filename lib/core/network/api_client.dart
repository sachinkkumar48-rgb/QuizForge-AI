import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Exception thrown when the backend server is unreachable or the request times out.
class BackendUnavailableException implements Exception {
  final String message;

  BackendUnavailableException([this.message = 'Backend service unavailable or unreachable.']);

  @override
  String toString() => 'BackendUnavailableException: $message';
}

/// Exception thrown when parsing backend JSON response fails or response schema is invalid.
class ParsingException implements Exception {
  final String message;

  ParsingException([this.message = 'Failed to parse JSON response.']);

  @override
  String toString() => 'ParsingException: $message';
}

/// Exception thrown when API returns an HTTP error status (e.g. 500 Internal Server Error).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, [this.message = 'API error occurred.']);

  @override
  String toString() => 'ApiException ($statusCode): $message';
}

/// Model representing a request to generate a quiz.
class QuizGenerateRequest {
  final String text;
  final int questions;
  final String difficulty;
  final String language;

  QuizGenerateRequest({
    required this.text,
    this.questions = 10,
    this.difficulty = 'medium',
    this.language = 'en',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'questions': questions,
      'difficulty': difficulty,
      'language': language,
    };
  }
}

/// Model representing a backend API generated quiz question.
class ApiQuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  ApiQuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory ApiQuizQuestion.fromJson(Map<String, dynamic> json) {
    return ApiQuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      answer: (json['answer'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'answer': answer,
      'explanation': explanation,
    };
  }
}

/// Alias for backward compatibility with QuizQuestion in network layer.
typedef QuizQuestion = ApiQuizQuestion;

/// Model representing the response from the quiz generation API.
class QuizGenerateResponse {
  final bool success;
  final List<ApiQuizQuestion> quiz;
  final int processingTimeMs;

  QuizGenerateResponse({
    required this.success,
    required this.quiz,
    required this.processingTimeMs,
  });

  factory QuizGenerateResponse.fromJson(Map<String, dynamic> json) {
    final quizList = json['quiz'];
    if (quizList is! List) {
      throw const FormatException("Missing or invalid 'quiz' field in response");
    }

    return QuizGenerateResponse(
      success: json['success'] as bool? ?? false,
      quiz: quizList
          .map((e) => ApiQuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'quiz': quiz.map((q) => q.toJson()).toList(),
      'processing_time_ms': processingTimeMs,
    };
  }
}

/// Reusable FastAPI client for Project TITAN.
class ApiClient {
  final AppConfig config;
  final http.Client _client;

  ApiClient({
    AppConfig? config,
    String? baseUrl,
    http.Client? client,
    Duration? timeoutDuration,
  })  : config = config ??
            AppConfig(
              apiBaseUrl: baseUrl ?? AppConfig.defaultConfig.apiBaseUrl,
              requestTimeout: timeoutDuration ?? AppConfig.defaultConfig.requestTimeout,
            ),
        _client = client ?? http.Client();

  String get baseUrl => config.apiBaseUrl;
  Duration get timeoutDuration => config.requestTimeout;

  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000));
    return 'req_${timestamp}_$random';
  }

  /// Generates a quiz by sending a POST request to /api/v1/quiz/generate
  Future<QuizGenerateResponse> generateQuiz(QuizGenerateRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/quiz/generate');
    final requestId = _generateRequestId();
    final headers = {
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
    };
    final body = jsonEncode(request.toJson());

    final maxAttempts = config.maxRetries > 0 ? config.maxRetries : 1;
    Object? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final stopwatch = Stopwatch()..start();
      AppLogger.info(
        'POST $url (attempt $attempt/$maxAttempts) [Request ID: $requestId]',
        tag: 'ApiClient',
      );

      try {
        final response = await _client
            .post(
              url,
              headers: headers,
              body: body,
            )
            .timeout(timeoutDuration);

        stopwatch.stop();
        final durationMs = stopwatch.elapsedMilliseconds;
        final responseRequestId =
            response.headers['x-request-id'] ?? response.headers['X-Request-ID'] ?? requestId;

        AppLogger.info(
          'HTTP ${response.statusCode} POST $url (${durationMs}ms) [Request ID: $responseRequestId]',
          tag: 'ApiClient',
        );

        // HTTP 4xx: Client error (non-transient) -> DO NOT RETRY
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw ApiException(
            response.statusCode,
            'HTTP ${response.statusCode}: ${response.body}',
          );
        }

        // HTTP 5xx: Server error (transient) -> Retry
        if (response.statusCode >= 500) {
          throw ApiException(
            response.statusCode,
            'HTTP ${response.statusCode} Internal Server Error: ${response.body}',
          );
        }

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Expected JSON object in response body');
          }
          return QuizGenerateResponse.fromJson(decoded);
        } catch (e) {
          throw ParsingException('Invalid JSON or response schema error: $e');
        }
      } on ApiException catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'API Error ${e.statusCode} during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: ${e.message}',
          error: e,
          tag: 'ApiClient',
        );
        if (e.statusCode >= 400 && e.statusCode < 500) {
          rethrow;
        }
        lastError = e;
      } on ParsingException catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'Parsing Error during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: ${e.message}',
          error: e,
          tag: 'ApiClient',
        );
        rethrow;
      } on TimeoutException catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'Timeout during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: ${e.message}',
          error: e,
          tag: 'ApiClient',
        );
        lastError = BackendUnavailableException('Request timed out: ${e.message}');
      } on SocketException catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'SocketException during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: ${e.message}',
          error: e,
          tag: 'ApiClient',
        );
        lastError = BackendUnavailableException('Network unavailable or host unreachable: ${e.message}');
      } on http.ClientException catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'ClientException during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: ${e.message}',
          error: e,
          tag: 'ApiClient',
        );
        lastError = BackendUnavailableException('HTTP Client error: ${e.message}');
      } catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'Error during POST $url (${stopwatch.elapsedMilliseconds}ms) [Request ID: $requestId]: $e',
          error: e,
          tag: 'ApiClient',
        );
        if (e is BackendUnavailableException || e is ApiException || e is ParsingException) {
          if (e is ApiException && e.statusCode >= 400 && e.statusCode < 500) {
            rethrow;
          }
          lastError = e;
        } else {
          lastError = BackendUnavailableException('Backend communication failed: $e');
        }
      }

      if (attempt < maxAttempts) {
        final delayMs = config.initialRetryDelay.inMilliseconds * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw BackendUnavailableException('Request failed after $maxAttempts attempts.');
  }

  void close() {
    _client.close();
  }
}
