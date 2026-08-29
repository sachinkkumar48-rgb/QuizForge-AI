/// Deterministic Remedial Lesson Service (TITAN-KO-025.0 P25).
///
/// Offline-first, purely deterministic implementation of [RemedialLessonService].
/// Integrates P23 diagnostic weak spots and P21 adaptive recommendations into structured
/// remedial lesson bindings and targeted practice retry configurations.
///
/// Educational Safety Invariants:
/// - Zero LLM runtime dependencies in core domain service.
/// - Zero network access; offline-first.
/// - Zero [DateTime.now()]. Explicit timestamps only.
/// - Strict adherence to P23 [minimumEvidenceThreshold].
/// - Zero mutation of P23 WeakSpotProfile, P21 LearningRecommendation, or P18 progress.
/// - Zero claims of learner innate intelligence or exam pass guarantees.
library;

import '../domain/entities/bloom_taxonomy_level.dart';
import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/remedial_binding.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/remedial_practice_session_config.dart';
import '../domain/entities/weak_spot_profile.dart';
import '../repository/remedial_lesson_repository.dart';
import 'remedial_lesson_service.dart';

/// Pure deterministic service resolving and binding remedial micro-lessons.
class DeterministicRemedialLessonService implements RemedialLessonService {
  /// Repository providing access to verified remedial lessons.
  final RemedialLessonRepository lessonRepository;

  const DeterministicRemedialLessonService({
    required this.lessonRepository,
  });

  @override
  Future<RemedialLesson?> findBestLessonForObjective({
    required String objectiveId,
    BloomTaxonomyLevel? targetBloomLevel,
  }) async {
    final available =
        await lessonRepository.getLessonsForObjective(objectiveId);
    if (available.isEmpty) return null;

    // If bloomLevel specified, prefer matching bloomLevel with highest version
    if (targetBloomLevel != null) {
      final matchingBloom =
          available.where((l) => l.bloomLevel == targetBloomLevel).toList();
      if (matchingBloom.isNotEmpty) {
        // available is already sorted by version DESC, lessonId ASC
        return matchingBloom.first;
      }
    }

    // Fallback to highest version overall
    return available.first;
  }

  @override
  Future<List<RemedialLessonBinding>> bindRemedialLessonsForWeakSpots({
    required WeakSpotProfile weakSpotProfile,
    int? maxLessons,
    DateTime? boundAt,
  }) async {
    final effectiveBoundAt = (boundAt ?? weakSpotProfile.evaluatedAt).toUtc();

    if (!weakSpotProfile.hasWeakSpots) {
      return const <RemedialLessonBinding>[];
    }

    // Filter to objectives that satisfy the minimum evidence threshold
    final qualifyingDiagnostics = weakSpotProfile.weakObjectives.where((diag) {
      return diag.attemptCount >= weakSpotProfile.minimumEvidenceThreshold;
    }).toList();

    // P23 already sorts by deficiencyScore DESC, objectiveId ASC
    final bindings = <RemedialLessonBinding>[];
    for (final diag in qualifyingDiagnostics) {
      if (maxLessons != null && bindings.length >= maxLessons) {
        break;
      }

      final lesson = await findBestLessonForObjective(
        objectiveId: diag.objectiveId,
        targetBloomLevel: diag.bloomLevel,
      );

      if (lesson != null) {
        final bindingId =
            'bind_${weakSpotProfile.learnerId}_${diag.objectiveId}_${effectiveBoundAt.millisecondsSinceEpoch}';
        bindings.add(
          RemedialLessonBinding(
            bindingId: bindingId,
            learnerId: weakSpotProfile.learnerId,
            objectiveId: diag.objectiveId,
            lesson: lesson,
            trigger: RemedialBindingTrigger.weakSpotDiagnostic,
            deficiencyScore: diag.deficiencyScore,
            boundAt: effectiveBoundAt,
            metadata: {
              'attemptCount': diag.attemptCount,
              'correctCount': diag.correctCount,
              'observedAccuracy': diag.observedAccuracy,
              'deficiencyScore': diag.deficiencyScore,
            },
          ),
        );
      }
    }

    return List.unmodifiable(bindings);
  }

  @override
  Future<RemedialLessonBinding?> bindRemedialLessonForRecommendation({
    required LearningRecommendation recommendation,
    DateTime? boundAt,
  }) async {
    final effectiveBoundAt = (boundAt ?? DateTime.utc(2026, 1, 1)).toUtc();

    final lesson = await findBestLessonForObjective(
      objectiveId: recommendation.objectiveId,
    );

    if (lesson == null) return null;

    final bindingId =
        'bind_${recommendation.learnerId}_${recommendation.objectiveId}_${effectiveBoundAt.millisecondsSinceEpoch}';

    return RemedialLessonBinding(
      bindingId: bindingId,
      learnerId: recommendation.learnerId,
      objectiveId: recommendation.objectiveId,
      lesson: lesson,
      trigger: RemedialBindingTrigger.adaptiveRecommendation,
      sourceRecommendationId: recommendation.recommendationId,
      boundAt: effectiveBoundAt,
      metadata: {
        'recommendationType': recommendation.type.name,
        'priorityScore': recommendation.priorityScore,
        'rationale': recommendation.rationale,
      },
    );
  }

  @override
  Future<RemedialPracticeSessionConfig> createPracticeRetryConfig({
    required RemedialLessonBinding binding,
    required List<String> availableQuestionIds,
    int questionLimit = 5,
    DateTime? createdAt,
  }) async {
    final effectiveCreatedAt = (createdAt ?? binding.boundAt).toUtc();

    // Sort available question IDs deterministically (lexically ascending)
    final sortedQuestions = List<String>.from(availableQuestionIds)..sort();

    final targetQuestions =
        sortedQuestions.take(questionLimit).toList(growable: false);

    final configId =
        'retry_${binding.learnerId}_${binding.objectiveId}_${effectiveCreatedAt.millisecondsSinceEpoch}';

    return RemedialPracticeSessionConfig(
      configId: configId,
      learnerId: binding.learnerId,
      objectiveId: binding.objectiveId,
      remedialLessonId: binding.lessonId,
      targetQuestionIds: targetQuestions,
      questionLimit: questionLimit,
      createdAt: effectiveCreatedAt,
      metadata: {
        'bindingId': binding.bindingId,
        'trigger': binding.trigger.name,
        if (binding.deficiencyScore != null)
          'deficiencyScore': binding.deficiencyScore,
      },
    );
  }
}
