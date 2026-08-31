/// Adaptive PYQ Diagnostic Placement Adapter (TITAN-KO-032.0 P32 -> P26).
///
/// Contextualizes P26 diagnostic placement frontiers with P31/P32 historical PYQ
/// representation to guide diagnostic assessment sequencing.
///
/// Educational Safety & Ownership Invariants:
/// - P26 retains 100% ownership of diagnostic placement status and correctness.
/// - P32 NEVER modifies diagnostic correctness, accuracy, or evidence states.
/// - Historical PYQ coverage is strictly contextual:
///   - PYQ evidence: "this objective historically occurred X times in exam Y."
///   - Learner evidence: "this learner demonstrated accuracy Z across N attempts."
/// - Historical PYQ counts are NEVER merged into fake learner scores.
library;

import 'package:meta/meta.dart';

import '../domain/entities/diagnostic_evidence_state.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/diagnostic_placement_status.dart';
import '../domain/entities/pyq_learning_priority_profile.dart';

/// Contextual wrapper pairing a single diagnostic objective with its historical PYQ evidence.
@immutable
class PyqContextualizedFrontierObjective {
  final String objectiveId;
  final DiagnosticPlacementStatus placementStatus;
  final DiagnosticEvidenceState evidenceState;
  final double? observedLearnerAccuracy;
  final int attemptsCount;
  final int historicalQuestionCount;
  final double historicalShare;
  final int yearsObserved;
  final double pyqPriorityScore;
  final double evidenceConfidence;
  final bool hasSufficientHistoricalEvidence;
  final String notes;

  const PyqContextualizedFrontierObjective({
    required this.objectiveId,
    required this.placementStatus,
    required this.evidenceState,
    this.observedLearnerAccuracy,
    required this.attemptsCount,
    required this.historicalQuestionCount,
    required this.historicalShare,
    required this.yearsObserved,
    required this.pyqPriorityScore,
    required this.evidenceConfidence,
    required this.hasSufficientHistoricalEvidence,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'placementStatus': placementStatus.name,
        'evidenceState': evidenceState.name,
        if (observedLearnerAccuracy != null)
          'observedLearnerAccuracy': observedLearnerAccuracy,
        'attemptsCount': attemptsCount,
        'historicalQuestionCount': historicalQuestionCount,
        'historicalShare': historicalShare,
        'yearsObserved': yearsObserved,
        'pyqPriorityScore': pyqPriorityScore,
        'evidenceConfidence': evidenceConfidence,
        'hasSufficientHistoricalEvidence': hasSufficientHistoricalEvidence,
        'notes': notes,
      };
}

/// Comprehensive wrapper holding P26 diagnostic result alongside P32 PYQ priority context.
@immutable
class PyqContextualizedDiagnosticResult {
  /// Authoritative untouched P26 diagnostic placement result.
  final DiagnosticPlacementResult placementResult;

  /// P32 PYQ priority profile used for contextualization.
  final PyqLearningPriorityProfile priorityProfile;

  /// Active frontier objective IDs ordered by historical PYQ priority (score DESC, id ASC).
  final List<String> prioritizedActiveFrontierIds;

  /// Unassessed objective IDs ordered by historical PYQ priority (score DESC, id ASC).
  final List<String> prioritizedUnassessedObjectiveIds;

  /// Detailed contextualized objective entries for all targets.
  final List<PyqContextualizedFrontierObjective> contextualizedObjectives;

  const PyqContextualizedDiagnosticResult({
    required this.placementResult,
    required this.priorityProfile,
    required this.prioritizedActiveFrontierIds,
    required this.prioritizedUnassessedObjectiveIds,
    required this.contextualizedObjectives,
  });

  String get learnerId => placementResult.learnerId;
  String get assessmentId => placementResult.assessmentId;
  String get examId => priorityProfile.examId;

