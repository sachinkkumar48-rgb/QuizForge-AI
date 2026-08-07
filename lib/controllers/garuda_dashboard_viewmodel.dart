import 'package:flutter/foundation.dart';

/// GARUDA AI DTO: Overview Summary
class DashboardSummaryDto {
  final double overallMastery;
  final double overallAccuracy;
  final int questionsAttempted;
  final int correctAnswers;
  final double studyHours;
  final int studyStreak;
  final double learningVelocity;
  final double confidenceScore;
  final double completionPercentage;

  const DashboardSummaryDto({
    required this.overallMastery,
    required this.overallAccuracy,
    required this.questionsAttempted,
    required this.correctAnswers,
    required this.studyHours,
    required this.studyStreak,
    required this.learningVelocity,
    required this.confidenceScore,
    required this.completionPercentage,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDto(
      overallMastery: (json['overall_mastery'] as num? ?? 0.68).toDouble(),
      overallAccuracy: (json['overall_accuracy'] as num? ?? 0.74).toDouble(),
      questionsAttempted: (json['questions_attempted'] as num? ?? 185).toInt(),
      correctAnswers: (json['correct_answers'] as num? ?? 137).toInt(),
      studyHours: (json['study_hours'] as num? ?? 12.5).toDouble(),
      studyStreak: (json['study_streak'] as num? ?? 7).toInt(),
      learningVelocity: (json['learning_velocity'] as num? ?? 0.05).toDouble(),
      confidenceScore: (json['confidence_score'] as num? ?? 3.2).toDouble(),
      completionPercentage: (json['completion_percentage'] as num? ?? 68.0).toDouble(),
    );
  }
}

/// GARUDA AI DTO: Topic Analytics
class TopicAnalyticsDto {
  final List<String> strongTopics;
  final List<String> weakTopics;
  final double masteryPct;
  final int revisionDue;
  final int practiceCount;
  final String accuracyTrend;
  final String confidenceTrend;

  const TopicAnalyticsDto({
    required this.strongTopics,
    required this.weakTopics,
    required this.masteryPct,
    required this.revisionDue,
    required this.practiceCount,
    required this.accuracyTrend,
    required this.confidenceTrend,
  });

  factory TopicAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return TopicAnalyticsDto(
      strongTopics: (json['strong_topics'] as List? ?? ['Polity Preamble', 'Panchayati Raj']).map((e) => e.toString()).toList(),
      weakTopics: (json['weak_topics'] as List? ?? ['Article 21 Judicial Precedents', 'Emergency Provisions']).map((e) => e.toString()).toList(),
      masteryPct: (json['mastery_pct'] as num? ?? 68.0).toDouble(),
      revisionDue: (json['revision_due'] as num? ?? 5).toInt(),
      practiceCount: (json['practice_count'] as num? ?? 185).toInt(),
      accuracyTrend: json['accuracy_trend'] as String? ?? 'improving',
      confidenceTrend: json['confidence_trend'] as String? ?? 'improving',
    );
  }
}

/// GARUDA AI DTO: Revision Analytics
class RevisionAnalyticsDto {
  final int todaysQueue;
  final int completed;
  final int pending;
  final int overdue;
  final double avgEaseFactor;
  final double avgInterval;
  final String nextRevision;
  final double completionPct;

  const RevisionAnalyticsDto({
    required this.todaysQueue,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.avgEaseFactor,
    required this.avgInterval,
    required this.nextRevision,
    required this.completionPct,
  });

  factory RevisionAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return RevisionAnalyticsDto(
      todaysQueue: (json['todays_queue'] as num? ?? 12).toInt(),
      completed: (json['completed'] as num? ?? 7).toInt(),
      pending: (json['pending'] as num? ?? 5).toInt(),
      overdue: (json['overdue'] as num? ?? 2).toInt(),
      avgEaseFactor: (json['avg_ease_factor'] as num? ?? 2.45).toDouble(),
      avgInterval: (json['avg_interval'] as num? ?? 3.5).toDouble(),
      nextRevision: json['next_revision'] as String? ?? 'Today at 6:00 PM',
      completionPct: (json['completion_pct'] as num? ?? 58.3).toDouble(),
    );
  }
}

