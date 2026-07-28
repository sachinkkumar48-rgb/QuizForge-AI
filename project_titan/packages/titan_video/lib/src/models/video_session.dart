import 'package:meta/meta.dart';

/// Immutable domain model representing a single continuous watch session for analytics.
@immutable
class VideoSession {
  final String id;
  final String contentId;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int activeWatchSeconds;
  final double averageSpeed;

  const VideoSession({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.activeWatchSeconds,
    this.averageSpeed = 1.0,
  });

  VideoSession copyWith({
    String? id,
    String? contentId,
    String? userId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? activeWatchSeconds,
    double? averageSpeed,
  }) {
    return VideoSession(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      activeWatchSeconds: activeWatchSeconds ?? this.activeWatchSeconds,
      averageSpeed: averageSpeed ?? this.averageSpeed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'userId': userId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'activeWatchSeconds': activeWatchSeconds,
        'averageSpeed': averageSpeed,
      };

  factory VideoSession.fromJson(Map<String, dynamic> json) => VideoSession(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        userId: json['userId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        activeWatchSeconds: json['activeWatchSeconds'] as int? ?? 0,
        averageSpeed: (json['averageSpeed'] as num? ?? 1.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          userId == other.userId &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          activeWatchSeconds == other.activeWatchSeconds &&
          averageSpeed == other.averageSpeed;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        userId,
        startedAt,
        endedAt,
        activeWatchSeconds,
        averageSpeed,
      );
}
