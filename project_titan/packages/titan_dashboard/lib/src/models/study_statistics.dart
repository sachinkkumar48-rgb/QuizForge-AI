import 'package:meta/meta.dart';

/// Immutable entity summarizing quantitative study metrics and activity counters.
@immutable
class StudyStatistics {
  final double totalStudyHours;
  final int totalQuestionsAttempted;
  final int correctAnswersCount;
  final int currentStreakDays;
  final int longestStreakDays;
  final int completedTasksCount;
  final int pendingRevisionsCount;

  const StudyStatistics({
    this.totalStudyHours = 0.0,
    this.totalQuestionsAttempted = 0,
    this.correctAnswersCount = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.completedTasksCount = 0,
    this.pendingRevisionsCount = 0,
  });

  double get overallAccuracy => totalQuestionsAttempted > 0
      ? correctAnswersCount / totalQuestionsAttempted
      : 0.0;

  StudyStatistics copyWith({
    double? totalStudyHours,
    int? totalQuestionsAttempted,
    int? correctAnswersCount,
    int? currentStreakDays,
    int? longestStreakDays,
    int? completedTasksCount,
    int? pendingRevisionsCount,
  }) {
    return StudyStatistics(
      totalStudyHours: totalStudyHours ?? this.totalStudyHours,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      correctAnswersCount: correctAnswersCount ?? this.correctAnswersCount,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      pendingRevisionsCount:
          pendingRevisionsCount ?? this.pendingRevisionsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalStudyHours': totalStudyHours,
        'totalQuestionsAttempted': totalQuestionsAttempted,
        'correctAnswersCount': correctAnswersCount,
        'currentStreakDays': currentStreakDays,
        'longestStreakDays': longestStreakDays,
        'completedTasksCount': completedTasksCount,
        'pendingRevisionsCount': pendingRevisionsCount,
      };

  factory StudyStatistics.fromJson(Map<String, dynamic> json) =>
      StudyStatistics(
        totalStudyHours: (json['totalStudyHours'] as num? ?? 0.0).toDouble(),
        totalQuestionsAttempted: json['totalQuestionsAttempted'] as int? ?? 0,
        correctAnswersCount: json['correctAnswersCount'] as int? ?? 0,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        longestStreakDays: json['longestStreakDays'] as int? ?? 0,
        completedTasksCount: json['completedTasksCount'] as int? ?? 0,
        pendingRevisionsCount: json['pendingRevisionsCount'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyStatistics &&
          runtimeType == other.runtimeType &&
          totalStudyHours == other.totalStudyHours &&
          totalQuestionsAttempted == other.totalQuestionsAttempted &&
          currentStreakDays == other.currentStreakDays;

  @override
  int get hashCode => Object.hash(
        totalStudyHours,
        totalQuestionsAttempted,
        currentStreakDays,
      );
}
