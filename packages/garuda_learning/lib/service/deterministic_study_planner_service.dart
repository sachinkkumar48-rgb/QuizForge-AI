/// Deterministic Study Planner Service (TITAN-KO-024.0 P24 Stage 2).
///
/// Implements [StudyPlannerEngine] providing evidence-backed, deterministic,
/// offline-first daily study agenda generation.
///
/// Educational Safety Principles:
/// - Pure deterministic algorithm with zero network access, zero LLM calls, and zero [DateTime.now()].
/// - Does NOT mutate any upstream P17/P18/P20/P21/P22/P23 state.
/// - Does NOT implement SM-2 or alter review schedules.
/// - Does NOT recalculate P23 analytics or infer learner ability.
/// - Explanations represent transparent scheduling decisions, NOT learner judgments.
library;

import 'dart:math' as math;

import '../domain/entities/daily_study_agenda.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/review_item.dart';
import '../domain/entities/review_schedule.dart';
import '../domain/entities/study_agenda_item.dart';
import '../domain/entities/study_allocation_type.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_request.dart';
import '../domain/entities/weak_spot_profile.dart';
import 'study_planner_engine.dart';

/// Purely deterministic study planner implementing [StudyPlannerEngine].
class DeterministicStudyPlannerService implements StudyPlannerEngine {
  /// Default maximum fraction of daily session slots that can be consumed by overdue reviews.
  static const double defaultMaxOverdueReviewsFraction = 0.50;

  /// Configured maximum fraction of daily session slots allocated to overdue reviews during balancing.
  final double maxOverdueReviewsFractionPerDay;

  const DeterministicStudyPlannerService({
    this.maxOverdueReviewsFractionPerDay = defaultMaxOverdueReviewsFraction,
  });

