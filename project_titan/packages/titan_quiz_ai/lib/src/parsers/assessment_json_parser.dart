import 'dart:convert';
import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/assessment_generation_request.dart';
import '../models/assessment_question_type.dart';
import '../models/assessment_source.dart';
import '../models/generated_question.dart';

/// Service responsible for extracting and parsing raw AI output into strongly typed [GeneratedQuestion] entities.
class AssessmentJsonParser {
  const AssessmentJsonParser();

  /// Extracts and decodes the root JSON map from raw LLM output text.
  Map<String, dynamic> extractJsonMap(String rawText) {
    if (rawText.trim().isEmpty) {
      throw const JsonParsingException('Raw AI response text is empty.');
    }

    var cleanText = rawText.trim();

    // Strip markdown code block fences if present
    if (cleanText.startsWith('```')) {
      final lines = cleanText.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      cleanText = lines.join('\n').trim();
    }

    final startIdx = cleanText.indexOf('{');
    final endIdx = cleanText.lastIndexOf('}');

    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      throw JsonParsingException(
          'Could not locate valid JSON object in AI response:\n"$rawText"');
    }

    final jsonSubstr = cleanText.substring(startIdx, endIdx + 1);

    try {
      final decoded = json.decode(jsonSubstr);
      if (decoded is! Map<String, dynamic>) {
        throw const JsonParsingException(
            'Decoded AI JSON is not a valid JSON object map.');
      }
      return decoded;
    } catch (e, st) {
      if (e is JsonParsingException) rethrow;
      throw JsonParsingException(
          'Failed to parse assessment JSON string: ${e.toString()}', e, st);
    }
  }

  /// Parses questions from decoded [map] into a list of [GeneratedQuestion]s.
  List<GeneratedQuestion> parseQuestions({
    required Map<String, dynamic> map,
    required AssessmentGenerationRequest request,
  }) {
    final rawQuestions = map['questions'] as List<dynamic>? ?? const [];
    final questions = <GeneratedQuestion>[];

    // Lookup map for fast source grounding resolution
    final sourceMap = <String, AssessmentSource>{
      for (final src in request.sources) src.chunkId: src,
    };
    final defaultSource =
        request.sources.isNotEmpty ? request.sources.first : null;

    for (var i = 0; i < rawQuestions.length; i++) {
      final qItem = rawQuestions[i];
      if (qItem is! Map<String, dynamic>) continue;

      final questionText = qItem['question']?.toString().trim() ?? '';
      if (questionText.isEmpty) continue;

      // Question Type
      final typeCode = qItem['type']?.toString() ?? 'mcq';
      final questionType = AssessmentQuestionType.fromCode(typeCode);

      // Options
      final optionsRaw = qItem['options'] as List<dynamic>? ?? const [];
      final options = <String>[];
      for (final opt in optionsRaw) {
        if (opt is String && opt.trim().isNotEmpty) {
          options.add(opt.trim());
        } else if (opt is Map && opt['text'] != null) {
          options.add(opt['text'].toString().trim());
        }
      }

      if (options.length < 2) continue;

      // Correct answers
      final correctAnswers = _extractCorrectAnswerIndices(qItem, options);
      if (correctAnswers.isEmpty) continue;

      // Source chunk and page resolution
      var sourceChunkId = qItem['sourceChunkId']?.toString().trim() ?? '';
      var pageNumber = qItem['pageNumber'] is num
          ? (qItem['pageNumber'] as num).toInt()
          : (defaultSource?.pageNumber ?? 1);

      if (sourceChunkId.isNotEmpty && sourceMap.containsKey(sourceChunkId)) {
        pageNumber = sourceMap[sourceChunkId]!.pageNumber;
      } else if (defaultSource != null) {
        sourceChunkId = defaultSource.chunkId;
        pageNumber = defaultSource.pageNumber;
      }

      final explanation = qItem['explanation']?.toString().trim();
      final topic =
          qItem['topic']?.toString().trim() ?? request.blueprint.topicHint;
      final diffStr = qItem['difficulty']?.toString().trim().toLowerCase();
      final difficulty =
          _parseDifficulty(diffStr, request.blueprint.difficulty);

      final questionId = 'gq_${QuizUtils.generateQuizId()}_$i';

      final metadata = QuestionGenerationMetadata(
        sourceDocumentId: request.blueprint.documentId,
        sourceChunkId: sourceChunkId,
        pageNumber: pageNumber,
        questionType: questionType,
        confidenceScore: 1.0,
        isGroundingVerified: sourceMap.containsKey(sourceChunkId),
      );

      questions.add(
        GeneratedQuestion(
          id: questionId,
          questionText: questionText,
          options: options,
          correctAnswers: correctAnswers,
          explanation: explanation,
          difficulty: difficulty,
          topic: topic,
          metadata: metadata,
        ),
      );
    }

    return List.unmodifiable(questions);
  }

  List<int> _extractCorrectAnswerIndices(
    Map<String, dynamic> qItem,
    List<String> options,
  ) {
    final indices = <int>[];

    // Check "correctAnswers" array first
    final multiAnswers = qItem['correctAnswers'];
    if (multiAnswers is List) {
      for (final a in multiAnswers) {
        if (a is num) {
          final idx = a.toInt();
          if (idx >= 0 && idx < options.length && !indices.contains(idx)) {
            indices.add(idx);
          }
        } else if (a is String) {
          final trimmed = a.trim();
          final matchIdx = options.indexOf(trimmed);
          if (matchIdx != -1 && !indices.contains(matchIdx)) {
            indices.add(matchIdx);
          }
        }
      }
    }

    // Fallback to "correctAnswer"
    if (indices.isEmpty) {
      final singleAnswer = qItem['correctAnswer'];
      if (singleAnswer is num) {
        final idx = singleAnswer.toInt();
        if (idx >= 0 && idx < options.length) {
          indices.add(idx);
        }
      } else if (singleAnswer is String) {
        final matchIdx = options.indexOf(singleAnswer.trim());
        if (matchIdx != -1) {
          indices.add(matchIdx);
        }
      }
    }

    return indices;
  }

  QuizDifficulty _parseDifficulty(String? diffStr, QuizDifficulty fallback) {
    switch (diffStr) {
      case 'easy':
        return QuizDifficulty.easy;
      case 'medium':
        return QuizDifficulty.medium;
      case 'hard':
        return QuizDifficulty.hard;
      default:
        return fallback == QuizDifficulty.mixed
            ? QuizDifficulty.medium
            : fallback;
    }
  }
}
