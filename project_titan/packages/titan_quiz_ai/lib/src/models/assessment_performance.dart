import 'package:meta/meta.dart';
import 'assessment_question_type.dart';

/// Immutable model representing deterministic performance analysis of an assessment session.
@immutable
class AssessmentPerformance {
  final int totalQuestions;
  final int answeredQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredQuestions;
  final double score;
  final double maxScore;
  final double percentage;
  final Map<AssessmentQuestionType, double> accuracyByType;
  final Map<String, double> accuracyByTopic;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final List<String> reviewQuestionIds;
  final List<String> incorrectQuestionIds;
  final List<String> unansweredQuestionIds;

  AssessmentPerformance({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    required this.score,
    required this.maxScore,
    required this.percentage,
    Map<AssessmentQuestionType, double>? accuracyByType,
    Map<String, double>? accuracyByTopic,
    List<String>? weakTopics,
    List<String>? strongTopics,
    List<String>? reviewQuestionIds,
    List<String>? incorrectQuestionIds,
    List<String>? unansweredQuestionIds,
  })  : accuracyByType = Map.unmodifiable(accuracyByType ?? const {}),
        accuracyByTopic = Map.unmodifiable(accuracyByTopic ?? const {}),
        weakTopics = List.unmodifiable(weakTopics ?? const []),
        strongTopics = List.unmodifiable(strongTopics ?? const []),
        reviewQuestionIds = List.unmodifiable(reviewQuestionIds ?? const []),
        incorrectQuestionIds =
            List.unmodifiable(incorrectQuestionIds ?? const []),
        unansweredQuestionIds =
            List.unmodifiable(unansweredQuestionIds ?? const []);

  const AssessmentPerformance.constPerformance({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.accuracyByType,
    required this.accuracyByTopic,
    required this.weakTopics,
    required this.strongTopics,
    required this.reviewQuestionIds,
    required this.incorrectQuestionIds,
    required this.unansweredQuestionIds,
  });

  bool get hasWeakTopics => weakTopics.isNotEmpty;
  bool get hasIncorrectQuestions => incorrectQuestionIds.isNotEmpty;
  bool get hasUnansweredQuestions => unansweredQuestionIds.isNotEmpty;
  bool get hasReviewQuestions => reviewQuestionIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentPerformance &&
          runtimeType == other.runtimeType &&
          totalQuestions == other.totalQuestions &&
          correctAnswers == other.correctAnswers &&
          incorrectAnswers == other.incorrectAnswers &&
          score == other.score &&
          percentage == other.percentage;

  @override
  int get hashCode => Object.hash(
        totalQuestions,
        correctAnswers,
        incorrectAnswers,
        score,
        percentage,
      );
}
