/// Learning Recommendation Entity (TITAN-KO-021.0 P21).
///
/// Immutable representation of a prioritized, evidence-backed next-learning-action
/// recommendation produced by the Adaptive Recommendation Engine.
library;

import 'package:meta/meta.dart';

import 'recommendation_type.dart';
import 'session_configuration.dart';

@immutable
class LearningRecommendation {
  /// Unique identifier for this recommendation instance.
  final String recommendationId;

  /// Target learner identifier.
  final String learnerId;

  /// Target P17 Learning Objective canonical identifier.
  final String objectiveId;

  /// Recommendation strategy classification.
  final RecommendationType type;

  /// Composite priority score bounded strictly in [0.0, 1.0].
  final double priorityScore;

  /// Human-readable, evidence-grounded rationale explaining the recommendation.
  final String rationale;

  /// Pre-configured turn-key P19 [SessionConfiguration] for immediate execution.
  final SessionConfiguration suggestedConfig;

  /// UTC timestamp when this recommendation was computed.
  final DateTime generatedAt;

  /// Additional diagnostic / evidence metadata.
  final Map<String, dynamic> metadata;

  LearningRecommendation({
    required this.recommendationId,
    required this.learnerId,
    required this.objectiveId,
    required this.type,
    required double priorityScore,
    required this.rationale,
    required this.suggestedConfig,
    DateTime? generatedAt,
    Map<String, dynamic>? metadata,
  })  : priorityScore = priorityScore.clamp(0.0, 1.0),
        generatedAt = (generatedAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {}) {
    if (recommendationId.trim().isEmpty) {
      throw ArgumentError('recommendationId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }
    if (rationale.trim().isEmpty) {
      throw ArgumentError('rationale cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'learnerId': learnerId,
        'objectiveId': objectiveId,
        'type': type.name,
        'priorityScore': priorityScore,
        'rationale': rationale,
        'suggestedConfig': suggestedConfig.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) =>
      LearningRecommendation(
        recommendationId: json['recommendationId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        type: RecommendationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => RecommendationType.curriculumAdvance,
        ),
        priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
        rationale: json['rationale'] as String? ?? '',
        suggestedConfig: SessionConfiguration.fromJson(
          Map<String, dynamic>.from(
              json['suggestedConfig'] as Map? ?? const {}),
        ),
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : null,
        metadata:
            Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningRecommendation &&
          recommendationId == other.recommendationId &&
          learnerId == other.learnerId &&
          objectiveId == other.objectiveId &&
          type == other.type &&
          (priorityScore - other.priorityScore).abs() < 0.0001 &&
          rationale == other.rationale &&
          suggestedConfig == other.suggestedConfig &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => Object.hash(
        recommendationId,
        learnerId,
        objectiveId,
        type,
        priorityScore,
        rationale,
        suggestedConfig,
        generatedAt,
      );

  @override
  String toString() =>
      'LearningRecommendation(id: $recommendationId, learner: $learnerId, obj: $objectiveId, type: ${type.name}, score: ${priorityScore.toStringAsFixed(3)})';
}
