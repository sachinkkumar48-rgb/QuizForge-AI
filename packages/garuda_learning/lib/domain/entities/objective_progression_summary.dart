/// Objective Progression Summary Domain Entity (TITAN-KO-044.0 P44).
///
/// Encapsulates the quantitative deltas, qualitative state transition,
/// statistical confidence, and auditable rationale for an individual
/// learning objective following an activity evaluation.
library;

import 'package:meta/meta.dart';

import 'objective_mastery_status.dart';

@immutable
class ObjectiveProgressionSummary {
  /// Canonical learning objective identifier.
  final String objectiveId;

  /// Objective mastery status prior to this activity evaluation.
  final ObjectiveMasteryStatus priorStatus;

  /// Objective mastery status after incorporating new evidence.
  final ObjectiveMasteryStatus newStatus;

  /// Qualitative transition classification.
  final ObjectiveTransitionType transitionType;

  /// Total attempts prior to this evaluation.
  final int priorAttempts;

  /// New attempts submitted in the completed activity.
  final int newAttempts;

  /// Cumulative attempts after this evaluation.
  final int totalAttempts;

  /// Total correct attempts prior to this evaluation.
  final int priorCorrect;

  /// New correct attempts in the completed activity.
  final int newCorrect;

  /// Cumulative correct attempts after this evaluation.
  final int totalCorrect;

  /// Prior success rate in range [0.0, 1.0].
  final double priorSuccessRate;

  /// Updated success rate in range [0.0, 1.0].
  final double newSuccessRate;

  /// Statistical confidence score in range [0.0, 1.0] reflecting evidence volume
  /// and consistency.
  final double confidenceScore;

  /// Auditable pedagogical explanation for the transition.
  final String rationale;

  ObjectiveProgressionSummary({
    required String objectiveId,
    required this.priorStatus,
    required this.newStatus,
    required this.transitionType,
    this.priorAttempts = 0,
    this.newAttempts = 0,
    required this.totalAttempts,
    this.priorCorrect = 0,
    this.newCorrect = 0,
    required this.totalCorrect,
    this.priorSuccessRate = 0.0,
    required this.newSuccessRate,
    required this.confidenceScore,
    required this.rationale,
  })  : objectiveId = objectiveId.trim(),
        assert(priorAttempts >= 0, 'priorAttempts cannot be negative'),
        assert(newAttempts >= 0, 'newAttempts cannot be negative'),
        assert(priorCorrect >= 0, 'priorCorrect cannot be negative'),
        assert(newCorrect >= 0, 'newCorrect cannot be negative'),
        assert(priorSuccessRate >= 0.0 && priorSuccessRate <= 1.0,
            'priorSuccessRate must be in [0.0, 1.0]'),
        assert(newSuccessRate >= 0.0 && newSuccessRate <= 1.0,
            'newSuccessRate must be in [0.0, 1.0]'),
        assert(confidenceScore >= 0.0 && confidenceScore <= 1.0,
            'confidenceScore must be in [0.0, 1.0]') {
    if (objectiveId.isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }
    if (totalAttempts < 0) {
      throw ArgumentError('totalAttempts cannot be negative');
    }
    if (totalCorrect < 0 || totalCorrect > totalAttempts) {
      throw ArgumentError(
          'totalCorrect ($totalCorrect) must be between 0 and totalAttempts ($totalAttempts)');
    }
  }

  /// Whether this objective is currently mastered.
  bool get isMastered => newStatus.isMastered;

  /// Whether this objective is currently flagged as struggling.
  bool get isStruggling => newStatus.isStruggling;

  /// Whether this objective has sufficient evidence for confident decisions.
  bool get hasSufficientEvidence =>
      newStatus != ObjectiveMasteryStatus.notAttempted &&
      newStatus != ObjectiveMasteryStatus.insufficientEvidence;

  /// Absolute success rate delta (positive indicates improvement).
  double get successRateDelta => newSuccessRate - priorSuccessRate;

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'priorStatus': priorStatus.name,
        'newStatus': newStatus.name,
        'transitionType': transitionType.name,
        'priorAttempts': priorAttempts,
        'newAttempts': newAttempts,
        'totalAttempts': totalAttempts,
        'priorCorrect': priorCorrect,
        'newCorrect': newCorrect,
        'totalCorrect': totalCorrect,
        'priorSuccessRate': priorSuccessRate,
        'newSuccessRate': newSuccessRate,
        'confidenceScore': confidenceScore,
        'rationale': rationale,
      };

  factory ObjectiveProgressionSummary.fromJson(Map<String, dynamic> json) {
    return ObjectiveProgressionSummary(
      objectiveId: json['objectiveId'] as String? ?? '',
      priorStatus: ObjectiveMasteryStatus.values.firstWhere(
        (e) => e.name == json['priorStatus'],
        orElse: () => ObjectiveMasteryStatus.notAttempted,
      ),
      newStatus: ObjectiveMasteryStatus.values.firstWhere(
        (e) => e.name == json['newStatus'],
        orElse: () => ObjectiveMasteryStatus.notAttempted,
      ),
      transitionType: ObjectiveTransitionType.values.firstWhere(
        (e) => e.name == json['transitionType'],
        orElse: () => ObjectiveTransitionType.unchanged,
      ),
      priorAttempts: json['priorAttempts'] as int? ?? 0,
      newAttempts: json['newAttempts'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      priorCorrect: json['priorCorrect'] as int? ?? 0,
      newCorrect: json['newCorrect'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      priorSuccessRate: (json['priorSuccessRate'] as num?)?.toDouble() ?? 0.0,
      newSuccessRate: (json['newSuccessRate'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      rationale: json['rationale'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjectiveProgressionSummary &&
          runtimeType == other.runtimeType &&
          objectiveId == other.objectiveId &&
          priorStatus == other.priorStatus &&
          newStatus == other.newStatus &&
          transitionType == other.transitionType &&
          priorAttempts == other.priorAttempts &&
          newAttempts == other.newAttempts &&
          totalAttempts == other.totalAttempts &&
          priorCorrect == other.priorCorrect &&
          newCorrect == other.newCorrect &&
          totalCorrect == other.totalCorrect &&
          priorSuccessRate == other.priorSuccessRate &&
          newSuccessRate == other.newSuccessRate &&
          confidenceScore == other.confidenceScore &&
          rationale == other.rationale;

  @override
  int get hashCode => Object.hash(
        objectiveId,
        priorStatus,
        newStatus,
        transitionType,
        priorAttempts,
        newAttempts,
        totalAttempts,
        priorCorrect,
        newCorrect,
        totalCorrect,
        priorSuccessRate,
        newSuccessRate,
        confidenceScore,
        rationale,
      );

  @override
  String toString() =>
      'ObjectiveProgressionSummary(obj: $objectiveId, $priorStatus -> $newStatus ($transitionType), '
      'att: $totalAttempts, rate: ${(newSuccessRate * 100).toStringAsFixed(1)}%, conf: ${(confidenceScore * 100).toStringAsFixed(1)}%)';
}
