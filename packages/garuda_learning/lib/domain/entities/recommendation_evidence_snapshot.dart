/// Recommendation Evidence Snapshot (TITAN-KO-022.0 P22).
///
/// Immutable value object capturing a compact audit snapshot of the learning
/// evidence state at the time a [RecommendationInstance] is issued.
///
/// This entity records evidence — it does NOT:
/// - Recalculate P18 assessment results.
/// - Create a second spaced-repetition scheduler (P20).
/// - Generate P21 recommendations.
/// - Make causal mastery claims.
///
/// Educational Safety Principles:
/// - Null/unknown semantics are preserved for unavailable metrics.
/// - Missing baseline attempts result in `baselineAccuracy: null`, not fabricated zeroes.
/// - `baselineStatus` is read-only from P18 [LearnerObjectiveStatus].
library;

import 'package:meta/meta.dart';

import 'learner_objective_status.dart';

/// Immutable issuance-time evidence snapshot for P22 recommendation lifecycle.
///
/// Fields correspond to the P21 factor weights captured at issuance time:
/// - [reviewUrgencyFactor]: P20 SM-2 review urgency signal.
/// - [prerequisiteBlockerFactor]: P17 prerequisite graph blocker weight.
/// - [weakDomainFactor]: P18 weak-domain identification weight.
/// - [curriculumAdvancementFactor]: P17 curriculum progression weight.
/// - [practiceDensityFactor]: P18/P19 practice density weight.
/// - [baselineAccuracy]: P18 pre-issuance accuracy, null if zero attempts.
/// - [baselineAttemptsCount]: P18 pre-issuance attempt count.
/// - [baselineStatus]: P18 [LearnerObjectiveStatus] at issuance time.
@immutable
class RecommendationEvidenceSnapshot {
  /// P20 SM-2 review urgency factor weight at issuance.
  final double reviewUrgencyFactor;

  /// P17 prerequisite blocker factor weight at issuance.
  final double prerequisiteBlockerFactor;

  /// P18 weak-domain identification factor weight at issuance.
  final double weakDomainFactor;

  /// P17 curriculum advancement factor weight at issuance.
  final double curriculumAdvancementFactor;

  /// P18/P19 practice density factor weight at issuance.
  final double practiceDensityFactor;

  /// P18 baseline accuracy prior to issuance, or null if zero attempts.
  ///
  /// A null value indicates no baseline accuracy data is available;
  /// it does NOT mean the learner has zero accuracy. Callers must
  /// distinguish null (unknown) from 0.0 (zero accuracy on attempted items).
  final double? baselineAccuracy;

  /// P18 total baseline attempt count at issuance time.
  ///
  /// Zero indicates no attempts were recorded prior to issuance.
  final int baselineAttemptsCount;

  /// P18 [LearnerObjectiveStatus] observed at issuance time.
  final LearnerObjectiveStatus baselineStatus;

  RecommendationEvidenceSnapshot({
    required double reviewUrgencyFactor,
    required double prerequisiteBlockerFactor,
    required double weakDomainFactor,
    required double curriculumAdvancementFactor,
    required double practiceDensityFactor,
    this.baselineAccuracy,
    required this.baselineAttemptsCount,
    required this.baselineStatus,
  })  : reviewUrgencyFactor = reviewUrgencyFactor.clamp(0.0, 1.0),
        prerequisiteBlockerFactor = prerequisiteBlockerFactor.clamp(0.0, 1.0),
        weakDomainFactor = weakDomainFactor.clamp(0.0, 1.0),
        curriculumAdvancementFactor =
            curriculumAdvancementFactor.clamp(0.0, 1.0),
        practiceDensityFactor = practiceDensityFactor.clamp(0.0, 1.0) {
    if (baselineAttemptsCount < 0) {
      throw ArgumentError(
        'baselineAttemptsCount cannot be negative (got $baselineAttemptsCount)',
      );
    }
    if (baselineAccuracy != null &&
        (baselineAccuracy! < 0.0 || baselineAccuracy! > 1.0)) {
      throw ArgumentError(
        'baselineAccuracy must be in [0.0, 1.0] or null (got $baselineAccuracy)',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'reviewUrgencyFactor': reviewUrgencyFactor,
        'prerequisiteBlockerFactor': prerequisiteBlockerFactor,
        'weakDomainFactor': weakDomainFactor,
        'curriculumAdvancementFactor': curriculumAdvancementFactor,
        'practiceDensityFactor': practiceDensityFactor,
        if (baselineAccuracy != null) 'baselineAccuracy': baselineAccuracy,
        'baselineAttemptsCount': baselineAttemptsCount,
        'baselineStatus': baselineStatus.name,
      };

  factory RecommendationEvidenceSnapshot.fromJson(
    Map<String, dynamic> json,
  ) =>
      RecommendationEvidenceSnapshot(
        reviewUrgencyFactor:
            (json['reviewUrgencyFactor'] as num?)?.toDouble() ?? 0.0,
        prerequisiteBlockerFactor:
            (json['prerequisiteBlockerFactor'] as num?)?.toDouble() ?? 0.0,
        weakDomainFactor: (json['weakDomainFactor'] as num?)?.toDouble() ?? 0.0,
        curriculumAdvancementFactor:
            (json['curriculumAdvancementFactor'] as num?)?.toDouble() ?? 0.0,
        practiceDensityFactor:
            (json['practiceDensityFactor'] as num?)?.toDouble() ?? 0.0,
        baselineAccuracy: (json['baselineAccuracy'] as num?)?.toDouble(),
        baselineAttemptsCount:
            (json['baselineAttemptsCount'] as num?)?.toInt() ?? 0,
        baselineStatus: LearnerObjectiveStatus.values.firstWhere(
          (s) => s.name == json['baselineStatus'],
          orElse: () => LearnerObjectiveStatus.notStarted,
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationEvidenceSnapshot &&
          (reviewUrgencyFactor - other.reviewUrgencyFactor).abs() < 0.0001 &&
          (prerequisiteBlockerFactor - other.prerequisiteBlockerFactor).abs() <
              0.0001 &&
          (weakDomainFactor - other.weakDomainFactor).abs() < 0.0001 &&
          (curriculumAdvancementFactor - other.curriculumAdvancementFactor)
                  .abs() <
              0.0001 &&
          (practiceDensityFactor - other.practiceDensityFactor).abs() <
              0.0001 &&
          ((baselineAccuracy == null && other.baselineAccuracy == null) ||
              (baselineAccuracy != null &&
                  other.baselineAccuracy != null &&
                  (baselineAccuracy! - other.baselineAccuracy!).abs() <
                      0.0001)) &&
          baselineAttemptsCount == other.baselineAttemptsCount &&
          baselineStatus == other.baselineStatus;

  @override
  int get hashCode => Object.hash(
        reviewUrgencyFactor,
        prerequisiteBlockerFactor,
        weakDomainFactor,
        curriculumAdvancementFactor,
        practiceDensityFactor,
        baselineAccuracy,
        baselineAttemptsCount,
        baselineStatus,
      );

  @override
  String toString() =>
      'RecommendationEvidenceSnapshot(urgency: ${reviewUrgencyFactor.toStringAsFixed(3)}, prereq: ${prerequisiteBlockerFactor.toStringAsFixed(3)}, weak: ${weakDomainFactor.toStringAsFixed(3)}, advance: ${curriculumAdvancementFactor.toStringAsFixed(3)}, density: ${practiceDensityFactor.toStringAsFixed(3)}, baselineAcc: $baselineAccuracy, attempts: $baselineAttemptsCount, status: ${baselineStatus.name})';
}
