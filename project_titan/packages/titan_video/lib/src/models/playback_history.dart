import 'package:meta/meta.dart';

/// Immutable domain model representing user watch history for a video.
@immutable
class PlaybackHistory {
  final String contentId;
  final String userId;
  final int lastPositionSeconds;
  final int watchCount;
  final int totalTimeWatchedSeconds;
  final DateTime lastWatchedAt;

  const PlaybackHistory({
    required this.contentId,
    required this.userId,
    required this.lastPositionSeconds,
    this.watchCount = 1,
    required this.totalTimeWatchedSeconds,
    required this.lastWatchedAt,
  });

  PlaybackHistory copyWith({
    String? contentId,
    String? userId,
    int? lastPositionSeconds,
    int? watchCount,
    int? totalTimeWatchedSeconds,
    DateTime? lastWatchedAt,
  }) {
    return PlaybackHistory(
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      watchCount: watchCount ?? this.watchCount,
      totalTimeWatchedSeconds:
          totalTimeWatchedSeconds ?? this.totalTimeWatchedSeconds,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'userId': userId,
        'lastPositionSeconds': lastPositionSeconds,
        'watchCount': watchCount,
        'totalTimeWatchedSeconds': totalTimeWatchedSeconds,
        'lastWatchedAt': lastWatchedAt.toIso8601String(),
      };

  factory PlaybackHistory.fromJson(Map<String, dynamic> json) =>
      PlaybackHistory(
        contentId: json['contentId'] as String,
        userId: json['userId'] as String,
        lastPositionSeconds: json['lastPositionSeconds'] as int? ?? 0,
        watchCount: json['watchCount'] as int? ?? 1,
        totalTimeWatchedSeconds: json['totalTimeWatchedSeconds'] as int? ?? 0,
        lastWatchedAt: DateTime.parse(json['lastWatchedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackHistory &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          userId == other.userId &&
          lastPositionSeconds == other.lastPositionSeconds &&
          watchCount == other.watchCount &&
          totalTimeWatchedSeconds == other.totalTimeWatchedSeconds &&
          lastWatchedAt == other.lastWatchedAt;

  @override
  int get hashCode => Object.hash(
        contentId,
        userId,
        lastPositionSeconds,
        watchCount,
        totalTimeWatchedSeconds,
        lastWatchedAt,
      );
}
