import 'package:titan_quiz/titan_quiz.dart';
import '../models/adaptive_assessment_plan.dart';
import '../models/adaptive_remedial_plan.dart';
import '../models/assessment_blueprint.dart';
import '../models/assessment_performance.dart';
import '../models/interactive_question_state.dart';
import '../models/learner_profile.dart';
import '../models/review_schedule_item.dart';
import 'adaptive_assessment_strategy.dart';
import 'assessment_performance_analyzer.dart';
import 'difficulty_adapter.dart';
import 'review_scheduler.dart';
import 'study_next_engine.dart';

/// Deterministic orchestration engine constructing complete, actionable adaptive remedial plans.
class AdaptiveRemedialEngine {
  final AssessmentPerformanceAnalyzer performanceAnalyzer;
  final DifficultyAdapter difficultyAdapter;
  final ReviewScheduler reviewScheduler;
  final AdaptiveAssessmentStrategy adaptiveStrategy;
  final StudyNextEngine studyNextEngine;

  const AdaptiveRemedialEngine({
    this.performanceAnalyzer = const AssessmentPerformanceAnalyzer(),
    this.difficultyAdapter = const DifficultyAdapter(),
    this.reviewScheduler = const ReviewScheduler(),
    this.adaptiveStrategy = const AdaptiveAssessmentStrategy(),
    this.studyNextEngine = const StudyNextEngine(),
  });

  /// Builds a cohesive [AdaptiveRemedialPlan] from assessment results and historical learner profile.
  AdaptiveRemedialPlan generateRemedialPlan({
    required LearnerProfile profile,
    required Quiz quiz,
    required AssessmentPerformance performance,
    required Map<String, InteractiveQuestionState> questionStates,
    List<ReviewScheduleItem> existingReviewItems = const [],
    AssessmentBlueprint? baseBlueprint,
  }) {
    // 1. Generate grounded source reviews connecting weak topics back to pages
    final sourceReviews = performanceAnalyzer.generateRemedialRecommendations(
      quiz: quiz,
      performance: performance,
      questionStates: questionStates,
    );

    // 2. Identify priority topics ordered by lowest accuracy first
    final priorityTopics = List<String>.from(performance.weakTopics);
    priorityTopics.sort((a, b) {
      final accA = performance.accuracyByTopic[a] ?? 0.0;
      final accB = performance.accuracyByTopic[b] ?? 0.0;
      return accA.compareTo(accB);
    });

    // 3. Recommended adapted difficulty for next steps
    final recommendedDiff = difficultyAdapter.recommendOverallDifficulty(
      profile,
      fallback: quiz.difficulty,
    );

    // 4. Determine currently due review items
    final dueItems = reviewScheduler.getDueItems(items: existingReviewItems);

    // 5. Generate Study Next recommendation
    final studyNext = studyNextEngine.recommendNext(
      profile: profile,
      dueReviewItems: dueItems,
      activeDocumentId: quiz.sourceDocumentId,
    );

    // 6. Generate next assessment plan if blueprint available
    AdaptiveAssessmentPlan? nextPlan;
    if (baseBlueprint != null) {
      nextPlan = adaptiveStrategy.createPlan(
        profile: profile,
        baseBlueprint: baseBlueprint,
        dueReviewItems: dueItems,
      );
    }

    return AdaptiveRemedialPlan(
      priorityTopics: priorityTopics,
      recommendedSourceReviews: sourceReviews,
      retryQuestions: performance.incorrectQuestionIds,
      recommendedDifficulty: recommendedDiff,
      reviewItems: existingReviewItems,
      nextAssessmentPlan: nextPlan,
      studyNext: studyNext,
    );
  }
}
