import 'package:meta/meta.dart';

import 'goal_progress.dart';
import 'learning_insights.dart';
import 'performance_trend.dart';
import 'study_statistics.dart';

/// Immutable domain entity aggregating executive intelligence from all 10 TITAN engines.
@immutable
class DashboardSnapshot {
  final String userId;
  final String userName;
  final String targetExam;
  final double readinessScore; // 0.0 - 100.0
  final StudyStatistics statistics;
  final PerformanceTrend trend;
  final LearningInsights insights;
  final List<GoalProgress> goals;
  final Map<String, dynamic> subsystemSummaries;
  final DateTime generatedAt;

  DashboardSnapshot({
    required this.userId,
    required this.userName,
    this.targetExam = 'UPSC CSE',
    this.readinessScore = 78.5,
    required this.statistics,
    required this.trend,
    required this.insights,
    List<GoalProgress>? goals,
    Map<String, dynamic>? subsystemSummaries,
    DateTime? generatedAt,
  })  : goals = List<GoalProgress>.unmodifiable(goals ?? []),
        subsystemSummaries =
            Map<String, dynamic>.unmodifiable(subsystemSummaries ?? {}),
        generatedAt = generatedAt ?? DateTime.now();

  factory DashboardSnapshot.empty({String userId = 'guest'}) =>
      DashboardSnapshot(
        userId: userId,
        userName: 'Learner',
        statistics: const StudyStatistics(),
        trend: PerformanceTrend.empty(),
        insights: LearningInsights.empty(),
      );

  DashboardSnapshot copyWith({
    String? userId,
    String? userName,
    String? targetExam,
    double? readinessScore,
    StudyStatistics? statistics,
    PerformanceTrend? trend,
    LearningInsights? insights,
    List<GoalProgress>? goals,
    Map<String, dynamic>? subsystemSummaries,
    DateTime? generatedAt,
  }) {
    return DashboardSnapshot(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      targetExam: targetExam ?? this.targetExam,
      readinessScore: readinessScore ?? this.readinessScore,
      statistics: statistics ?? this.statistics,
      trend: trend ?? this.trend,
      insights: insights ?? this.insights,
      goals: goals ?? this.goals,
      subsystemSummaries: subsystemSummaries ?? this.subsystemSummaries,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'targetExam': targetExam,
        'readinessScore': readinessScore,
        'statistics': statistics.toJson(),
        'trend': trend.toJson(),
        'insights': insights.toJson(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'subsystemSummaries': subsystemSummaries,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) =>
      DashboardSnapshot(
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        targetExam: json['targetExam'] as String? ?? 'UPSC CSE',
        readinessScore: (json['readinessScore'] as num? ?? 0.0).toDouble(),
        statistics: StudyStatistics.fromJson(
            Map<String, dynamic>.from(json['statistics'] as Map? ?? {})),
        trend: PerformanceTrend.fromJson(
            Map<String, dynamic>.from(json['trend'] as Map? ?? {})),
        insights: LearningInsights.fromJson(
            Map<String, dynamic>.from(json['insights'] as Map? ?? {})),
        goals: (json['goals'] as List? ?? [])
            .map((g) =>
                GoalProgress.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList(),
        subsystemSummaries:
            Map<String, dynamic>.from(json['subsystemSummaries'] as Map? ?? {}),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSnapshot &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          userName == other.userName &&
          readinessScore == other.readinessScore;

  @override
  int get hashCode => Object.hash(userId, userName, readinessScore);
}
