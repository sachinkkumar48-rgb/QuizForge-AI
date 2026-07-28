import 'package:meta/meta.dart';

/// Immutable domain model representing continue-watching hero banner items.
@immutable
class ContinueWatching {
  final String contentId;
  final String videoTitle;
  final String thumbnailUri;
  final int lastPositionSeconds;
  final int totalDurationSeconds;
  final double progressPercentage;
  final DateTime lastWatchedAt;

  const ContinueWatching({
    required this.contentId,
    required this.videoTitle,
    required this.thumbnailUri,
    required this.lastPositionSeconds,
    required this.totalDurationSeconds,
    required this.progressPercentage,
    required this.lastWatchedAt,
  });

  ContinueWatching copyWith({
    String? contentId,
    String? videoTitle,
    String? thumbnailUri,
    int? lastPositionSeconds,
    int? totalDurationSeconds,
    double? progressPercentage,
    DateTime? lastWatchedAt,
  }) {
    return ContinueWatching(
      contentId: contentId ?? this.contentId,
      videoTitle: videoTitle ?? this.videoTitle,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'videoTitle': videoTitle,
        'thumbnailUri': thumbnailUri,
        'lastPositionSeconds': lastPositionSeconds,
        'totalDurationSeconds': totalDurationSeconds,
        'progressPercentage': progressPercentage,
        'lastWatchedAt': lastWatchedAt.toIso8601String(),
      };

  factory ContinueWatching.fromJson(Map<String, dynamic> json) =>
      ContinueWatching(
        contentId: json['contentId'] as String,
        videoTitle: json['videoTitle'] as String,
        thumbnailUri: json['thumbnailUri'] as String? ?? '',
        lastPositionSeconds: json['lastPositionSeconds'] as int? ?? 0,
        totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
        progressPercentage:
            (json['progressPercentage'] as num? ?? 0.0).toDouble(),
        lastWatchedAt: DateTime.parse(json['lastWatchedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContinueWatching &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          videoTitle == other.videoTitle &&
          thumbnailUri == other.thumbnailUri &&
          lastPositionSeconds == other.lastPositionSeconds &&
          totalDurationSeconds == other.totalDurationSeconds &&
          progressPercentage == other.progressPercentage &&
          lastWatchedAt == other.lastWatchedAt;

  @override
  int get hashCode => Object.hash(
        contentId,
        videoTitle,
        thumbnailUri,
        lastPositionSeconds,
        totalDurationSeconds,
        progressPercentage,
        lastWatchedAt,
      );
}
