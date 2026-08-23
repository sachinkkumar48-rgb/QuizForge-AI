import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'assessment_question_type.dart';

/// Immutable model representing metadata about how and from where a question was generated.
@immutable
class QuestionGenerationMetadata {
  final String sourceDocumentId;
  final String sourceChunkId;
  final int pageNumber;
  final AssessmentQuestionType questionType;
  final double confidenceScore;
  final bool isGroundingVerified;

  const QuestionGenerationMetadata({
    required this.sourceDocumentId,
    required this.sourceChunkId,
    required this.pageNumber,
    this.questionType = AssessmentQuestionType.mcq,
    this.confidenceScore = 1.0,
    this.isGroundingVerified = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionGenerationMetadata &&
          runtimeType == other.runtimeType &&
          sourceDocumentId == other.sourceDocumentId &&
          sourceChunkId == other.sourceChunkId &&
          pageNumber == other.pageNumber &&
          questionType == other.questionType &&
          confidenceScore == other.confidenceScore &&
          isGroundingVerified == other.isGroundingVerified;

  @override
  int get hashCode => Object.hash(
        sourceDocumentId,
        sourceChunkId,
        pageNumber,
        questionType,
        confidenceScore,
        isGroundingVerified,
      );
}

/// Immutable model representing a generated question before conversion to the legacy Quiz entity.
@immutable
class GeneratedQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final List<int> correctAnswers;
  final String? explanation;
  final QuizDifficulty difficulty;
  final String? topic;
  final String? subtopic;
  final QuestionGenerationMetadata metadata;

  GeneratedQuestion({
    required this.id,
    required this.questionText,
    required List<String> options,
    required List<int> correctAnswers,
    this.explanation,
    this.difficulty = QuizDifficulty.medium,
    this.topic,
    this.subtopic,
    required this.metadata,
  })  : options = List.unmodifiable(options),
        correctAnswers = List.unmodifiable(correctAnswers);

  const GeneratedQuestion.constQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswers,
    required this.explanation,
    required this.difficulty,
    required this.topic,
    required this.subtopic,
    required this.metadata,
  });

  /// Primary 0-based index of the first correct answer for backward compatibility with single-choice models.
  int get primaryCorrectAnswerIndex =>
      correctAnswers.isNotEmpty ? correctAnswers.first : 0;

  /// Converts this [GeneratedQuestion] to the canonical [QuizQuestion] entity used across QuizForge UI.
  QuizQuestion toQuizQuestion(
      {double marks = 1.0, double negativeMarks = 0.33}) {
    final quizOptions = <QuizOption>[];
    for (var i = 0; i < options.length; i++) {
      quizOptions.add(
        QuizOption(
          id: 'opt_${id}_$i',
          text: options[i],
        ),
      );
    }

    return QuizQuestion(
      id: id,
      question: questionText,
      options: quizOptions,
      correctAnswerIndex: primaryCorrectAnswerIndex,
      explanation: explanation,
      difficulty: difficulty,
      topic: topic,
      subtopic: subtopic,
      pageReference: metadata.pageNumber,
      marks: marks,
      negativeMarks: negativeMarks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionText == other.questionText &&
          explanation == other.explanation &&
          difficulty == other.difficulty &&
          topic == other.topic &&
          subtopic == other.subtopic &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(
        id,
        questionText,
        Object.hashAll(options),
        Object.hashAll(correctAnswers),
        explanation,
        difficulty,
        topic,
        subtopic,
        metadata,
      );
}
