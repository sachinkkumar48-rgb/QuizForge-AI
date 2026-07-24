import 'package:flutter/foundation.dart';

enum DashboardStatus { loading, ready, error }

/// Holds aggregate statistics for the QuizForge Dashboard.
@immutable
class DashboardStats {
  final int totalQuizzesCompleted;
  final double averageAccuracyPercentage;
  final int studyStreakDays;
  final int totalQuestionsAnswered;
  final int totalPdfSources;

  const DashboardStats({
    this.totalQuizzesCompleted = 12,
    this.averageAccuracyPercentage = 78.5,
    this.studyStreakDays = 5,
    this.totalQuestionsAnswered = 145,
    this.totalPdfSources = 4,
  });

  DashboardStats copyWith({
    int? totalQuizzesCompleted,
    double? averageAccuracyPercentage,
    int? studyStreakDays,
    int? totalQuestionsAnswered,
    int? totalPdfSources,
  }) {
    return DashboardStats(
      totalQuizzesCompleted:
          totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      averageAccuracyPercentage:
          averageAccuracyPercentage ?? this.averageAccuracyPercentage,
      studyStreakDays: studyStreakDays ?? this.studyStreakDays,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalPdfSources: totalPdfSources ?? this.totalPdfSources,
    );
  }
}

/// Represents a recent activity item on the dashboard.
@immutable
class RecentActivity {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final double scorePercentage;
  final String categoryTag;

  const RecentActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.scorePercentage,
    required this.categoryTag,
  });
}

/// Represents a plugin module summary item.
@immutable
class DashboardModuleInfo {
  final String id;
  final String title;
  final String category;
  final bool isEnabled;

  const DashboardModuleInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.isEnabled,
  });
}

/// Immutable state container for the QuizForge Dashboard.
@immutable
class DashboardState {
  final DashboardStatus status;
  final String userGreeting;
  final DashboardStats stats;
  final List<RecentActivity> recentActivities;
  final List<DashboardModuleInfo> activeModules;
  final String? activeSessionSourceName;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    this.userGreeting = "Welcome back, Aspirant!",
    this.stats = const DashboardStats(),
    this.recentActivities = const [],
    this.activeModules = const [],
    this.activeSessionSourceName,
    this.errorMessage,
  });

  factory DashboardState.loading() => const DashboardState(
        status: DashboardStatus.loading,
      );

  factory DashboardState.ready({
    String userGreeting = "Welcome back, Aspirant!",
    DashboardStats stats = const DashboardStats(),
    List<RecentActivity> recentActivities = const [],
    List<DashboardModuleInfo> activeModules = const [],
    String? activeSessionSourceName,
  }) =>
      DashboardState(
        status: DashboardStatus.ready,
        userGreeting: userGreeting,
        stats: stats,
        recentActivities: recentActivities,
        activeModules: activeModules,
        activeSessionSourceName: activeSessionSourceName,
      );

  factory DashboardState.error(String message) => DashboardState(
        status: DashboardStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == DashboardStatus.loading;
  bool get isReady => status == DashboardStatus.ready;
  bool get isError => status == DashboardStatus.error;
}
