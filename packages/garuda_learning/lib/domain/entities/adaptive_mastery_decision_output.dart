/// Adaptive Mastery Decision Output Domain Entity (TITAN-KO-040.0 P40).
///
/// Encapsulates deterministic decision signals extracted from topic mastery profiles
/// to guide downstream question selection, remediation triggering, and difficulty pacing.
library;

import 'package:meta/meta.dart';

import 'mastery_classification.dart';

/// Clean deterministic decision container derived from topic mastery states.
@immutable
class AdaptiveMasteryDecisionOutput {
  /// Topics ordered from lowest to highest mastery score.
  final List<String> weakestTopics;

  /// Topics ordered from highest to lowest mastery score.
  final List<String> strongestTopics;

  /// Topics in 'emerging' or low-accuracy developing states requiring targeted remediation.
  final List<String> remediationRequiredTopics;

  /// Topics in 'developing' or 'proficient' states near the mastery threshold.
  final List<String> approachingMasteryTopics;

  /// Topics with low evidence or confidence needing diagnostic or practice exposure.
  final List<String> insufficientEvidenceTopics;

  /// Recommended difficulty level ('Easy', 'Medium', 'Hard') per topic.
  final Map<String, String> recommendedDifficultyBand;

  /// Count of evaluated topics per mastery classification.
  final Map<MasteryClassification, int> masteryDistribution;

  /// Mean mastery score across all evaluated topics, or 0.0 if empty.
  final double overallMasteryScore;

  /// Mean statistical confidence across all evaluated topics, or 0.0 if empty.
  final double overallConfidence;

  AdaptiveMasteryDecisionOutput({
    required List<String> weakestTopics,
    required List<String> strongestTopics,
    required List<String> remediationRequiredTopics,
    required List<String> approachingMasteryTopics,
    required List<String> insufficientEvidenceTopics,
    required Map<String, String> recommendedDifficultyBand,
    required Map<MasteryClassification, int> masteryDistribution,
    required this.overallMasteryScore,
    required this.overallConfidence,
  })  : weakestTopics = List.unmodifiable(weakestTopics),
        strongestTopics = List.unmodifiable(strongestTopics),
        remediationRequiredTopics =
            List.unmodifiable(remediationRequiredTopics),
        approachingMasteryTopics = List.unmodifiable(approachingMasteryTopics),
        insufficientEvidenceTopics =
            List.unmodifiable(insufficientEvidenceTopics),
        recommendedDifficultyBand = Map.unmodifiable(recommendedDifficultyBand),
        masteryDistribution = Map.unmodifiable(masteryDistribution);

  Map<String, dynamic> toJson() => {
        'weakestTopics': weakestTopics,
        'strongestTopics': strongestTopics,
        'remediationRequiredTopics': remediationRequiredTopics,
        'approachingMasteryTopics': approachingMasteryTopics,
        'insufficientEvidenceTopics': insufficientEvidenceTopics,
        'recommendedDifficultyBand': recommendedDifficultyBand,
        'masteryDistribution': masteryDistribution.map(
          (key, value) => MapEntry(key.toJson(), value),
        ),
        'overallMasteryScore': overallMasteryScore,
        'overallConfidence': overallConfidence,
      };

  factory AdaptiveMasteryDecisionOutput.fromJson(Map<String, dynamic> json) {
    final distJson = json['masteryDistribution'] as Map<String, dynamic>? ?? {};
    final dist = <MasteryClassification, int>{};
    for (final entry in distJson.entries) {
      final key = MasteryClassification.fromJson(entry.key);
      dist[key] = (entry.value as num?)?.toInt() ?? 0;
    }

    return AdaptiveMasteryDecisionOutput(
      weakestTopics: (json['weakestTopics'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      strongestTopics: (json['strongestTopics'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      remediationRequiredTopics:
          (json['remediationRequiredTopics'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      approachingMasteryTopics:
          (json['approachingMasteryTopics'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      insufficientEvidenceTopics:
          (json['insufficientEvidenceTopics'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      recommendedDifficultyBand:
          (json['recommendedDifficultyBand'] as Map<String, dynamic>? ??
                  const {})
              .map((k, v) => MapEntry(k, v as String)),
      masteryDistribution: dist,
      overallMasteryScore:
          (json['overallMasteryScore'] as num?)?.toDouble() ?? 0.0,
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'AdaptiveMasteryDecisionOutput(overallScore: ${overallMasteryScore.toStringAsFixed(2)}, conf: ${overallConfidence.toStringAsFixed(2)}, weakest: $weakestTopics)';
}