/// GARUDA AI DTO: Study Analytics
class StudyAnalyticsDto {
  final List<Map<String, dynamic>> todaysPlan;
  final int completedTasks;
  final int remainingTasks;
  final double weeklyProgress;
  final double monthlyProgress;
  final int studyTimeMinutes;
  final double completionPct;

  const StudyAnalyticsDto({
    required this.todaysPlan,
    required this.completedTasks,
    required this.remainingTasks,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.studyTimeMinutes,
    required this.completionPct,
  });

  factory StudyAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return StudyAnalyticsDto(
      todaysPlan: (json['todays_plan'] as List? ?? [
        {'title': 'Revise Article 21 Rights', 'type': 'revision', 'duration': 30, 'completed': true},
        {'title': 'Solve 15 Polity Questions', 'type': 'quiz', 'duration': 30, 'completed': true},
        {'title': 'Read Emergency Provisions PDF', 'type': 'learning', 'duration': 60, 'completed': false},
      ]).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      completedTasks: (json['completed_tasks'] as num? ?? 2).toInt(),
      remainingTasks: (json['remaining_tasks'] as num? ?? 1).toInt(),
      weeklyProgress: (json['weekly_progress'] as num? ?? 75.0).toDouble(),
      monthlyProgress: (json['monthly_progress'] as num? ?? 68.0).toDouble(),
      studyTimeMinutes: (json['study_time_minutes'] as num? ?? 120).toInt(),
      completionPct: (json['completion_pct'] as num? ?? 66.7).toDouble(),
    );
  }
}

/// GARUDA AI DTO: Performance Analytics
class PerformanceAnalyticsDto {
  final double dailyAccuracy;
  final double weeklyAccuracy;
  final double monthlyAccuracy;
  final double avgScore;
  final String bestTopic;
  final String weakestTopic;
  final double improvementRate;
  final double consistencyScore;

  const PerformanceAnalyticsDto({
    required this.dailyAccuracy,
    required this.weeklyAccuracy,
    required this.monthlyAccuracy,
    required this.avgScore,
    required this.bestTopic,
    required this.weakestTopic,
    required this.improvementRate,
    required this.consistencyScore,
  });

  factory PerformanceAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalyticsDto(
      dailyAccuracy: (json['daily_accuracy'] as num? ?? 0.78).toDouble(),
      weeklyAccuracy: (json['weekly_accuracy'] as num? ?? 0.74).toDouble(),
      monthlyAccuracy: (json['monthly_accuracy'] as num? ?? 0.71).toDouble(),
      avgScore: (json['avg_score'] as num? ?? 74.0).toDouble(),
      bestTopic: json['best_topic'] as String? ?? 'Polity Preamble',
      weakestTopic: json['weakest_topic'] as String? ?? 'Article 21 Judicial Precedents',
      improvementRate: (json['improvement_rate'] as num? ?? 12.5).toDouble(),
      consistencyScore: (json['consistency_score'] as num? ?? 88.0).toDouble(),
    );
  }
}

/// GARUDA AI DTO: Recommendations Summary
class RecommendationsDto {
  final String nextBestAction;
  final String todaysGoal;
  final String priorityTopic;
  final String suggestedRevision;
  final String suggestedQuiz;
  final String suggestedReading;

  const RecommendationsDto({
    required this.nextBestAction,
    required this.todaysGoal,
    required this.priorityTopic,
    required this.suggestedRevision,
    required this.suggestedQuiz,
    required this.suggestedReading,
  });

  factory RecommendationsDto.fromJson(Map<String, dynamic> json) {
    return RecommendationsDto(
      nextBestAction: json['next_best_action'] as String? ?? 'Revise Article 21 Rights (Accuracy 52%)',
      todaysGoal: json['todays_goal'] as String? ?? 'Achieve 80%+ Accuracy on Weak Topics',
      priorityTopic: json['priority_topic'] as String? ?? 'Article 21 Judicial Precedents',
      suggestedRevision: json['suggested_revision'] as String? ?? 'Spaced Repetition: 5 Overdue Flashcards',
      suggestedQuiz: json['suggested_quiz'] as String? ?? '10-Question Polity Practice Test',
      suggestedReading: json['suggested_reading'] as String? ?? 'Indian_Constitution_Summary.pdf (Page 14)',
    );
  }
}

