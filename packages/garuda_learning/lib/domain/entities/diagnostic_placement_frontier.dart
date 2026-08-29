/// Diagnostic Placement Frontier Entity (TITAN-KO-026.0 P26).
///
/// Encapsulates the evidence-based knowledge frontier of a learner across
/// curriculum learning objectives.
///
/// Used directly by downstream modules:
/// - P24 Study Planner consumes [activeFrontierObjectiveIds] for prioritized agenda scheduling.
/// - P25 Remedial Framework consumes [remediationTargetObjectiveIds] for micro-lesson binding.
library;

import 'package:meta/meta.dart';

@immutable
class DiagnosticPlacementFrontier {
  /// The active learning frontier: objectives where prerequisites are demonstrated
  /// but the objective itself is developing, insufficient, or unassessed.
  final List<String> activeFrontierObjectiveIds;

  /// Objectives where demonstrated performance has been verified.
  final List<String> demonstratedObjectiveIds;

  /// Objectives with sufficient evidence where performance is currently developing.
  final List<String> developingObjectiveIds;

  /// Objectives with insufficient evidence or not yet assessed.
  final List<String> unassessedObjectiveIds;

  /// High-priority remediation targets (objectives with sufficient evidence but low accuracy).
  final List<String> remediationTargetObjectiveIds;

  DiagnosticPlacementFrontier({
    required List<String> activeFrontierObjectiveIds,
    required List<String> demonstratedObjectiveIds,
    required List<String> developingObjectiveIds,
    required List<String> unassessedObjectiveIds,
    required List<String> remediationTargetObjectiveIds,
  })  : activeFrontierObjectiveIds =
            List.unmodifiable(activeFrontierObjectiveIds),
        demonstratedObjectiveIds = List.unmodifiable(demonstratedObjectiveIds),
        developingObjectiveIds = List.unmodifiable(developingObjectiveIds),
        unassessedObjectiveIds = List.unmodifiable(unassessedObjectiveIds),
        remediationTargetObjectiveIds =
            List.unmodifiable(remediationTargetObjectiveIds);

  Map<String, dynamic> toJson() => {
        'activeFrontierObjectiveIds': activeFrontierObjectiveIds,
        'demonstratedObjectiveIds': demonstratedObjectiveIds,
        'developingObjectiveIds': developingObjectiveIds,
        'unassessedObjectiveIds': unassessedObjectiveIds,
        'remediationTargetObjectiveIds': remediationTargetObjectiveIds,
      };

  factory DiagnosticPlacementFrontier.fromJson(Map<String, dynamic> json) =>
      DiagnosticPlacementFrontier(
        activeFrontierObjectiveIds: List<String>.from(
            json['activeFrontierObjectiveIds'] as List? ?? []),
        demonstratedObjectiveIds:
            List<String>.from(json['demonstratedObjectiveIds'] as List? ?? []),
        developingObjectiveIds:
            List<String>.from(json['developingObjectiveIds'] as List? ?? []),
        unassessedObjectiveIds:
            List<String>.from(json['unassessedObjectiveIds'] as List? ?? []),
        remediationTargetObjectiveIds: List<String>.from(
            json['remediationTargetObjectiveIds'] as List? ?? []),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticPlacementFrontier &&
          runtimeType == other.runtimeType &&
          _listEquals(
              activeFrontierObjectiveIds, other.activeFrontierObjectiveIds) &&
          _listEquals(
              demonstratedObjectiveIds, other.demonstratedObjectiveIds) &&
          _listEquals(developingObjectiveIds, other.developingObjectiveIds) &&
          _listEquals(unassessedObjectiveIds, other.unassessedObjectiveIds) &&
          _listEquals(remediationTargetObjectiveIds,
              other.remediationTargetObjectiveIds);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(activeFrontierObjectiveIds),
        Object.hashAll(demonstratedObjectiveIds),
        Object.hashAll(developingObjectiveIds),
        Object.hashAll(unassessedObjectiveIds),
        Object.hashAll(remediationTargetObjectiveIds),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
