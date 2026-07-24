import 'package:meta/meta.dart';

/// Value object describing WHY a mentor recommendation was generated in TITAN AIME.
@immutable
class RecommendationReason {
  /// Category code identifying recommendation rationale (e.g., 'WEAK_AREA_REMEDIATION').
  final String code;

  /// Human-readable explanation of the recommendation rationale.
  final String explanation;

  /// Confidence or priority weight score between 0.0 and 1.0.
  final double weight;

  /// Arbitrary extensible key-value metadata.
  final Map<String, dynamic> metadata;

  /// Constructs an immutable [RecommendationReason].
  RecommendationReason({
    required this.code,
    required this.explanation,
    this.weight = 1.0,
    Map<String, dynamic> metadata = const {},
  })  : assert(weight >= 0.0 && weight <= 1.0,
            'weight must be between 0.0 and 1.0'),
        metadata = Map<String, dynamic>.unmodifiable(metadata);

  /// Standard factory for Weak Area Remediation reasons.
  factory RecommendationReason.weakAreaRemediation({
    required String topic,
    double weight = 0.95,
  }) {
    return RecommendationReason(
      code: 'WEAK_AREA_REMEDIATION',
      explanation: 'Targeted remediation for identified weak topic: $topic.',
      weight: weight,
      metadata: {'targetTopic': topic},
    );
  }

  /// Standard factory for Next Topic Progression reasons.
  factory RecommendationReason.nextTopicProgression({
    required String completedTopic,
    double weight = 0.85,
  }) {
    return RecommendationReason(
      code: 'NEXT_TOPIC_PROGRESSION',
      explanation:
          'Logical progression building upon completed topic: $completedTopic.',
      weight: weight,
      metadata: {'completedTopic': completedTopic},
    );
  }

  /// Standard factory for Prerequisite Gap reasons.
  factory RecommendationReason.prerequisiteGap({
    required String targetTopic,
    double weight = 0.90,
  }) {
    return RecommendationReason(
      code: 'PREREQUISITE_GAP',
      explanation:
          'Essential prerequisite required prior to studying $targetTopic.',
      weight: weight,
      metadata: {'targetTopic': targetTopic},
    );
  }

  /// Standard factory for Revision Due reasons.
  factory RecommendationReason.revisionDue({
    required String topic,
    double weight = 0.80,
  }) {
    return RecommendationReason(
      code: 'REVISION_DUE',
      explanation: 'Scheduled revision cycle due for topic: $topic.',
      weight: weight,
      metadata: {'targetTopic': topic},
    );
  }

  /// Creates a copy of this [RecommendationReason] with updated fields.
  RecommendationReason copyWith({
    String? code,
    String? explanation,
    double? weight,
    Map<String, dynamic>? metadata,
  }) {
    return RecommendationReason(
      code: code ?? this.code,
      explanation: explanation ?? this.explanation,
      weight: weight ?? this.weight,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this [RecommendationReason] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'explanation': explanation,
      'weight': weight,
      'metadata': metadata,
    };
  }

  /// Deserializes a [RecommendationReason] from a Map.
  factory RecommendationReason.fromMap(Map<String, dynamic> map) {
    return RecommendationReason(
      code: (map['code'] as String?) ?? 'GENERAL_RECOMMENDATION',
      explanation: (map['explanation'] as String?) ?? '',
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : 1.0,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecommendationReason &&
        other.code == code &&
        other.explanation == explanation &&
        other.weight == weight &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      code,
      explanation,
      weight,
      Object.hashAll(metadata.keys),
      Object.hashAll(metadata.values),
    );
  }

  @override
  String toString() {
    return 'RecommendationReason(code: $code, weight: $weight, explanation: $explanation)';
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
