import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain entity representing a single user activity event on learning content.
@immutable
class LearningActivity {
  final String id;
  final String userId;
  final String contentId;
  final LearningActivityType activityType;
  final DateTime timestamp;
  final int durationSeconds;
  final Map<String, dynamic> metadata;

  LearningActivity({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.activityType,
    DateTime? timestamp,
    this.durationSeconds = 0,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  LearningActivity copyWith({
    String? id,
    String? userId,
    String? contentId,
    LearningActivityType? activityType,
    DateTime? timestamp,
    int? durationSeconds,
    Map<String, dynamic>? metadata,
  }) {
    return LearningActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      activityType: activityType ?? this.activityType,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'contentId': contentId,
        'activityType': activityType.name,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
        'metadata': metadata,
      };

  factory LearningActivity.fromJson(Map<String, dynamic> json) =>
      LearningActivity(
        id: json['id'] as String,
        userId: json['userId'] as String,
        contentId: json['contentId'] as String,
        activityType: LearningActivityType.values.firstWhere(
          (e) => e.name == json['activityType'],
          orElse: () => LearningActivityType.viewed,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningActivity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          contentId == other.contentId &&
          activityType == other.activityType &&
          timestamp == other.timestamp &&
          durationSeconds == other.durationSeconds;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        contentId,
        activityType,
        timestamp,
        durationSeconds,
      );
}
