import 'dart:convert';
import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/quiz_generation_request.dart';

/// Service converting raw AI JSON strings or decoded maps into Quiz domain models.
class QuizJsonParser {
  const QuizJsonParser();

  /// Extracts and decodes JSON map from raw AI output string [rawText].
  Map<String, dynamic> extractJsonMap(String rawText) {
    if (rawText.trim().isEmpty) {
      throw const JsonParsingException('Raw AI response text is empty.');
    }

    var cleanText = rawText.trim();

    // Strip markdown code block fences if present (```json ... ``` or ``` ... ```)
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

    // Locate first '{' and last '}'
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
            'Decoded AI JSON is not a JSON object map.');
      }
      return decoded;
    } catch (e, st) {
      if (e is JsonParsingException) rethrow;
      throw JsonParsingException(
          'Failed to parse JSON string: ${e.toString()}', e, st);
    }
  }

  /// Converts a decoded JSON [map] into a complete [Quiz] domain object.
  Quiz parseQuiz({
    required Map<String, dynamic> map,
    required QuizGenerationRequest request,
  }) {
    try {
      final title = map['title'] as String? ?? 'AI Generated Quiz';
      final description = map['description'] as String? ??
          'Generated from document ${request.documentId}';
      final rawQuestions = map['questions'] as List<dynamic>? ?? const [];

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final quizId = QuizUtils.generateQuizId();

      final parsedQuestions = <QuizQuestion>[];

      for (var i = 0; i < rawQuestions.length; i++) {
        final qMap = rawQuestions[i] as Map<String, dynamic>;
        final qText = qMap['question'] as String? ?? '';
        final qExplanation = qMap['explanation'] as String?;
        final qTopic = qMap['topic'] as String?;
        final qSubtopic = qMap['subtopic'] as String?;
        final pageRef = qMap['pageReference'] as int?;

        final diffStr = qMap['difficulty'] as String?;
        final questionDifficulty =
            _parseDifficulty(diffStr, fallback: request.difficulty);

        final rawOptions = qMap['options'] as List<dynamic>? ?? const [];
        final rawCorrectAns = qMap['correctAnswer'];

        int correctIndex = 0;

        final optionTexts = rawOptions.map((o) {
          if (o is String) return o.trim();
          if (o is Map) return (o['text'] ?? '').toString().trim();
          return o.toString().trim();
        }).toList();

        if (rawCorrectAns is num) {
          correctIndex = rawCorrectAns
              .toInt()
              .clamp(0, optionTexts.isEmpty ? 0 : optionTexts.length - 1);
        } else if (rawCorrectAns is String) {
          final trimmed = rawCorrectAns.trim();
          final foundIdx = optionTexts.indexOf(trimmed);
          if (foundIdx != -1) {
            correctIndex = foundIdx;
          }
        }

        final options = <QuizOption>[];
        for (var j = 0; j < optionTexts.length; j++) {
          options.add(QuizOption(
            id: 'opt_${i + 1}_${j + 1}_$timestamp',
            text: optionTexts[j],
            isCorrect: j == correctIndex,
          ));
        }

        // Set marks & negativeMarks based on Category defaults (e.g. UPSC: 2.0 / 0.66)
        final marks = (qMap['marks'] as num?)?.toDouble() ??
            _defaultMarksForCategory(request.category);
        final negativeMarks = (qMap['negativeMarks'] as num?)?.toDouble() ??
            _defaultNegativeMarksForCategory(request.category);

        parsedQuestions.add(QuizQuestion(
          id: 'q_${i + 1}_$timestamp',
          question: qText,
          options: options,
          correctAnswerIndex: correctIndex,
          explanation: qExplanation,
          difficulty: questionDifficulty,
          topic: qTopic,
          subtopic: qSubtopic,
          pageReference: pageRef,
          marks: marks,
          negativeMarks: negativeMarks,
        ));
      }

      final metadata = QuizMetadata(
        totalQuestions: parsedQuestions.length,
        estimatedDurationMinutes:
            QuizUtils.estimateDurationMinutes(parsedQuestions.length),
        generatedBy: 'TITAN AI Quiz Pipeline',
        version: '1.0.0',
        tags: [
          request.category.name,
          request.difficulty.name,
          request.language.name
        ],
      );

      return Quiz(
        id: quizId,
        title: title,
        description: description,
        sourceDocumentId: request.documentId,
        difficulty: request.difficulty,
        language: request.language,
        category: request.category,
        questions: parsedQuestions,
        metadata: metadata,
      );
    } catch (e, st) {
      if (e is QuizGenerationException) rethrow;
      throw JsonParsingException(
          'Error mapping JSON to Quiz entity: ${e.toString()}', e, st);
    }
  }

  QuizDifficulty _parseDifficulty(String? val,
      {required QuizDifficulty fallback}) {
    if (val == null) return fallback;
    final clean = val.toLowerCase().trim();
    return QuizDifficulty.values.firstWhere(
      (QuizDifficulty d) => d.name.toLowerCase() == clean,
      orElse: () => fallback,
    );
  }

  double _defaultMarksForCategory(QuizCategory category) {
    switch (category) {
      case QuizCategory.upsc:
      case QuizCategory.bpsc:
        return 2.0;
      case QuizCategory.ssc:
      case QuizCategory.banking:
      case QuizCategory.railway:
      case QuizCategory.custom:
        return 1.0;
    }
  }

  double _defaultNegativeMarksForCategory(QuizCategory category) {
    switch (category) {
      case QuizCategory.upsc:
      case QuizCategory.bpsc:
        return 0.66;
      case QuizCategory.ssc:
      case QuizCategory.banking:
      case QuizCategory.railway:
      case QuizCategory.custom:
        return 0.33;
    }
  }
}
