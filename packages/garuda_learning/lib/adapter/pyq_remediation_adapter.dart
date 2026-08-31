/// Adaptive PYQ Remediation Adapter (TITAN-KO-032.0 P32 -> P25).
///
/// Integrates P31/P32 historical PYQ intelligence into P25 remedial target selection.
///
/// Ownership & Architectural Invariants:
/// - P25 retains 100% ownership of remedial lesson resolution, binding, and content.
/// - P32 NEVER generates remedial lesson content or alters lesson explanations.
/// - P32 provides historical representation, recurrence, and evidence confidence
///   to inform which diagnosed weak spots should be addressed first.
/// - Adheres strictly to P23 [minimumEvidenceThreshold] — unassessed or sparse
///   objectives are NEVER converted into weak spots.
library;

import '../domain/entities/pyq_learning_priority_profile.dart';
import '../domain/entities/pyq_learning_priority_signal.dart';
import '../domain/entities/remedial_binding.dart';
import '../domain/entities/weak_spot_profile.dart';
import '../service/remedial_lesson_service.dart';

/// Contextual wrapper holding P32 historical priority alongside a diagnosed weak spot.
class PyqContextualizedWeakSpot {
  final WeakObjectiveDiagnostic diagnostic;
  final PyqLearningPrioritySignal pyqSignal;
  final double compositeRemedialScore;

  const PyqContextualizedWeakSpot({
    required this.diagnostic,
    required this.pyqSignal,
    required this.compositeRemedialScore,
  });

  String get objectiveId => diagnostic.objectiveId;

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'deficiencyScore': diagnostic.deficiencyScore,
        'observedAccuracy': diagnostic.observedAccuracy,
        'attemptCount': diagnostic.attemptCount,
        'pyqPriorityScore': pyqSignal.priorityScore,
        'historicalQuestionCount': pyqSignal.historicalQuestionCount,
        'yearsObserved': pyqSignal.yearsObserved,
        'compositeRemedialScore': compositeRemedialScore,
      };
}

/// Adapter contextualizing P25 remedial lesson binding using P32 PYQ intelligence.
class PyqRemediationAdapter {
  /// Default weight for learner deficiency score in composite remedial ranking.
  static const double defaultDeficiencyWeight = 0.60;

  /// Default weight for historical PYQ priority in composite remedial ranking.
  static const double defaultPyqWeight = 0.40;

  final double deficiencyWeight;
  final double pyqWeight;

  const PyqRemediationAdapter({
    this.deficiencyWeight = defaultDeficiencyWeight,
    this.pyqWeight = defaultPyqWeight,
  });

  /// Evaluates and prioritizes diagnosed weak spots from a P23 [WeakSpotProfile]
  /// using P32 historical PYQ intelligence.
  ///
  /// Ordering: compositeRemedialScore DESC, objectiveId ASC.
  List<PyqContextualizedWeakSpot> prioritizeWeakSpots({
    required WeakSpotProfile weakSpotProfile,
    required PyqLearningPriorityProfile priorityProfile,
  }) {
    if (!weakSpotProfile.hasWeakSpots) {
      return const <PyqContextualizedWeakSpot>[];
    }

    final totalWeight = deficiencyWeight + pyqWeight;
    final normDeficiency =
        totalWeight > 0 ? (deficiencyWeight / totalWeight) : 0.6;
    final normPyq = totalWeight > 0 ? (pyqWeight / totalWeight) : 0.4;

    final contextualized = <PyqContextualizedWeakSpot>[];
    for (final diag in weakSpotProfile.weakObjectives) {
      // Must satisfy P23 minimum evidence threshold to qualify
      if (diag.attemptCount < weakSpotProfile.minimumEvidenceThreshold) {
        continue;
      }

      final pyqSignal = priorityProfile.getObjectiveSignal(
        diag.objectiveId,
        learnerEvidenceCount: diag.attemptCount,
        learnerAccuracy: diag.observedAccuracy,
        currentWeakness: diag.deficiencyScore,
      );

      final composite = (diag.deficiencyScore * normDeficiency +
              pyqSignal.priorityScore * normPyq)
          .clamp(0.0, 1.0);

      contextualized.add(PyqContextualizedWeakSpot(
        diagnostic: diag,
        pyqSignal: pyqSignal,
        compositeRemedialScore: composite,
      ));
    }

    contextualized.sort((a, b) {
      final cmp = b.compositeRemedialScore.compareTo(a.compositeRemedialScore);
      if (cmp != 0) return cmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    return List.unmodifiable(contextualized);
  }

  /// Contextualizes weak spots and invokes P25 [remedialService] to bind remedial lessons.
  ///
  /// P25 retains 100% ownership of finding verified lessons and constructing bindings.
  Future<List<RemedialLessonBinding>> bindContextualizedRemedialLessons({
    required WeakSpotProfile weakSpotProfile,
    required PyqLearningPriorityProfile priorityProfile,
    required RemedialLessonService remedialService,
    int? maxLessons,
    DateTime? boundAt,
  }) async {
    final prioritized = prioritizeWeakSpots(
      weakSpotProfile: weakSpotProfile,
      priorityProfile: priorityProfile,
    );

    if (prioritized.isEmpty) {
      return const <RemedialLessonBinding>[];
    }

    final effectiveBoundAt = (boundAt ?? weakSpotProfile.evaluatedAt).toUtc();
    final bindings = <RemedialLessonBinding>[];

    for (final spot in prioritized) {
      if (maxLessons != null && bindings.length >= maxLessons) {
        break;
      }

      final lesson = await remedialService.findBestLessonForObjective(
        objectiveId: spot.objectiveId,
        targetBloomLevel: spot.diagnostic.bloomLevel,
      );

      if (lesson != null) {
        final bindingId =
            'bind_${weakSpotProfile.learnerId}_${spot.objectiveId}_${effectiveBoundAt.millisecondsSinceEpoch}';
        bindings.add(RemedialLessonBinding(
          bindingId: bindingId,
          learnerId: weakSpotProfile.learnerId,
          objectiveId: spot.objectiveId,
          lesson: lesson,
          trigger: RemedialBindingTrigger.weakSpotDiagnostic,
          deficiencyScore: spot.diagnostic.deficiencyScore,
          boundAt: effectiveBoundAt,
          metadata: {
            'pyqExamId': priorityProfile.examId,
            'pyqPriorityScore': spot.pyqSignal.priorityScore,
            'compositeRemedialScore': spot.compositeRemedialScore,
            'pyqRemediationContextualized': true,
          },
        ));
      }
    }

    return List.unmodifiable(bindings);
  }
}
