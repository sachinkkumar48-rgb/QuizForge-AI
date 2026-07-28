import 'package:meta/meta.dart';

/// Immutable domain model representing item statistics for a question.
@immutable
class QuestionStatistics {
  final String questionId;
  final int timesAttempted;
  final int timesCorrect;
  final double averageTimeSeconds;
  final double difficultyEstimate; // 0.0 (easiest) to 1.0 (hardest)

  const QuestionStatistics({
    required this.questionId,
    this.timesAttempted = 0,
    this.timesCorrect = 0,
    this.averageTimeSeconds = 60.0,
    this.difficultyEstimate = 0.5,
  });

  double get accuracyRate =>
      timesAttempted > 0 ? (timesCorrect / timesAttempted) * 100.0 : 0.0;

  QuestionStatistics copyWith({
    String? questionId,
    int? timesAttempted,
    int? timesCorrect,
    double? averageTimeSeconds,
    double? difficultyEstimate,
  }) {
    return QuestionStatistics(
      questionId: questionId ?? this.questionId,
      timesAttempted: timesAttempted ?? this.timesAttempted,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
      difficultyEstimate: difficultyEstimate ?? this.difficultyEstimate,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'timesAttempted': timesAttempted,
        'timesCorrect': timesCorrect,
        'averageTimeSeconds': averageTimeSeconds,
        'difficultyEstimate': difficultyEstimate,
      };

  factory QuestionStatistics.fromJson(Map<String, dynamic> json) =>
      QuestionStatistics(
        questionId: json['questionId'] as String,
        timesAttempted: json['timesAttempted'] as int? ?? 0,
        timesCorrect: json['timesCorrect'] as int? ?? 0,
        averageTimeSeconds:
            (json['averageTimeSeconds'] as num? ?? 60.0).toDouble(),
        difficultyEstimate:
            (json['difficultyEstimate'] as num? ?? 0.5).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionStatistics &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          timesAttempted == other.timesAttempted;

  @override
  int get hashCode => Object.hash(questionId, timesAttempted);
}