/// Backward Compatibility DTOs
class DailyStudyPlanDto {
  final String dateStr;
  final int totalStudyMinutes;
  final int revisionMinutes;
  final int learningMinutes;
  final int quizMinutes;
  final int taskCount;

  const DailyStudyPlanDto({
    required this.dateStr,
    required this.totalStudyMinutes,
    required this.revisionMinutes,
    required this.learningMinutes,
    required this.quizMinutes,
    required this.taskCount,
  });
}

class RevisionQueueDto {
  final int totalDueItems;
  final int queueSize;
  final int urgentItemsCount;

  const RevisionQueueDto({
    required this.totalDueItems,
    required this.queueSize,
    required this.urgentItemsCount,
  });
}

class NextBestActionDto {
  final String id;
  final String recType;
  final String title;
  final String description;
  final String priority;
  final String reason;
  final double confidenceScore;

  const NextBestActionDto({
    required this.id,
    required this.recType,
    required this.title,
    required this.description,
    required this.priority,
    required this.reason,
    required this.confidenceScore,
  });
}

class LearningProfileDto {
  final String userId;
  final double overallMastery;
  final int studyStreakDays;
  final int totalQuestionsAnswered;
  final String currentTopic;

  const LearningProfileDto({
    required this.userId,
    required this.overallMastery,
    required this.studyStreakDays,
    required this.totalQuestionsAnswered,
    required this.currentTopic,
  });
}

class RecentConversationDto {
  final String sessionId;
  final String topicName;
  final String lastMessage;
  final DateTime timestamp;

  const RecentConversationDto({
    required this.sessionId,
    required this.topicName,
    required this.lastMessage,
    required this.timestamp,
  });
}

class UploadedPdfDto {
  final String documentId;
  final String documentName;
  final int chunksCount;
  final DateTime uploadedAt;

  const UploadedPdfDto({
    required this.documentId,
    required this.documentName,
    required this.chunksCount,
    required this.uploadedAt,
  });
}

/// Abstract Repository Interface
abstract class GarudaDashboardRepository {
  Future<DashboardSummaryDto> fetchSummary(String userId);
  Future<TopicAnalyticsDto> fetchTopicAnalytics(String userId);
  Future<RevisionAnalyticsDto> fetchRevisionAnalytics(String userId);
  Future<StudyAnalyticsDto> fetchStudyAnalytics(String userId);
  Future<PerformanceAnalyticsDto> fetchPerformanceAnalytics(String userId);
  Future<RecommendationsDto> fetchRecommendations(String userId);

  // Backward compatibility methods
  Future<DailyStudyPlanDto> fetchStudyPlan(String userId);
  Future<RevisionQueueDto> fetchRevisionQueue(String userId);
  Future<NextBestActionDto> fetchNextBestAction(String userId);
  Future<LearningProfileDto> fetchLearningProfile(String userId);
  Future<List<RecentConversationDto>> fetchRecentConversations(String userId);
  Future<List<UploadedPdfDto>> fetchPdfLibrary(String userId);
}

/// Mock Implementation for Zero-Network Testing & Offline Execution
class MockGarudaDashboardRepository implements GarudaDashboardRepository {
  @override
  Future<DashboardSummaryDto> fetchSummary(String userId) async {
    return const DashboardSummaryDto(
      overallMastery: 0.68,
      overallAccuracy: 0.74,
      questionsAttempted: 185,
      correctAnswers: 137,
      studyHours: 12.5,
      studyStreak: 7,
      learningVelocity: 0.05,
      confidenceScore: 3.2,
      completionPercentage: 68.0,
    );
  }

  @override
  Future<TopicAnalyticsDto> fetchTopicAnalytics(String userId) async {
    return const TopicAnalyticsDto(
      strongTopics: ['Polity Preamble', 'Panchayati Raj'],
      weakTopics: ['Article 21 Judicial Precedents', 'Emergency Provisions'],
      masteryPct: 68.0,
      revisionDue: 5,
      practiceCount: 185,
      accuracyTrend: 'improving',
      confidenceTrend: 'improving',
    );
  }

