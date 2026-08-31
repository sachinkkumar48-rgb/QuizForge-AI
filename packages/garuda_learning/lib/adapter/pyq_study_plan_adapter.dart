/// Adaptive PYQ Study Plan Adapter (TITAN-KO-032.0 P32 -> P24).
///
/// Bridges P31/P32 historical PYQ intelligence into P24 dynamic study planning.
///
/// Ownership & Architectural Invariants:
/// - P24 retains 100% ownership of time budgeting, daily capacity limits,
///   session slot allocation, and agenda creation.
/// - P32 NEVER directly allocates study minutes or alters session durations.
/// - P32 provides historical priority context by ordering candidate learning
///   objectives according to deterministic PYQ priority scores.
/// - Educational safety: Zero predictions, zero claims of pass guarantees.
library;

import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/pyq_learning_priority_profile.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/review_schedule.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_request.dart';
import '../domain/entities/weak_spot_profile.dart';
import '../service/deterministic_study_planner_service.dart';
import '../service/study_planner_engine.dart';

/// Contextual wrapper holding P32 priority metadata alongside a P24 study plan request.
class PyqStudyPlanContext {
  final StudyPlanRequest request;
  final PyqLearningPriorityProfile priorityProfile;
  final List<String> prioritizedObjectiveIds;

  const PyqStudyPlanContext({
    required this.request,
    required this.priorityProfile,
    required this.prioritizedObjectiveIds,
  });

  Map<String, dynamic> toJson() => {
        'examId': priorityProfile.examId,
        'sufficientEvidence': priorityProfile.sufficientEvidence,
        'prioritizedObjectiveIds': prioritizedObjectiveIds,
      };
}

/// Adapter integrating P32 PYQ Priority Context with P24 [StudyPlannerEngine].
class PyqStudyPlanAdapter {
  /// Authoritative P24 study planner engine.
  final StudyPlannerEngine planner;

  const PyqStudyPlanAdapter({
    this.planner = const DeterministicStudyPlannerService(),
  });

  /// Prioritizes a list of P17 [LearningObjective]s according to P32 PYQ priority scores.
  ///
  /// Ordering: priorityScore DESC, unitId ASC, objectiveId ASC.
  List<LearningObjective> prioritizeObjectives({
    required List<LearningObjective> objectives,
    required PyqLearningPriorityProfile priorityProfile,
  }) {
    final sorted = List<LearningObjective>.from(objectives);
    sorted.sort((a, b) {
      final sigA = priorityProfile.getObjectiveSignal(a.id);
      final sigB = priorityProfile.getObjectiveSignal(b.id);
      final scoreCmp = sigB.priorityScore.compareTo(sigA.priorityScore);
      if (scoreCmp != 0) return scoreCmp;

      final unitCmp = a.unitId.compareTo(b.unitId);
      if (unitCmp != 0) return unitCmp;

      return a.id.compareTo(b.id);
    });

    // Map unitId to rank prefix to guarantee P24 internal _extractNewCurriculum
    // preserves the PYQ-prioritized candidate order.
    return List.unmodifiable(
      sorted.asMap().entries.map((entry) {
        final rank = entry.key;
        final obj = entry.value;
        return LearningObjective(
          id: obj.id,
          unitId: 'pyq_${rank.toString().padLeft(4, '0')}',
          title: obj.title,
          description: obj.description,
          bloomLevel: obj.bloomLevel,
          provenance: obj.provenance,
          prerequisites: obj.prerequisites,
          supportedProducts: obj.supportedProducts,
          masteryCriteria: obj.masteryCriteria,
          sequenceIndex: obj.sequenceIndex,
        );
      }),
    );
  }

  /// Builds a [PyqStudyPlanContext] for a study plan request.
  PyqStudyPlanContext createContext({
    required StudyPlanRequest request,
    required PyqLearningPriorityProfile priorityProfile,
    List<LearningObjective>? availableObjectives,
  }) {
    final candidateIds = request.scopedObjectiveIds ??
        availableObjectives?.map((o) => o.id).toList() ??
        priorityProfile.objectiveSignals
            .map((s) => s.objectiveId)
            .whereType<String>()
            .toList();

    final sortedIds = List<String>.from(candidateIds);
    sortedIds.sort((a, b) {
      final scoreA = priorityProfile.getObjectiveSignal(a).priorityScore;
      final scoreB = priorityProfile.getObjectiveSignal(b).priorityScore;
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.compareTo(b);
    });

    return PyqStudyPlanContext(
      request: request,
      priorityProfile: priorityProfile,
      prioritizedObjectiveIds: List.unmodifiable(sortedIds),
    );
  }

  /// Generates a study plan where candidate learning objectives are contextualized
  /// by P32 historical priority while delegating all time budgeting and agenda
  /// generation to P24 [planner].
  StudyPlan generatePlanWithPyqPriority({
    required StudyPlanRequest request,
    required PyqLearningPriorityProfile priorityProfile,
    ReviewSchedule? reviewSchedule,
    WeakSpotProfile? weakSpotProfile,
    RecommendationQueue? recommendationQueue,
    List<LearningObjective>? availableObjectives,
    List<LearnerProgress>? progressList,
    DateTime? generatedAt,
  }) {
    // 1. Contextualize available objectives by sorting according to PYQ priority
    final prioritizedObjectives = availableObjectives != null
        ? prioritizeObjectives(
            objectives: availableObjectives,
            priorityProfile: priorityProfile,
          )
        : null;

    // 2. Contextualize scoped objective IDs if present
    List<String>? prioritizedScopedIds;
    if (request.scopedObjectiveIds != null) {
      final ids = List<String>.from(request.scopedObjectiveIds!);
      ids.sort((a, b) {
        final scoreA = priorityProfile.getObjectiveSignal(a).priorityScore;
        final scoreB = priorityProfile.getObjectiveSignal(b).priorityScore;
        final cmp = scoreB.compareTo(scoreA);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });
      prioritizedScopedIds = List.unmodifiable(ids);
    }

    // 3. Enrich request metadata with P32 PYQ priority context (without mutating request)
    final enrichedMetadata = Map<String, dynamic>.from(request.metadata)
      ..addAll({
        'pyqExamId': priorityProfile.examId,
        'pyqSufficientEvidence': priorityProfile.sufficientEvidence,
        'pyqCorpusQuestionCount': priorityProfile.corpusQuestionCount,
        'pyqPriorityIntegrated': true,
      });

    final contextualizedRequest = StudyPlanRequest(
      learnerId: request.learnerId,
      planningWindowStart: request.planningWindowStart,
      planningWindowEnd: request.planningWindowEnd,
      targetMilestoneDate: request.targetMilestoneDate,
      timeBudget: request.timeBudget,
      scopedObjectiveIds: prioritizedScopedIds ?? request.scopedObjectiveIds,
      requestedAt: request.requestedAt,
      metadata: enrichedMetadata,
    );

    // 4. Delegate 100% of study planning, daily quotas, and agenda items to P24 planner
    return planner.generatePlan(
      request: contextualizedRequest,
      reviewSchedule: reviewSchedule,
      weakSpotProfile: weakSpotProfile,
      recommendationQueue: recommendationQueue,
      availableObjectives: prioritizedObjectives ?? availableObjectives,
      progressList: progressList,
      generatedAt: generatedAt,
    );
  }
}
