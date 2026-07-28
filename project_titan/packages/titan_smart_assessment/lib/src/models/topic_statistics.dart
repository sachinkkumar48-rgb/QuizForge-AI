import 'package:meta/meta.dart';

/// Immutable domain model representing performance statistics for a specific topic.
@immutable
class TopicStatistics {
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skipped;
  final double accuracyPercentage;
  final double masteryScore; // 0.0 to 100.0

  const TopicStatistics({
    required this.topicId,
    required this.topicName,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.skipped = 0,
    this.accuracyPercentage = 0.0,
    this.masteryScore = 0.0,
  });

  TopicStatistics copyWith({
    String? topicId,
    String? topicName,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    int? skipped,
    double? accuracyPercentage,
    double? masteryScore,
  }) {
    return TopicStatistics(
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      skipped: skipped ?? this.skipped,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      masteryScore: masteryScore ?? this.masteryScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'topicName': topicName,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'skipped': skipped,
        'accuracyPercentage': accuracyPercentage,
        'masteryScore': masteryScore,
      };

  factory TopicStatistics.fromJson(Map<String, dynamic> json) =>
      TopicStatistics(
        topicId: json['topicId'] as String,
        topicName: json['topicName'] as String,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        wrongAnswers: json['wrongAnswers'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
        accuracyPercentage:
            (json['accuracyPercentage'] as num? ?? 0.0).toDouble(),
        masteryScore: (json['masteryScore'] as num? ?? 0.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicStatistics &&
          runtimeType == other.runtimeType &&
          topicId == other.topicId &&
          accuracyPercentage == other.accuracyPercentage;

  @override
  int get hashCode => Object.hash(topicId, accuracyPercentage);
}