  @override
  Future<RevisionAnalyticsDto> fetchRevisionAnalytics(String userId) async {
    return const RevisionAnalyticsDto(
      todaysQueue: 12,
      completed: 7,
      pending: 5,
      overdue: 2,
      avgEaseFactor: 2.45,
      avgInterval: 3.5,
      nextRevision: 'Today at 6:00 PM',
      completionPct: 58.3,
    );
  }

  @override
  Future<StudyAnalyticsDto> fetchStudyAnalytics(String userId) async {
    return const StudyAnalyticsDto(
      todaysPlan: [
        {'title': 'Revise Article 21 Rights', 'type': 'revision', 'duration': 30, 'completed': true},
        {'title': 'Solve 15 Polity Questions', 'type': 'quiz', 'duration': 30, 'completed': true},
        {'title': 'Read Emergency Provisions PDF', 'type': 'learning', 'duration': 60, 'completed': false},
      ],
      completedTasks: 2,
      remainingTasks: 1,
      weeklyProgress: 75.0,
      monthlyProgress: 68.0,
      studyTimeMinutes: 120,
      completionPct: 66.7,
    );
  }

  @override
  Future<PerformanceAnalyticsDto> fetchPerformanceAnalytics(String userId) async {
    return const PerformanceAnalyticsDto(
      dailyAccuracy: 0.78,
      weeklyAccuracy: 0.74,
      monthlyAccuracy: 0.71,
      avgScore: 74.0,
      bestTopic: 'Polity Preamble',
      weakestTopic: 'Article 21 Judicial Precedents',
      improvementRate: 12.5,
      consistencyScore: 88.0,
    );
  }

  @override
  Future<RecommendationsDto> fetchRecommendations(String userId) async {
    return const RecommendationsDto(
      nextBestAction: 'Revise Article 21 Rights (Accuracy 52%)',
      todaysGoal: 'Achieve 80%+ Accuracy on Weak Topics',
      priorityTopic: 'Article 21 Judicial Precedents',
      suggestedRevision: 'Spaced Repetition: 5 Overdue Flashcards',
      suggestedQuiz: '10-Question Polity Practice Test',
      suggestedReading: 'Indian_Constitution_Summary.pdf (Page 14)',
    );
  }

  @override
  Future<DailyStudyPlanDto> fetchStudyPlan(String userId) async {
    return const DailyStudyPlanDto(
      dateStr: 'Today',
      totalStudyMinutes: 120,
      revisionMinutes: 30,
      learningMinutes: 60,
      quizMinutes: 30,
      taskCount: 4,
    );
  }

  @override
  Future<RevisionQueueDto> fetchRevisionQueue(String userId) async {
    return const RevisionQueueDto(
      totalDueItems: 5,
      queueSize: 12,
      urgentItemsCount: 2,
    );
  }

  @override
  Future<NextBestActionDto> fetchNextBestAction(String userId) async {
    return const NextBestActionDto(
      id: 'nba_01',
      recType: 'WEAK_TOPIC_REVISION',
      title: 'Revise Article 21 Rights',
      description: 'Mastery score is below target (52%). Socratic review recommended.',
      priority: 'URGENT',
      reason: 'WEAK_ACCURACY',
      confidenceScore: 0.88,
    );
  }

  @override
  Future<LearningProfileDto> fetchLearningProfile(String userId) async {
    return const LearningProfileDto(
      userId: 'user_garuda_01',
      overallMastery: 0.68,
      studyStreakDays: 7,
      totalQuestionsAnswered: 185,
      currentTopic: 'UPSC Indian Polity & Constitution',
    );
  }