  @override
  StudyPlan generatePlan({
    required StudyPlanRequest request,
    ReviewSchedule? reviewSchedule,
    WeakSpotProfile? weakSpotProfile,
    RecommendationQueue? recommendationQueue,
    List<LearningObjective>? availableObjectives,
    List<LearnerProgress>? progressList,
    DateTime? generatedAt,
  }) {
    final effectiveGeneratedAt = (generatedAt ?? request.requestedAt).toUtc();

    // 1. Generate discrete UTC calendar days across the planning window.
    final planningDays = _generatePlanningDays(
      request.planningWindowStart,
      request.planningWindowEnd,
    );

    // 2. Resolve daily session constraints from learner budget.
    final budget = request.timeBudget;
    final sessionDuration = budget.preferredSessionDurationMinutes;
    final dailyAvailableMinutes = budget.dailyAvailableMinutes;
    final maxSessionsPerDay = budget.maxSessionsPerDay;
    final effectiveDailyCapacity = budget.effectiveDailyCapacityMinutes;
    final maxSessionsAllowed = (effectiveDailyCapacity / sessionDuration)
        .floor()
        .clamp(0, maxSessionsPerDay);

    // 3. Build candidate pools (filtered by scopedObjectiveIds if provided).
    final scopedIds = request.scopedObjectiveIds?.toSet();

    // Pool 1: Overdue reviews (items scheduled before the first planning day).
    final windowStartMidnight = planningDays.first;
    final overdueReviewCandidates = _extractOverdueReviews(
      reviewSchedule,
      windowStartMidnight,
      scopedIds,
    );

    // Pool 2: Due reviews indexed by calendar date.
    final dueReviewsByDate = _extractDueReviewsByDate(
      reviewSchedule,
      windowStartMidnight,
      scopedIds,
    );

    // Pool 3: Diagnosed weak spots from P23.
    final weakSpotCandidates = _extractWeakSpots(
      weakSpotProfile,
      scopedIds,
    );

    // Pool 4: Adaptive recommendations from P21.
    final recommendationCandidates = _extractRecommendations(
      recommendationQueue,
      scopedIds,
    );

    // Pool 5: New curriculum objectives not yet achieved or in progress.
    final newCurriculumCandidates = _extractNewCurriculum(
      availableObjectives,
      progressList,
      request.learnerId,
      scopedIds,
    );

    // 4. Daily agenda allocation state across the planning window.
    final dailyAgendas = <DailyStudyAgenda>[];
    final scheduledObjectiveIdsInPlan = <String>{};

    // Tracking queues
    var overdueQueue = List<ReviewItem>.from(overdueReviewCandidates);
    var weakSpotsQueue = List<WeakObjectiveDiagnostic>.from(weakSpotCandidates);
    var recsQueue = List<LearningRecommendation>.from(recommendationCandidates);
    var curriculumQueue = List<LearningObjective>.from(newCurriculumCandidates);

    // Maximum overdue reviews allowed per day to prevent review starvation of new learning.
    final maxDailyOverdueSlots = math.max(
      1,
      (maxSessionsAllowed * maxOverdueReviewsFractionPerDay).floor(),
    );

    for (final day in planningDays) {
      final dailyItems = <StudyAgendaItem>[];
      int currentRank = 1;
      int allocatedMinutesToday = 0;

      bool canFitSession() {
        return dailyItems.length < maxSessionsAllowed &&
            (allocatedMinutesToday + sessionDuration) <= effectiveDailyCapacity;
      }

      String makeItemId(int rank) {
        final dStr =
            '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
        return 'agenda_${request.learnerId}_${dStr}_$rank';
      }

      // ── Tier 1: Balanced Overdue Reviews ──────────────────────────────────
      int overdueAllocatedToday = 0;
      final remainingOverdue = <ReviewItem>[];
      for (final item in overdueQueue) {
        if (!scheduledObjectiveIdsInPlan.contains(item.objectiveId) &&
            overdueAllocatedToday < maxDailyOverdueSlots &&
            canFitSession()) {
          final overdueHours =
              day.difference(item.nextReviewDate).inMinutes / 60.0;
          dailyItems.add(StudyAgendaItem(
            itemId: makeItemId(currentRank),
            objectiveId: item.objectiveId,
            allocationType: StudyAllocationType.overdueReview,
            scheduledDate: day,
            allocatedMinutes: sessionDuration,
            priorityRank: currentRank++,
            explanation:
                'Overdue spaced review from P20 (scheduled for ${item.nextReviewDate.toIso8601String().substring(0, 10)}, overdue by ${overdueHours.toStringAsFixed(1)}h)',
            sourceEntityId: item.objectiveId,
            metadata: {
              'intervalDays': item.intervalDays,
              'easeFactor': item.easeFactor,
              'overdueHours': overdueHours,
            },
          ));
          allocatedMinutesToday += sessionDuration;
          overdueAllocatedToday++;
          scheduledObjectiveIdsInPlan.add(item.objectiveId);
        } else if (!scheduledObjectiveIdsInPlan.contains(item.objectiveId)) {
          remainingOverdue.add(item);
        }
      }
      overdueQueue = remainingOverdue;

      // ── Tier 2: Due Reviews for this specific day ─────────────────────────
      final dueOnThisDay = dueReviewsByDate[day] ?? const <ReviewItem>[];
      for (final item in dueOnThisDay) {
        if (!scheduledObjectiveIdsInPlan.contains(item.objectiveId) &&
            canFitSession()) {
          dailyItems.add(StudyAgendaItem(
            itemId: makeItemId(currentRank),
            objectiveId: item.objectiveId,
            allocationType: StudyAllocationType.dueReview,
            scheduledDate: day,
            allocatedMinutes: sessionDuration,
            priorityRank: currentRank++,
            explanation:
                'Due spaced review scheduled for ${day.toIso8601String().substring(0, 10)}',
            sourceEntityId: item.objectiveId,
            metadata: {
              'intervalDays': item.intervalDays,
              'easeFactor': item.easeFactor,
            },
          ));
          allocatedMinutesToday += sessionDuration;
          scheduledObjectiveIdsInPlan.add(item.objectiveId);
        }
      }

      // ── Tier 3: Diagnosed Weak Spots from P23 ─────────────────────────────
      final remainingWeakSpots = <WeakObjectiveDiagnostic>[];
      for (final weakObj in weakSpotsQueue) {
        if (!scheduledObjectiveIdsInPlan.contains(weakObj.objectiveId) &&
            canFitSession()) {
          dailyItems.add(StudyAgendaItem(
            itemId: makeItemId(currentRank),
            objectiveId: weakObj.objectiveId,
            allocationType: StudyAllocationType.weakSpotPractice,
            scheduledDate: day,
            allocatedMinutes: sessionDuration,
            priorityRank: currentRank++,
            explanation:
                'Weak-spot practice: observed accuracy ${(weakObj.observedAccuracy * 100).toStringAsFixed(1)}% across ${weakObj.attemptCount} attempts (deficiency score: ${weakObj.deficiencyScore.toStringAsFixed(2)})',
            sourceEntityId: weakObj.objectiveId,
            metadata: {
              'observedAccuracy': weakObj.observedAccuracy,
              'attemptCount': weakObj.attemptCount,
              'deficiencyScore': weakObj.deficiencyScore,
            },
          ));
          allocatedMinutesToday += sessionDuration;
          scheduledObjectiveIdsInPlan.add(weakObj.objectiveId);
        } else if (!scheduledObjectiveIdsInPlan.contains(weakObj.objectiveId)) {
          remainingWeakSpots.add(weakObj);
        }
      }
      weakSpotsQueue = remainingWeakSpots;

      // ── Tier 4: Adaptive Recommendations from P21 ─────────────────────────
      final remainingRecs = <LearningRecommendation>[];
      for (final rec in recsQueue) {
        if (!scheduledObjectiveIdsInPlan.contains(rec.objectiveId) &&
            canFitSession()) {
          dailyItems.add(StudyAgendaItem(
            itemId: makeItemId(currentRank),
            objectiveId: rec.objectiveId,
            allocationType: StudyAllocationType.recommendedAction,
            scheduledDate: day,
            allocatedMinutes: sessionDuration,
            priorityRank: currentRank++,
            explanation:
                'P21 recommended action (${rec.type.name}): priority score ${rec.priorityScore.toStringAsFixed(3)}',
            sourceEntityId: rec.recommendationId,
            metadata: {
              'recommendationType': rec.type.name,
              'priorityScore': rec.priorityScore,
              'rationale': rec.rationale,
            },
          ));
          allocatedMinutesToday += sessionDuration;
          scheduledObjectiveIdsInPlan.add(rec.objectiveId);
        } else if (!scheduledObjectiveIdsInPlan.contains(rec.objectiveId)) {
          remainingRecs.add(rec);
        }
      }
      recsQueue = remainingRecs;

      // ── Tier 5: New Curriculum Objectives ─────────────────────────────────
      final remainingCurriculum = <LearningObjective>[];
      for (final obj in curriculumQueue) {
        if (!scheduledObjectiveIdsInPlan.contains(obj.id) && canFitSession()) {
          dailyItems.add(StudyAgendaItem(
            itemId: makeItemId(currentRank),
            objectiveId: obj.id,
            allocationType: StudyAllocationType.newCurriculum,
            scheduledDate: day,
            allocatedMinutes: sessionDuration,
            priorityRank: currentRank++,
            explanation:
                'New curriculum: objective ${obj.title.isNotEmpty ? obj.title : obj.id} (${obj.bloomLevel.name})',
            sourceEntityId: obj.id,
            metadata: {
              'unitId': obj.unitId,
              'bloomLevel': obj.bloomLevel.name,
            },
          ));
          allocatedMinutesToday += sessionDuration;
          scheduledObjectiveIdsInPlan.add(obj.id);
        } else if (!scheduledObjectiveIdsInPlan.contains(obj.id)) {
          remainingCurriculum.add(obj);
        }
      }
      curriculumQueue = remainingCurriculum;

      // ── Spillover: Absorb remaining overdue reviews if slots remain on the last day ─
      final isLastDay = day == planningDays.last;
      if (isLastDay && canFitSession() && overdueQueue.isNotEmpty) {
        final overflowRemaining = <ReviewItem>[];
        for (final item in overdueQueue) {
          if (!scheduledObjectiveIdsInPlan.contains(item.objectiveId) &&
              canFitSession()) {
            final overdueHours =
                day.difference(item.nextReviewDate).inMinutes / 60.0;
            dailyItems.add(StudyAgendaItem(
              itemId: makeItemId(currentRank),
              objectiveId: item.objectiveId,
              allocationType: StudyAllocationType.overdueReview,
              scheduledDate: day,
              allocatedMinutes: sessionDuration,
              priorityRank: currentRank++,
              explanation:
                  'Overdue spaced review (capacity spillover, overdue by ${overdueHours.toStringAsFixed(1)}h)',
              sourceEntityId: item.objectiveId,
              metadata: {
                'intervalDays': item.intervalDays,
                'easeFactor': item.easeFactor,
                'overdueHours': overdueHours,
                'spillover': true,
              },
            ));
            allocatedMinutesToday += sessionDuration;
            scheduledObjectiveIdsInPlan.add(item.objectiveId);
          } else if (!scheduledObjectiveIdsInPlan.contains(item.objectiveId)) {
            overflowRemaining.add(item);
          }
        }
        overdueQueue = overflowRemaining;
      }

      dailyAgendas.add(DailyStudyAgenda(
        learnerId: request.learnerId,
        date: day,
        items: dailyItems,
        availableMinutes: dailyAvailableMinutes,
      ));
    }

    // 5. Total unallocated candidates count.
    final unallocatedCount = overdueQueue.length +
        weakSpotsQueue.length +
        recsQueue.length +
        curriculumQueue.length;

    // 6. Target milestone advisory check.
    String? milestoneWarning;
    if (request.targetMilestoneDate != null) {
      final milestone = request.targetMilestoneDate!.toUtc();
      if (unallocatedCount > 0) {
        final milestoneFormatted =
            '${milestone.year}-${milestone.month.toString().padLeft(2, '0')}-${milestone.day.toString().padLeft(2, '0')}';
        milestoneWarning =
            'Milestone capacity advisory: $unallocatedCount candidate study item(s) could not be scheduled within the planning window before target milestone ($milestoneFormatted). Consider increasing daily study capacity or extending the planning window.';
      }
    }

    // 7. Assemble immutable StudyPlan.
    final planId =
        'plan_${request.learnerId}_${effectiveGeneratedAt.millisecondsSinceEpoch}';

    return StudyPlan(
      planId: planId,
      request: request,
      dailyAgendas: dailyAgendas,
      unallocatedObjectivesCount: unallocatedCount,
      milestoneWarning: milestoneWarning,
      generatedAt: effectiveGeneratedAt,
      metadata: {
        'totalPlanningDays': planningDays.length,
        'effectiveDailyCapacityMinutes': effectiveDailyCapacity,
        'maxSessionsPerDay': maxSessionsPerDay,
        'sessionDurationMinutes': sessionDuration,
      },
    );
  }

