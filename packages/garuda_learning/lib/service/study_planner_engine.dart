/// Study Planner Engine Contract (TITAN-KO-024.0 P24).
///
/// Clean Architecture service interface for deterministic, offline-first study
/// calendar and daily agenda generation.
library;

import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/review_schedule.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_request.dart';
import '../domain/entities/weak_spot_profile.dart';

/// Abstract service contract for generating deterministic study plans.
abstract class StudyPlannerEngine {
  /// Generates an immutable [StudyPlan] spanning the window specified in [request].
  ///
  /// Parameters:
  /// - [request]: Required [StudyPlanRequest] specifying planning window and budget.
  /// - [reviewSchedule]: Optional P20 [ReviewSchedule] containing SM-2 review items.
  /// - [weakSpotProfile]: Optional P23 [WeakSpotProfile] containing diagnostic weak spots.
  /// - [recommendationQueue]: Optional P21 [RecommendationQueue] containing prioritized recommendations.
  /// - [availableObjectives]: Optional list of P17 [LearningObjective] entities in curriculum.
  /// - [progressList]: Optional list of P18 [LearnerProgress] records for progress state.
  /// - [generatedAt]: Explicit UTC generation timestamp for deterministic replay.
  StudyPlan generatePlan({
    required StudyPlanRequest request,
    ReviewSchedule? reviewSchedule,
    WeakSpotProfile? weakSpotProfile,
    RecommendationQueue? recommendationQueue,
    List<LearningObjective>? availableObjectives,
    List<LearnerProgress>? progressList,
    DateTime? generatedAt,
  });
}
