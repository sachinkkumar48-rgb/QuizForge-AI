/// Remedial Lesson Service Contract (TITAN-KO-025.0 P25).
///
/// Interface defining the deterministic remedial learning engine contract.
/// Integrates P23 WeakSpotProfile, P21 Recommendation, and P19 SessionConfiguration.
library;

import '../domain/entities/bloom_taxonomy_level.dart';
import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/remedial_binding.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/remedial_practice_session_config.dart';
import '../domain/entities/weak_spot_profile.dart';

/// Abstract service contract for resolving, binding, and configuring remedial micro-lessons.
abstract interface class RemedialLessonService {
  /// Resolves the optimal remedial lesson for a target learning objective.
  /// If multiple exist, prefers matching [targetBloomLevel] if specified,
  /// then highest version.
  Future<RemedialLesson?> findBestLessonForObjective({
    required String objectiveId,
    BloomTaxonomyLevel? targetBloomLevel,
  });

  /// Deterministically binds remedial lessons for all diagnosed weak spots in a [WeakSpotProfile].
  ///
  /// Educational Safety Rules:
  /// - Only binds objectives meeting the [weakSpotProfile.minimumEvidenceThreshold].
  /// - Orders bindings by P23 deficiencyScore descending, objectiveId ascending.
  /// - Respects optional [maxLessons] budget.
  /// - Generates deterministic binding IDs with explicit [boundAt].
  /// - Guarantees zero mutation of the upstream [WeakSpotProfile].
  Future<List<RemedialLessonBinding>> bindRemedialLessonsForWeakSpots({
    required WeakSpotProfile weakSpotProfile,
    int? maxLessons,
    DateTime? boundAt,
  });

  /// Binds a remedial lesson for an adaptive recommendation from P21.
  /// Preserves recommendation ID as provenance only without mutating P21 queues.
  Future<RemedialLessonBinding?> bindRemedialLessonForRecommendation({
    required LearningRecommendation recommendation,
    DateTime? boundAt,
  });

  /// Creates a targeted re-testing practice session configuration following remedial study.
  /// Selects questions matching the objective deterministically.
  Future<RemedialPracticeSessionConfig> createPracticeRetryConfig({
    required RemedialLessonBinding binding,
    required List<String> availableQuestionIds,
    int questionLimit = 5,
    DateTime? createdAt,
  });
}
