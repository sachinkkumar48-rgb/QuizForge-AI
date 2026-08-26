/// Retention Analytics Evaluator (TITAN-KO-023.0 P23 Stage 4).
///
/// Stateless, deterministic evaluation service that calculates [RetentionProfile]
/// for a target learner from P20 spaced repetition review telemetry.
///
/// Clean Architecture Boundary:
/// - P20 owns SM-2 scheduling, interval updates, and review queues.
/// - This evaluator is strictly a read-only analytical observer.
/// - Zero mutation of [ReviewSchedule], [ReviewItem], or [ReviewResult].
///
/// Educational Safety Principles:
/// - Zero review evidence yields null metric values and [hasSufficientEvidence] == false.
/// - Zero-denominator guards prevent NaN, Infinity, or division-by-zero.
/// - All normalized indices strictly bounded in range [0.0, 1.0].
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/performance_rating.dart';
import '../domain/entities/retention_profile.dart';
import '../domain/entities/review_item.dart';
import '../domain/entities/review_result.dart';
import '../domain/entities/review_schedule.dart';

/// Stateless evaluator for computing observed [RetentionProfile].
class RetentionAnalyticsEvaluator {
  const RetentionAnalyticsEvaluator();

  /// Evaluates retention analytics from P20 review schedule and result evidence.
  ///
  /// Parameters:
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [scopeId]: Optional curriculum scope identifier.
  /// - [schedule]: The learner's P20 [ReviewSchedule] (read-only).
  /// - [reviewResults]: Optional historical [ReviewResult] records for retention rate calculation.
  /// - [scopedObjectiveIds]: Optional objective ID filter for scoping evaluation.
  /// - [minimumEvidenceThreshold]: Active review items required for sufficient evidence (default: 3).
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  RetentionProfile evaluate({
    required String learnerId,
    String? scopeId,
    required ReviewSchedule schedule,
    List<ReviewResult>? reviewResults,
    List<String>? scopedObjectiveIds,
    int minimumEvidenceThreshold = RetentionProfile.defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }

    final utcEvaluatedAt = evaluatedAt.toUtc();

    // Step 1: Filter schedule items by scoped objective IDs when supplied.
    final Map<String, ReviewItem> scopedItems;
    if (scopedObjectiveIds != null) {
      final scopeSet = scopedObjectiveIds.toSet();
      scopedItems = Map<String, ReviewItem>.fromEntries(
        schedule.items.entries.where((e) => scopeSet.contains(e.key)),
      );
    } else {
      scopedItems = schedule.items;
    }

    // Step 2: Total tracked objectives.
    final totalTrackedObjectives = scopedItems.length;

    // Step 3: Active review items (reviewCount > 0 OR lastReviewed != null).
    var activeReviewItemsCount = 0;
    for (final item in scopedItems.values) {
      if (item.reviewCount > 0 || item.lastReviewed != null) {
        activeReviewItemsCount++;
      }
    }

    // Step 4: Overdue items (nextReviewDate <= evaluatedAt UTC).
    var overdueItemsCount = 0;
    for (final item in scopedItems.values) {
      if (!item.nextReviewDate.toUtc().isAfter(utcEvaluatedAt)) {
        overdueItemsCount++;
      }
    }

    // Step 5: Upcoming items.
    final upcomingItemsCount = totalTrackedObjectives - overdueItemsCount;

    // Step 6: Average ease factor.
    final double? averageEaseFactor;
    if (totalTrackedObjectives == 0) {
      averageEaseFactor = null;
    } else {
      var easeSum = 0.0;
      for (final item in scopedItems.values) {
        easeSum += item.easeFactor;
      }
      averageEaseFactor = (easeSum / totalTrackedObjectives).clamp(1.3, 2.5);
    }

    // Step 7: Average interval days.
    final double? averageIntervalDays;
    if (totalTrackedObjectives == 0) {
      averageIntervalDays = null;
    } else {
      var intervalSum = 0;
      for (final item in scopedItems.values) {
        intervalSum += item.intervalDays;
      }
      averageIntervalDays = intervalSum / totalTrackedObjectives;
    }

    // Step 8: Observed retention rate from review results.
    final double? observedRetentionRate;
    final effectiveResults = reviewResults ?? const <ReviewResult>[];
    if (effectiveResults.isEmpty) {
      observedRetentionRate = null;
    } else {
      // Filter results to scoped objectives when applicable.
      final List<ReviewResult> filteredResults;
      if (scopedObjectiveIds != null) {
        final scopeSet = scopedObjectiveIds.toSet();
        filteredResults = effectiveResults
            .where((r) => scopeSet.contains(r.objectiveId))
            .toList();
      } else {
        filteredResults = effectiveResults;
      }

      if (filteredResults.isEmpty) {
        observedRetentionRate = null;
      } else {
        var successfulReviews = 0;
        for (final result in filteredResults) {
          // SM-2 grade >= 3 (hard, good, easy) is considered successful retention.
          if (result.rating.grade >= PerformanceRating.hard.grade) {
            successfulReviews++;
          }
        }
        observedRetentionRate =
            (successfulReviews / filteredResults.length).clamp(0.0, 1.0);
      }
    }

    // Step 9: Has sufficient evidence.
    final hasSufficientEvidence = totalTrackedObjectives > 0 &&
        activeReviewItemsCount >= minimumEvidenceThreshold;

    // Step 10: Projected memory stability.
    final double? projectedMemoryStability;
    if (!hasSufficientEvidence) {
      projectedMemoryStability = null;
    } else {
      // Use observedRetentionRate or default to 0.0 when no review results exist.
      final retentionRate = observedRetentionRate ?? 0.0;

      // Overdue component: 1.0 - (overdueCount / totalTracked).
      final overdueComponent = totalTrackedObjectives == 0
          ? 0.0
          : 1.0 - (overdueItemsCount / totalTrackedObjectives);

      // Ease component: normalized ease within [1.3, 2.5].
      final easeComponent = averageEaseFactor == null
          ? 0.0
          : (averageEaseFactor - 1.3) / (2.5 - 1.3);

      final stability =
          (0.5 * retentionRate + 0.3 * overdueComponent + 0.2 * easeComponent)
              .clamp(0.0, 1.0);

      projectedMemoryStability = stability;
    }

    return RetentionProfile(
      learnerId: learnerId,
      scopeId: scopeId,
      totalTrackedObjectives: totalTrackedObjectives,
      activeReviewItemsCount: activeReviewItemsCount,
      overdueItemsCount: overdueItemsCount,
      upcomingItemsCount: upcomingItemsCount,
      averageEaseFactor: averageEaseFactor,
      averageIntervalDays: averageIntervalDays,
      observedRetentionRate: observedRetentionRate,
      projectedMemoryStability: projectedMemoryStability,
      hasSufficientEvidence: hasSufficientEvidence,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      evaluatedAt: utcEvaluatedAt,
      metadata: metadata,
    );
  }
}