  Map<String, dynamic> toJson() => {
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        'examId': examId,
        'prioritizedActiveFrontierIds': prioritizedActiveFrontierIds,
        'prioritizedUnassessedObjectiveIds': prioritizedUnassessedObjectiveIds,
        'contextualizedObjectives':
            contextualizedObjectives.map((o) => o.toJson()).toList(),
        'placementResult': placementResult.toJson(),
      };
}

/// Adapter contextualizing P26 diagnostic placements with P32 PYQ intelligence.
class PyqDiagnosticAdapter {
  const PyqDiagnosticAdapter();

  /// Contextualizes a [DiagnosticPlacementResult] from P26 with [priorityProfile] from P32.
  ///
  /// Safe: Never modifies diagnostic correctness, accuracy, or evidence states.
  PyqContextualizedDiagnosticResult contextualizePlacementResult({
    required DiagnosticPlacementResult placementResult,
    required PyqLearningPriorityProfile priorityProfile,
  }) {
    final objectiveEntries = <PyqContextualizedFrontierObjective>[];

    // 1. Process each assessed objective in the diagnostic result
    for (final entry in placementResult.objectiveResults.entries) {
      final objId = entry.key;
      final diagResult = entry.value;

      final pyqSignal = priorityProfile.getObjectiveSignal(
        objId,
        learnerEvidenceCount: diagResult.attemptsCount,
        learnerAccuracy: diagResult.observedAccuracy,
        currentWeakness: diagResult.observedAccuracy != null
            ? (1.0 - diagResult.observedAccuracy!).clamp(0.0, 1.0)
            : 0.0,
      );

      final notes =
          'Learner: ${diagResult.placementStatus.name} (${diagResult.attemptsCount} attempts, accuracy: ${diagResult.observedAccuracy != null ? (diagResult.observedAccuracy! * 100).toStringAsFixed(1) : "N/A"}%). PYQ: ${pyqSignal.historicalQuestionCount} question(s) observed across ${pyqSignal.yearsObserved} year(s) in ${priorityProfile.examId.toUpperCase()}.';

      objectiveEntries.add(PyqContextualizedFrontierObjective(
        objectiveId: objId,
        placementStatus: diagResult.placementStatus,
        evidenceState: diagResult.evidenceState,
        observedLearnerAccuracy: diagResult.observedAccuracy,
        attemptsCount: diagResult.attemptsCount,
        historicalQuestionCount: pyqSignal.historicalQuestionCount,
        historicalShare: pyqSignal.historicalShare,
        yearsObserved: pyqSignal.yearsObserved,
        pyqPriorityScore: pyqSignal.priorityScore,
        evidenceConfidence: pyqSignal.evidenceConfidence,
        hasSufficientHistoricalEvidence:
            pyqSignal.hasSufficientHistoricalEvidence,
        notes: notes,
      ));
    }

    // 2. Prioritize active frontier objective IDs by PYQ priority score DESC, id ASC
    final prioritizedFrontier =
        List<String>.from(placementResult.frontier.activeFrontierObjectiveIds);
    prioritizedFrontier.sort((a, b) {
      final scoreA = priorityProfile.getObjectiveSignal(a).priorityScore;
      final scoreB = priorityProfile.getObjectiveSignal(b).priorityScore;
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.compareTo(b);
    });

    // 3. Prioritize unassessed objective IDs by PYQ priority score DESC, id ASC
    final prioritizedUnassessed =
        List<String>.from(placementResult.frontier.unassessedObjectiveIds);
    prioritizedUnassessed.sort((a, b) {
      final scoreA = priorityProfile.getObjectiveSignal(a).priorityScore;
      final scoreB = priorityProfile.getObjectiveSignal(b).priorityScore;
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.compareTo(b);
    });

    return PyqContextualizedDiagnosticResult(
      placementResult: placementResult,
      priorityProfile: priorityProfile,
      prioritizedActiveFrontierIds: List.unmodifiable(prioritizedFrontier),
      prioritizedUnassessedObjectiveIds:
          List.unmodifiable(prioritizedUnassessed),
      contextualizedObjectives: List.unmodifiable(objectiveEntries),
    );
  }
}