  @override
  Future<List<RecentConversationDto>> fetchRecentConversations(String userId) async {
    return [
      RecentConversationDto(
        sessionId: 'sess_01',
        topicName: 'Article 14 Fundamental Rights',
        lastMessage: 'How does administrative discretion affect equality before law?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RecentConversationDto(
        sessionId: 'sess_02',
        topicName: 'Harappan Civilisation Trade',
        lastMessage: 'What were the key maritime trading ports of Indus Valley?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<UploadedPdfDto>> fetchPdfLibrary(String userId) async {
    return [
      UploadedPdfDto(
        documentId: 'doc_polity_pdf',
        documentName: 'Indian_Constitution_Summary.pdf',
        chunksCount: 24,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UploadedPdfDto(
        documentId: 'doc_history_pdf',
        documentName: 'Ancient_India_NCERT.pdf',
        chunksCount: 42,
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}

/// ViewModel for GARUDA AI Learning Analytics Dashboard
class DashboardViewModel extends ChangeNotifier {
  final GarudaDashboardRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastSelectedAction;

  DashboardSummaryDto? _summary;
  TopicAnalyticsDto? _topicAnalytics;
  RevisionAnalyticsDto? _revisionAnalytics;
  StudyAnalyticsDto? _studyAnalytics;
  PerformanceAnalyticsDto? _performanceAnalytics;
  RecommendationsDto? _recommendations;

  // Backward compatibility fields
  DailyStudyPlanDto? _studyPlan;
  RevisionQueueDto? _revisionQueue;
  NextBestActionDto? _nextBestAction;
  LearningProfileDto? _learningProfile;
  List<RecentConversationDto> _recentConversations = [];
  List<UploadedPdfDto> _pdfLibrary = [];

  DashboardViewModel({GarudaDashboardRepository? repository})
      : repository = repository ?? MockGarudaDashboardRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastSelectedAction => _lastSelectedAction;

  DashboardSummaryDto? get summary => _summary;
  TopicAnalyticsDto? get topicAnalytics => _topicAnalytics;
  RevisionAnalyticsDto? get revisionAnalytics => _revisionAnalytics;
  StudyAnalyticsDto? get studyAnalytics => _studyAnalytics;
  PerformanceAnalyticsDto? get performanceAnalytics => _performanceAnalytics;
  RecommendationsDto? get recommendations => _recommendations;

  // Backward compatibility getters
  DailyStudyPlanDto? get studyPlan => _studyPlan;
  RevisionQueueDto? get revisionQueue => _revisionQueue;
  NextBestActionDto? get nextBestAction => _nextBestAction;
  LearningProfileDto? get learningProfile => _learningProfile;
  List<RecentConversationDto> get recentConversations => _recentConversations;
  List<UploadedPdfDto> get pdfLibrary => _pdfLibrary;

  Future<void> loadDashboardData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.fetchSummary(userId),
        repository.fetchTopicAnalytics(userId),
        repository.fetchRevisionAnalytics(userId),
        repository.fetchStudyAnalytics(userId),
        repository.fetchPerformanceAnalytics(userId),
        repository.fetchRecommendations(userId),
        repository.fetchStudyPlan(userId),
        repository.fetchRevisionQueue(userId),
        repository.fetchNextBestAction(userId),
        repository.fetchLearningProfile(userId),
        repository.fetchRecentConversations(userId),
        repository.fetchPdfLibrary(userId),
      ]);

      _summary = results[0] as DashboardSummaryDto;
      _topicAnalytics = results[1] as TopicAnalyticsDto;
      _revisionAnalytics = results[2] as RevisionAnalyticsDto;
      _studyAnalytics = results[3] as StudyAnalyticsDto;
      _performanceAnalytics = results[4] as PerformanceAnalyticsDto;
      _recommendations = results[5] as RecommendationsDto;

      _studyPlan = results[6] as DailyStudyPlanDto;
      _revisionQueue = results[7] as RevisionQueueDto;
      _nextBestAction = results[8] as NextBestActionDto;
      _learningProfile = results[9] as LearningProfileDto;
      _recentConversations = results[10] as List<RecentConversationDto>;
      _pdfLibrary = results[11] as List<UploadedPdfDto>;

      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Failed to load GARUDA Analytics Dashboard: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  void onQuickActionSelected(String actionKey) {
    _lastSelectedAction = actionKey;
    notifyListeners();
  }
}
