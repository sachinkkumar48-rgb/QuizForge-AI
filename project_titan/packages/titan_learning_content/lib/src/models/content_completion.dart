import 'package:meta/meta.dart';

/// Immutable domain model representing official completion record of a learning content item.
@immutable
class ContentCompletion {
  final String contentId;
  final String userId;
  final DateTime completedAt;
  final double? score;
  final int totalAttempts;
  final String? certificateUrl;
  final String? feedback;

  const ContentCompletion({
    required this.contentId,
    required this.userId,
    required this.completedAt,
    this.score,
    this.totalAttempts = 1,
    this.certificateUrl,
    this.feedback,
  });

  ContentCompletion copyWith({
    String? contentId,
    String? userId,
    DateTime? completedAt,
    double? score,
    int? totalAttempts,
    String? certificateUrl,
    String? feedback,
  }) {
    return ContentCompletion(
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'userId': userId,
        'completedAt': completedAt.toIso8601String(),
        'score': score,
        'totalAttempts': totalAttempts,
        'certificateUrl': certificateUrl,
        'feedback': feedback,
      };

  factory ContentCompletion.fromJson(Map<String, dynamic> json) =>
      ContentCompletion(
        contentId: json['contentId'] as String,
        userId: json['userId'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        score: (json['score'] as num?)?.toDouble(),
        totalAttempts: json['totalAttempts'] as int? ?? 1,
        certificateUrl: json['certificateUrl'] as String?,
        feedback: json['feedback'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentCompletion &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          userId == other.userId &&
          completedAt == other.completedAt &&
          score == other.score &&
          totalAttempts == other.totalAttempts &&
          certificateUrl == other.certificateUrl &&
          feedback == other.feedback;

  @override
  int get hashCode => Object.hash(
        contentId,
        userId,
        completedAt,
        score,
        totalAttempts,
        certificateUrl,
        feedback,
      );
}
