import 'package:meta/meta.dart';

import 'mentor_recommendation.dart';
import 'recommendation_reason.dart';

/// Value object representing a single AI Mentor interaction or recommendation session cycle.
@immutable
class MentorSession {
  /// Unique identifier of the session.
  final String sessionId;

  /// Identifier of the learner associated with this session.
  final String learnerId;

  /// Timestamp when the session was created.
  final DateTime timestamp;

  /// Recommendation payload generated during this session.
  final MentorRecommendation recommendation;

  /// Extensible metadata payload.
  final Map<String, dynamic> metadata;

  /// Constructs an immutable [MentorSession].
  MentorSession({
    required this.sessionId,
    required this.learnerId,
    required this.recommendation,
    DateTime? timestamp,
    Map<String, dynamic> metadata = const {},
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = Map<String, dynamic>.unmodifiable(metadata);

  /// Creates a copy of this [MentorSession] with updated fields.
  MentorSession copyWith({
    String? sessionId,
    String? learnerId,
    DateTime? timestamp,
    MentorRecommendation? recommendation,
    Map<String, dynamic>? metadata,
  }) {
    return MentorSession(
      sessionId: sessionId ?? this.sessionId,
      learnerId: learnerId ?? this.learnerId,
      timestamp: timestamp ?? this.timestamp,
      recommendation: recommendation ?? this.recommendation,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this [MentorSession] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'learnerId': learnerId,
      'timestamp': timestamp.toIso8601String(),
      'recommendation': recommendation.toMap(),
      'metadata': metadata,
    };
  }

  /// Deserializes a [MentorSession] from a Map.
  factory MentorSession.fromMap(Map<String, dynamic> map) {
    return MentorSession(
      sessionId: (map['sessionId'] as String?) ?? '',
      learnerId: (map['learnerId'] as String?) ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      recommendation: map['recommendation'] != null
          ? MentorRecommendation.fromMap(
              Map<String, dynamic>.from(map['recommendation'] as Map))
          : MentorRecommendation(
              recommendedTopics: const [],
              reasoning:
                  RecommendationReason(code: 'DEFAULT', explanation: 'Default'),
            ),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MentorSession &&
        other.sessionId == sessionId &&
        other.learnerId == learnerId &&
        other.timestamp == timestamp &&
        other.recommendation == recommendation &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      sessionId,
      learnerId,
      timestamp,
      recommendation,
      Object.hashAll(metadata.keys),
      Object.hashAll(metadata.values),
    );
  }

  @override
  String toString() {
    return 'MentorSession(sessionId: $sessionId, learnerId: $learnerId, timestamp: ${timestamp.toIso8601String()})';
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
