/// Recommendation Interaction Entity (TITAN-KO-022.0 P22).
///
/// Immutable domain model representing a discrete learner interaction telemetry
/// event on a [RecommendationInstance] (e.g. view, acceptance, dismissal, deferral).
library;

import 'package:meta/meta.dart';

import 'dismissal_reason.dart';
import 'recommendation_lifecycle_state.dart';

@immutable
class RecommendationInteraction {
  /// Unique identifier for this discrete interaction record.
  final String interactionId;

  /// Target [RecommendationInstance.instanceId] this interaction applies to.
  final String instanceId;

  /// Lifecycle state resulting from this interaction.
  final RecommendationLifecycleState targetState;

  /// Structured reason if the interaction represents a dismissal.
  final DismissalReason? dismissalReason;

  /// UTC timestamp when the interaction occurred.
  final DateTime timestamp;

  /// Immutable diagnostic metadata associated with this interaction.
  final Map<String, dynamic> metadata;

  RecommendationInteraction({
    required this.interactionId,
    required this.instanceId,
    required this.targetState,
    this.dismissalReason,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (interactionId.trim().isEmpty) {
      throw ArgumentError('interactionId cannot be empty');
    }
    if (instanceId.trim().isEmpty) {
      throw ArgumentError('instanceId cannot be empty');
    }
    if (targetState == RecommendationLifecycleState.dismissed &&
        dismissalReason == null) {
      throw ArgumentError(
        'dismissalReason cannot be null when targetState is dismissed',
      );
    }
  }

  /// Factory helper for creating a `viewed` interaction.
  factory RecommendationInteraction.viewed({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      RecommendationInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.viewed,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Factory helper for creating an `accepted` interaction.
  factory RecommendationInteraction.accepted({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      RecommendationInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.accepted,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Factory helper for creating a `dismissed` interaction with required [reason].
  factory RecommendationInteraction.dismissed({
    required String interactionId,
    required String instanceId,
    required DismissalReason reason,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      RecommendationInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.dismissed,
        dismissalReason: reason,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Factory helper for creating a `deferred` interaction.
  factory RecommendationInteraction.deferred({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      RecommendationInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.deferred,
        timestamp: timestamp,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() => {
        'interactionId': interactionId,
        'instanceId': instanceId,
        'targetState': targetState.name,
        if (dismissalReason != null) 'dismissalReason': dismissalReason!.name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory RecommendationInteraction.fromJson(Map<String, dynamic> json) =>
      RecommendationInteraction(
        interactionId: json['interactionId'] as String? ?? '',
        instanceId: json['instanceId'] as String? ?? '',
        targetState: RecommendationLifecycleState.values.firstWhere(
          (s) => s.name == json['targetState'],
          orElse: () => RecommendationLifecycleState.viewed,
        ),
        dismissalReason: json['dismissalReason'] != null
            ? DismissalReason.values.firstWhere(
                (r) => r.name == json['dismissalReason'],
                orElse: () => DismissalReason.other,
              )
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        metadata:
            Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationInteraction &&
          interactionId == other.interactionId &&
          instanceId == other.instanceId &&
          targetState == other.targetState &&
          dismissalReason == other.dismissalReason &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        interactionId,
        instanceId,
        targetState,
        dismissalReason,
        timestamp,
      );

  @override
  String toString() =>
      'RecommendationInteraction($interactionId, instance: $instanceId, state: ${targetState.name}${dismissalReason != null ? ', reason: ${dismissalReason!.name}' : ''})';
}
