import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'assessment_blueprint.dart';

/// Immutable domain model specifying the deterministic strategy and blueprint for an adaptive assessment.
@immutable
class AdaptiveAssessmentPlan {
  final QuizDifficulty recommendedDifficulty;
  final List<String> targetTopics;
  final int questionCount;
  final List<String> retryQuestionIds;
  final List<String> remedialTopics;
  final List<String> sourceChunks;
  final String rationale;
  final double confidence;
  final AssessmentBlueprint blueprint;

  AdaptiveAssessmentPlan({
    required this.recommendedDifficulty,
    List<String>? targetTopics,
    required this.questionCount,
    List<String>? retryQuestionIds,
    List<String>? remedialTopics,
    List<String>? sourceChunks,
    required this.rationale,
    this.confidence = 1.0,
    required this.blueprint,
  })  : targetTopics = List.unmodifiable(targetTopics ?? const []),
        retryQuestionIds = List.unmodifiable(retryQuestionIds ?? const []),
        remedialTopics = List.unmodifiable(remedialTopics ?? const []),
        sourceChunks = List.unmodifiable(sourceChunks ?? const []);

  const AdaptiveAssessmentPlan.constPlan({
    required this.recommendedDifficulty,
    required this.targetTopics,
    required this.questionCount,
    required this.retryQuestionIds,
    required this.remedialTopics,
    required this.sourceChunks,
    required this.rationale,
    required this.confidence,
    required this.blueprint,
  });

  AdaptiveAssessmentPlan copyWith({
    QuizDifficulty? recommendedDifficulty,
    List<String>? targetTopics,
    int? questionCount,
    List<String>? retryQuestionIds,
    List<String>? remedialTopics,
    List<String>? sourceChunks,
    String? rationale,
    double? confidence,
    AssessmentBlueprint? blueprint,
  }) {
    return AdaptiveAssessmentPlan(
      recommendedDifficulty:
          recommendedDifficulty ?? this.recommendedDifficulty,
      targetTopics: targetTopics ?? this.targetTopics,
      questionCount: questionCount ?? this.questionCount,
      retryQuestionIds: retryQuestionIds ?? this.retryQuestionIds,
      remedialTopics: remedialTopics ?? this.remedialTopics,
      sourceChunks: sourceChunks ?? this.sourceChunks,
      rationale: rationale ?? this.rationale,
      confidence: confidence ?? this.confidence,
      blueprint: blueprint ?? this.blueprint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveAssessmentPlan &&
          runtimeType == other.runtimeType &&
          recommendedDifficulty == other.recommendedDifficulty &&
          questionCount == other.questionCount &&
          rationale == other.rationale &&
          blueprint == other.blueprint;

  @override
  int get hashCode => Object.hash(
        recommendedDifficulty,
        questionCount,
        rationale,
        blueprint,
      );
}
