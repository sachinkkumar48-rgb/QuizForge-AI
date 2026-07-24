import 'package:meta/meta.dart';
import '../enums/quiz_difficulty.dart';
import 'quiz_option.dart';

/// Immutable model representing a single question within a quiz.
@immutable
class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;
  final int correctAnswerIndex;
  final String? explanation;
  final QuizDifficulty difficulty;
  final String? topic;
  final String? subtopic;
  final int? pageReference;
  final double marks;
  final double negativeMarks;

  QuizQuestion({
    required this.id,
    required this.question,
    required List<QuizOption> options,
    required this.correctAnswerIndex,
    this.explanation,
    this.difficulty = QuizDifficulty.medium,
    this.topic,
    this.subtopic,
    this.pageReference,
    this.marks = 1.0,
    this.negativeMarks = 0.33,
  }) : options = List<QuizOption>.unmodifiable(options);

  const QuizQuestion.constQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.difficulty,
    required this.topic,
    required this.subtopic,
    required this.pageReference,
    required this.marks,
    required this.negativeMarks,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizQuestion || runtimeType != other.runtimeType) {
      return false;
    }
    if (id != other.id ||
        question != other.question ||
        correctAnswerIndex != other.correctAnswerIndex ||
        explanation != other.explanation ||
        difficulty != other.difficulty ||
        topic != other.topic ||
        subtopic != other.subtopic ||
        pageReference != other.pageReference ||
        marks != other.marks ||
        negativeMarks != other.negativeMarks) {
      return false;
    }
    if (options.length != other.options.length) {
      return false;
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i] != other.options[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        question,
        Object.hashAll(options),
        correctAnswerIndex,
        explanation,
        difficulty,
        topic,
        subtopic,
        pageReference,
        marks,
        negativeMarks,
      );

  @override
  String toString() =>
      'QuizQuestion($id: "$question", options: ${options.length}, correctIndex: $correctAnswerIndex)';
}
