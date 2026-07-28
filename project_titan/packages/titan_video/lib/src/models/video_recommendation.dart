import 'package:meta/meta.dart';

/// Immutable domain model representing a recommended video suggestion for the learner.
@immutable
class VideoRecommendation {
  final String contentId;
  final String title;
  final String reason;
  final double similarityScore;
  final String type; // 'next_lesson', 'revision', 'related', 'practice'

  const VideoRecommendation({
    required this.contentId,
    required this.title,
    required this.reason,
    required this.similarityScore,
    required this.type,
  });

  VideoRecommendation copyWith({
    String? contentId,
    String? title,
    String? reason,
    double? similarityScore,
    String? type,
  }) {
    return VideoRecommendation(
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      similarityScore: similarityScore ?? this.similarityScore,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'title': title,
        'reason': reason,
        'similarityScore': similarityScore,
        'type': type,
      };

  factory VideoRecommendation.fromJson(Map<String, dynamic> json) =>
      VideoRecommendation(
        contentId: json['contentId'] as String,
        title: json['title'] as String,
        reason: json['reason'] as String,
        similarityScore: (json['similarityScore'] as num? ?? 0.0).toDouble(),
        type: json['type'] as String? ?? 'related',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoRecommendation &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          title == other.title &&
          reason == other.reason &&
          similarityScore == other.similarityScore &&
          type == other.type;

  @override
  int get hashCode => Object.hash(
        contentId,
        title,
        reason,
        similarityScore,
        type,
      );
}
