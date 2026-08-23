import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'adaptive_assessment_plan.dart';
import 'remedial_study_recommendation.dart';
import 'review_schedule_item.dart';
import 'study_next_recommendation.dart';

/// Immutable aggregate representing a complete, deterministic remedial study plan.
@immutable
class AdaptiveRemedialPlan {
  final List<String> priorityTopics;
  final List<RemedialStudyRecommendation> recommendedSourceReviews;
  final List<String> retryQuestions;
  final QuizDifficulty recommendedDifficulty;
  final List<ReviewScheduleItem> reviewItems;
  final AdaptiveAssessmentPlan? nextAssessmentPlan;
  final StudyNextRecommendation studyNext;

  AdaptiveRemedialPlan({
    List<String>? priorityTopics,
    List<RemedialStudyRecommendation>? recommendedSourceReviews,
    List<String>? retryQuestions,
    required this.recommendedDifficulty,
    List<ReviewScheduleItem>? reviewItems,
    this.nextAssessmentPlan,
    required this.studyNext,
  })  : priorityTopics = List.unmodifiable(priorityTopics ?? const []),
        recommendedSourceReviews =
            List.unmodifiable(recommendedSourceReviews ?? const []),
        retryQuestions = List.unmodifiable(retryQuestions ?? const []),
        reviewItems = List.unmodifiable(reviewItems ?? const []);

  const AdaptiveRemedialPlan.constPlan({
    required this.priorityTopics,
    required this.recommendedSourceReviews,
    required this.retryQuestions,
    required this.recommendedDifficulty,
    required this.reviewItems,
    required this.nextAssessmentPlan,
    required this.studyNext,
  });

  bool get hasSourceReviews => recommendedSourceReviews.isNotEmpty;
  bool get hasRetryQuestions => retryQuestions.isNotEmpty;
  bool get hasReviewItems => reviewItems.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveRemedialPlan &&
          runtimeType == other.runtimeType &&
          recommendedDifficulty == other.recommendedDifficulty &&
          studyNext == other.studyNext;

  @override
  int get hashCode => Object.hash(
        recommendedDifficulty,
        studyNext,
      );
}