  /// Generates continuous list of UTC calendar days from [start] to [end] inclusive.
  static List<DateTime> _generatePlanningDays(DateTime start, DateTime end) {
    final utcStart = DateTime.utc(start.year, start.month, start.day);
    final utcEnd = DateTime.utc(end.year, end.month, end.day);
    final days = <DateTime>[];
    var current = utcStart;
    while (!current.isAfter(utcEnd)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  /// Extracts and deterministically sorts overdue review items.
  static List<ReviewItem> _extractOverdueReviews(
    ReviewSchedule? schedule,
    DateTime windowStartMidnight,
    Set<String>? scopedIds,
  ) {
    if (schedule == null) return const <ReviewItem>[];
    final items = schedule.items.values.where((item) {
      if (scopedIds != null && !scopedIds.contains(item.objectiveId)) {
        return false;
      }
      return item.nextReviewDate.isBefore(windowStartMidnight);
    }).toList();

    // Sort by priorityScore descending, then objectiveId ascending.
    items.sort((a, b) {
      final scoreA = a.priorityScore(asOfDate: windowStartMidnight);
      final scoreB = b.priorityScore(asOfDate: windowStartMidnight);
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });
    return items;
  }

  /// Extracts due review items grouped by their scheduled UTC calendar date.
  static Map<DateTime, List<ReviewItem>> _extractDueReviewsByDate(
    ReviewSchedule? schedule,
    DateTime windowStartMidnight,
    Set<String>? scopedIds,
  ) {
    final map = <DateTime, List<ReviewItem>>{};
    if (schedule == null) return map;

    for (final item in schedule.items.values) {
      if (scopedIds != null && !scopedIds.contains(item.objectiveId)) {
        continue;
      }
      if (!item.nextReviewDate.isBefore(windowStartMidnight)) {
        final dueDate = DateTime.utc(
          item.nextReviewDate.year,
          item.nextReviewDate.month,
          item.nextReviewDate.day,
        );
        map.putIfAbsent(dueDate, () => <ReviewItem>[]).add(item);
      }
    }

    // Sort items within each day by nextReviewDate ascending, then objectiveId ascending.
    for (final list in map.values) {
      list.sort((a, b) {
        final cmp = a.nextReviewDate.compareTo(b.nextReviewDate);
        if (cmp != 0) return cmp;
        return a.objectiveId.compareTo(b.objectiveId);
      });
    }
    return map;
  }

  /// Extracts diagnosed weak spots from P23.
  static List<WeakObjectiveDiagnostic> _extractWeakSpots(
    WeakSpotProfile? profile,
    Set<String>? scopedIds,
  ) {
    if (profile == null || !profile.hasWeakSpots) {
      return const <WeakObjectiveDiagnostic>[];
    }
    final items = profile.weakObjectives.where((diag) {
      if (scopedIds != null && !scopedIds.contains(diag.objectiveId)) {
        return false;
      }
      return diag.attemptCount >= profile.minimumEvidenceThreshold;
    }).toList();

    // P23 already sorts by deficiencyScore descending, objectiveId ascending.
    return items;
  }

  /// Extracts adaptive recommendations from P21.
  static List<LearningRecommendation> _extractRecommendations(
    RecommendationQueue? queue,
    Set<String>? scopedIds,
  ) {
    if (queue == null || queue.isEmpty) {
      return const <LearningRecommendation>[];
    }
    final items = queue.items.where((rec) {
      if (scopedIds != null && !scopedIds.contains(rec.objectiveId)) {
        return false;
      }
      return true;
    }).toList();

    // P21 already sorts by priorityScore descending, objectiveId ascending.
    return items;
  }

  /// Extracts new curriculum objectives that have not yet been achieved or attempted.
  static List<LearningObjective> _extractNewCurriculum(
    List<LearningObjective>? objectives,
    List<LearnerProgress>? progressList,
    String learnerId,
    Set<String>? scopedIds,
  ) {
    if (objectives == null || objectives.isEmpty) {
      return const <LearningObjective>[];
    }

    final achievedOrInProgress = <String>{};
    if (progressList != null) {
      for (final p in progressList) {
        if (p.learnerId == learnerId &&
            (p.status == LearnerObjectiveStatus.achieved ||
                p.status == LearnerObjectiveStatus.inProgress)) {
          achievedOrInProgress.add(p.objectiveId);
        }
      }
    }

    final candidates = objectives.where((obj) {
      if (scopedIds != null && !scopedIds.contains(obj.id)) {
        return false;
      }
      return !achievedOrInProgress.contains(obj.id);
    }).toList();

    // Deterministic sort: unitId ascending, then id ascending.
    candidates.sort((a, b) {
      final unitCmp = a.unitId.compareTo(b.unitId);
      if (unitCmp != 0) return unitCmp;
      return a.id.compareTo(b.id);
    });

    return candidates;
  }
}
