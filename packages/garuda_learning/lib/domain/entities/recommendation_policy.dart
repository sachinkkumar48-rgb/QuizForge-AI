/// Recommendation Policy Value Object (TITAN-KO-021.0 P21).
///
/// Configuration descriptor governing recommendation multi-factor weighting,
/// thresholds, cold-start protections, and scoping filters.
library;

import 'package:meta/meta.dart';

@immutable
class RecommendationPolicy {
  /// Weight $w_1$ for Spaced Repetition urgency factor $U_{review}$ (Default: 0.35).
  final double weightSpacedReview;

  /// Weight $w_2$ for Prerequisite blocker severity factor $S_{prereq}$ (Default: 0.25).
  final double weightPrerequisiteGap;

  /// Weight $w_3$ for Weak Domain accuracy gap factor $G_{weak}$ (Default: 0.20).
  final double weightWeakDomain;

  /// Weight $w_4$ for Curriculum advancement factor $P_{curric}$ (Default: 0.10).
  final double weightCurriculumAdvance;

  /// Weight $w_5$ for Practice Question density factor $H_{density}$ (Default: 0.10).
  final double weightPracticeDensity;

  /// Maximum number of recommendations to return (Default: 10).
  final int maxRecommendations;

  /// Accuracy threshold below which a domain is flagged as weak (Default: 0.60).
  final double weakDomainThreshold;

  /// Minimum question attempts required in a domain before evaluating accuracy (Default: 3).
  final int minDomainAttempts;

  /// Optional domain identifier filter.
  final String? targetDomainId;

  /// Optional unit identifier filter.
  final String? targetUnitId;

  const RecommendationPolicy({
    this.weightSpacedReview = 0.35,
    this.weightPrerequisiteGap = 0.25,
    this.weightWeakDomain = 0.20,
    this.weightCurriculumAdvance = 0.10,
    this.weightPracticeDensity = 0.10,
    this.maxRecommendations = 10,
    this.weakDomainThreshold = 0.60,
    this.minDomainAttempts = 3,
    this.targetDomainId,
    this.targetUnitId,
  })  : assert(weightSpacedReview >= 0.0, 'weightSpacedReview must be >= 0.0'),
        assert(weightPrerequisiteGap >= 0.0,
            'weightPrerequisiteGap must be >= 0.0'),
        assert(weightWeakDomain >= 0.0, 'weightWeakDomain must be >= 0.0'),
        assert(weightCurriculumAdvance >= 0.0,
            'weightCurriculumAdvance must be >= 0.0'),
        assert(weightPracticeDensity >= 0.0,
            'weightPracticeDensity must be >= 0.0'),
        assert(maxRecommendations > 0, 'maxRecommendations must be > 0'),
        assert(weakDomainThreshold >= 0.0 && weakDomainThreshold <= 1.0,
            'weakDomainThreshold must be between 0.0 and 1.0'),
        assert(minDomainAttempts >= 1, 'minDomainAttempts must be >= 1');

  /// Sum of all component factor weights.
  double get totalWeight =>
      weightSpacedReview +
      weightPrerequisiteGap +
      weightWeakDomain +
      weightCurriculumAdvance +
      weightPracticeDensity;

  Map<String, dynamic> toJson() => {
        'weightSpacedReview': weightSpacedReview,
        'weightPrerequisiteGap': weightPrerequisiteGap,
        'weightWeakDomain': weightWeakDomain,
        'weightCurriculumAdvance': weightCurriculumAdvance,
        'weightPracticeDensity': weightPracticeDensity,
        'maxRecommendations': maxRecommendations,
        'weakDomainThreshold': weakDomainThreshold,
        'minDomainAttempts': minDomainAttempts,
        if (targetDomainId != null) 'targetDomainId': targetDomainId,
        if (targetUnitId != null) 'targetUnitId': targetUnitId,
      };

  factory RecommendationPolicy.fromJson(Map<String, dynamic> json) =>
      RecommendationPolicy(
        weightSpacedReview:
            (json['weightSpacedReview'] as num?)?.toDouble() ?? 0.35,
        weightPrerequisiteGap:
            (json['weightPrerequisiteGap'] as num?)?.toDouble() ?? 0.25,
        weightWeakDomain:
            (json['weightWeakDomain'] as num?)?.toDouble() ?? 0.20,
        weightCurriculumAdvance:
            (json['weightCurriculumAdvance'] as num?)?.toDouble() ?? 0.10,
        weightPracticeDensity:
            (json['weightPracticeDensity'] as num?)?.toDouble() ?? 0.10,
        maxRecommendations: json['maxRecommendations'] as int? ?? 10,
        weakDomainThreshold:
            (json['weakDomainThreshold'] as num?)?.toDouble() ?? 0.60,
        minDomainAttempts: json['minDomainAttempts'] as int? ?? 3,
        targetDomainId: json['targetDomainId'] as String?,
        targetUnitId: json['targetUnitId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationPolicy &&
          (weightSpacedReview - other.weightSpacedReview).abs() < 0.0001 &&
          (weightPrerequisiteGap - other.weightPrerequisiteGap).abs() <
              0.0001 &&
          (weightWeakDomain - other.weightWeakDomain).abs() < 0.0001 &&
          (weightCurriculumAdvance - other.weightCurriculumAdvance).abs() <
              0.0001 &&
          (weightPracticeDensity - other.weightPracticeDensity).abs() <
              0.0001 &&
          maxRecommendations == other.maxRecommendations &&
          (weakDomainThreshold - other.weakDomainThreshold).abs() < 0.0001 &&
          minDomainAttempts == other.minDomainAttempts &&
          targetDomainId == other.targetDomainId &&
          targetUnitId == other.targetUnitId;

  @override
  int get hashCode => Object.hash(
        weightSpacedReview,
        weightPrerequisiteGap,
        weightWeakDomain,
        weightCurriculumAdvance,
        weightPracticeDensity,
        maxRecommendations,
        weakDomainThreshold,
        minDomainAttempts,
        targetDomainId,
        targetUnitId,
      );

  @override
  String toString() =>
      'RecommendationPolicy(weights: [${weightSpacedReview.toStringAsFixed(2)}, ${weightPrerequisiteGap.toStringAsFixed(2)}, ${weightWeakDomain.toStringAsFixed(2)}, ${weightCurriculumAdvance.toStringAsFixed(2)}, ${weightPracticeDensity.toStringAsFixed(2)}], max: $maxRecommendations, minAttempts: $minDomainAttempts)';
}
