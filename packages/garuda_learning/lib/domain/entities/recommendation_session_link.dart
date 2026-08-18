/// Recommendation Session Link Entity (TITAN-KO-022.0 P22).
///
/// Immutable domain model providing decoupled provenance between a P22
/// [RecommendationInstance] and a P19 [LearningSession], supporting 1-to-many
/// execution mapping (e.g. retries, multi-part practice) without mutating P19.
library;

import 'package:meta/meta.dart';

@immutable
class RecommendationSessionLink {
  /// Unique identifier for this provenance link.
  final String linkId;

  /// Originating [RecommendationInstance.instanceId].
  final String instanceId;

  /// Linked P19 [LearningSession.sessionId].
  final String sessionId;

  /// UTC timestamp when the link was established.
  final DateTime linkedAt;

  /// Optional immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  RecommendationSessionLink({
    required this.linkId,
    required this.instanceId,
    required this.sessionId,
    required DateTime linkedAt,
    Map<String, dynamic>? metadata,
  })  : linkedAt = linkedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (linkId.trim().isEmpty) {
      throw ArgumentError('linkId cannot be empty');
    }
    if (instanceId.trim().isEmpty) {
      throw ArgumentError('instanceId cannot be empty');
    }
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'linkId': linkId,
        'instanceId': instanceId,
        'sessionId': sessionId,
        'linkedAt': linkedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory RecommendationSessionLink.fromJson(Map<String, dynamic> json) =>
      RecommendationSessionLink(
        linkId: json['linkId'] as String? ?? '',
        instanceId: json['instanceId'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        linkedAt: DateTime.parse(json['linkedAt'] as String).toUtc(),
        metadata:
            Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationSessionLink &&
          linkId == other.linkId &&
          instanceId == other.instanceId &&
          sessionId == other.sessionId &&
          linkedAt == other.linkedAt;

  @override
  int get hashCode => Object.hash(
        linkId,
        instanceId,
        sessionId,
        linkedAt,
      );

  @override
  String toString() =>
      'RecommendationSessionLink($linkId, instance: $instanceId, session: $sessionId)';
}
