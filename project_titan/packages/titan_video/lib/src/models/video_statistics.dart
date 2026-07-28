import 'package:meta/meta.dart';

/// Immutable domain model representing engagement analytics for a video.
@immutable
class VideoStatistics {
  final int totalViews;
  final int averageWatchDurationSeconds;
  final double completionRatePercentage;
  final int totalBookmarks;
  final int totalNotes;
  final int rewatchCount;

  const VideoStatistics({
    required this.totalViews,
    required this.averageWatchDurationSeconds,
    required this.completionRatePercentage,
    required this.totalBookmarks,
    required this.totalNotes,
    required this.rewatchCount,
  });

  VideoStatistics copyWith({
    int? totalViews,
    int? averageWatchDurationSeconds,
    double? completionRatePercentage,
    int? totalBookmarks,
    int? totalNotes,
    int? rewatchCount,
  }) {
    return VideoStatistics(
      totalViews: totalViews ?? this.totalViews,
      averageWatchDurationSeconds:
          averageWatchDurationSeconds ?? this.averageWatchDurationSeconds,
      completionRatePercentage:
          completionRatePercentage ?? this.completionRatePercentage,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      totalNotes: totalNotes ?? this.totalNotes,
      rewatchCount: rewatchCount ?? this.rewatchCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalViews': totalViews,
        'averageWatchDurationSeconds': averageWatchDurationSeconds,
        'completionRatePercentage': completionRatePercentage,
        'totalBookmarks': totalBookmarks,
        'totalNotes': totalNotes,
        'rewatchCount': rewatchCount,
      };

  factory VideoStatistics.fromJson(Map<String, dynamic> json) =>
      VideoStatistics(
        totalViews: json['totalViews'] as int? ?? 0,
        averageWatchDurationSeconds:
            json['averageWatchDurationSeconds'] as int? ?? 0,
        completionRatePercentage:
            (json['completionRatePercentage'] as num? ?? 0.0).toDouble(),
        totalBookmarks: json['totalBookmarks'] as int? ?? 0,
        totalNotes: json['totalNotes'] as int? ?? 0,
        rewatchCount: json['rewatchCount'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoStatistics &&
          runtimeType == other.runtimeType &&
          totalViews == other.totalViews &&
          averageWatchDurationSeconds == other.averageWatchDurationSeconds &&
          completionRatePercentage == other.completionRatePercentage &&
          totalBookmarks == other.totalBookmarks &&
          totalNotes == other.totalNotes &&
          rewatchCount == other.rewatchCount;

  @override
  int get hashCode => Object.hash(
        totalViews,
        averageWatchDurationSeconds,
        completionRatePercentage,
        totalBookmarks,
        totalNotes,
        rewatchCount,
      );
}
