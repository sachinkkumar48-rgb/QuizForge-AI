/// Learner Analytics & Reporting Entities (TITAN-KO-046.0 P46).
///
/// Production domain models representing real, evidence-backed learner analytics,
/// performance summaries, weak area diagnoses, mastery distribution breakdowns,
/// chronological score trends, curriculum drilldowns, and faculty content telemetry.
library;

import 'package:meta/meta.dart';

import 'mastery_progression_decision.dart';

/// Comprehensive performance summary for a learner within an exam context.
@immutable
class LearnerPerformanceSummary {
  /// Total question attempts submitted by the learner.
  final int totalAttempts;

  /// Total unique questions attempted (matches totalAttempts when attempts are question-level).
  final int totalQuestionsAttempted;

  /// Total number of correct question attempts.
  final int correctCount;

  /// Total number of incorrect question attempts.
  final int incorrectCount;

  /// Overall success accuracy ratio in range [0.0, 1.0]. Zero when totalAttempts is 0.
  final double accuracy;

  /// Accuracy represented as a percentage [0.0, 100.0].
  double get accuracyPercentage => accuracy * 100.0;

  /// Total number of curriculum objectives that have at least one attempt.
  final int objectivesAttempted;

  /// Total number of curriculum objectives achieving the mastered stage.
  final int objectivesMastered;

  /// Total number of curriculum objectives diagnosed as needing targeted remediation or regressed.
  final int objectivesNeedingRemediation;

  /// Total learning objectives in the syllabus/framework.
  final int totalObjectives;

  /// Syllabus completion ratio in range [0.0, 1.0] based on mastered objectives.
  final double completionRate;

  /// Completion percentage in range [0.0, 100.0].
  double get completionPercentage => completionRate * 100.0;

  /// Consecutive active study streak in days.
  final int currentStreak;

  /// Timestamp of the learner's most recent activity, if any.
  final DateTime? lastActiveAt;

  LearnerPerformanceSummary({
    this.totalAttempts = 0,
    int? totalQuestionsAttempted,
    this.correctCount = 0,
    int? incorrectCount,
    double? accuracy,
    this.objectivesAttempted = 0,
    this.objectivesMastered = 0,
    this.objectivesNeedingRemediation = 0,
    this.totalObjectives = 0,
    double? completionRate,
    this.currentStreak = 0,
    this.lastActiveAt,
  })  : totalQuestionsAttempted = totalQuestionsAttempted ?? totalAttempts,
        incorrectCount = incorrectCount ??
            (totalAttempts - correctCount).clamp(0, totalAttempts),
        accuracy = accuracy ??
            (totalAttempts > 0
                ? (correctCount / totalAttempts).clamp(0.0, 1.0)
                : 0.0),
        completionRate = completionRate ??
            (totalObjectives > 0
                ? (objectivesMastered / totalObjectives).clamp(0.0, 1.0)
                : 0.0) {
    if (totalAttempts < 0) {
      throw ArgumentError('totalAttempts cannot be negative');
    }
    if (correctCount < 0 || correctCount > totalAttempts) {
      throw ArgumentError(
          'correctCount ($correctCount) must be between 0 and totalAttempts ($totalAttempts)');
    }
    if (objectivesAttempted < 0) {
      throw ArgumentError('objectivesAttempted cannot be negative');
    }
    if (objectivesMastered < 0) {
      throw ArgumentError('objectivesMastered cannot be negative');
    }
    if (currentStreak < 0) {
      throw ArgumentError('currentStreak cannot be negative');
    }
  }

  /// Empty performance summary for new learners or unstarted exams.
  factory LearnerPerformanceSummary.empty({int totalObjectives = 0}) =>
      LearnerPerformanceSummary(
        totalAttempts: 0,
        totalQuestionsAttempted: 0,
        correctCount: 0,
        incorrectCount: 0,
        accuracy: 0.0,
        objectivesAttempted: 0,
        objectivesMastered: 0,
        objectivesNeedingRemediation: 0,
        totalObjectives: totalObjectives,
        completionRate: 0.0,
        currentStreak: 0,
      );

  Map<String, dynamic> toJson() => {
        'totalAttempts': totalAttempts,
        'totalQuestionsAttempted': totalQuestionsAttempted,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'accuracy': accuracy,
        'accuracyPercentage': accuracyPercentage,
        'objectivesAttempted': objectivesAttempted,
        'objectivesMastered': objectivesMastered,
        'objectivesNeedingRemediation': objectivesNeedingRemediation,
        'totalObjectives': totalObjectives,
        'completionRate': completionRate,
        'completionPercentage': completionPercentage,
        'currentStreak': currentStreak,
        if (lastActiveAt != null)
          'lastActiveAt': lastActiveAt!.toIso8601String(),
      };

  factory LearnerPerformanceSummary.fromJson(Map<String, dynamic> json) =>
      LearnerPerformanceSummary(
        totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
        totalQuestionsAttempted:
            (json['totalQuestionsAttempted'] as num?)?.toInt(),
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        incorrectCount: (json['incorrectCount'] as num?)?.toInt(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        objectivesAttempted:
            (json['objectivesAttempted'] as num?)?.toInt() ?? 0,
        objectivesMastered: (json['objectivesMastered'] as num?)?.toInt() ?? 0,
        objectivesNeedingRemediation:
            (json['objectivesNeedingRemediation'] as num?)?.toInt() ?? 0,
        totalObjectives: (json['totalObjectives'] as num?)?.toInt() ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble(),
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String).toUtc()
            : null,
      );
}

/// A discrete chronological data point capturing performance evidence over time.
@immutable
class PerformanceTrendPoint {
  /// UTC timestamp of the evidence event.
  final DateTime timestamp;

  /// Identifier of the practice or assessment session, if applicable.
  final String? sessionId;

  /// Identifier of the completed learning activity, if applicable.
  final String? activityId;

  /// Questions attempted in this event.
  final int attempts;

  /// Correct answers in this event.
  final int correctCount;

  /// Accuracy achieved in this event [0.0, 1.0].
  final double accuracy;

  /// Running cumulative attempts up to and including this point.
  final int cumulativeAttempts;

  /// Running cumulative accuracy up to and including this point.
  final double cumulativeAccuracy;

  /// Associated objective or topic identifier, if targeted.
  final String? targetId;

  const PerformanceTrendPoint({
    required this.timestamp,
    this.sessionId,
    this.activityId,
    required this.attempts,
    required this.correctCount,
    required this.accuracy,
    required this.cumulativeAttempts,
    required this.cumulativeAccuracy,
    this.targetId,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        if (sessionId != null) 'sessionId': sessionId,
        if (activityId != null) 'activityId': activityId,
        'attempts': attempts,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'cumulativeAttempts': cumulativeAttempts,
        'cumulativeAccuracy': cumulativeAccuracy,
        if (targetId != null) 'targetId': targetId,
      };

  factory PerformanceTrendPoint.fromJson(Map<String, dynamic> json) =>
      PerformanceTrendPoint(
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        sessionId: json['sessionId'] as String?,
        activityId: json['activityId'] as String?,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        cumulativeAttempts: (json['cumulativeAttempts'] as num?)?.toInt() ?? 0,
        cumulativeAccuracy:
            (json['cumulativeAccuracy'] as num?)?.toDouble() ?? 0.0,
        targetId: json['targetId'] as String?,
      );
}

/// Diagnosed weak area metric with hierarchical context and recommended intervention.
@immutable
class WeakAreaMetric {
  /// Canonical identifier of the weak entity.
  final String id;

  /// Human-readable title or label of the weak area.
  final String name;

  /// Structural dimension: 'objective', 'topic', or 'subject'.
  final String dimension;

  /// Subject identifier context.
  final String? subjectId;

  /// Subject display name context.
  final String? subjectName;

  /// Topic identifier context.
  final String? topicId;

  /// Topic display name context.
  final String? topicName;

  /// Total question attempts recorded.
  final int attempts;

  /// Total correct attempts recorded.
  final int correctCount;

  /// Accuracy ratio in [0.0, 1.0].
  final double accuracy;

  /// Accuracy expressed as a percentage [0.0, 100.0].
  double get accuracyPercentage => accuracy * 100.0;

  /// Current mastery progression stage.
  final ProgressionStage stage;

  /// Pedagogical recommended next action (from MasteryProgressionService).
  final String recommendedAction;

  /// Whether active remedial intervention is urgently required.
  final bool isRemediationRequired;

  const WeakAreaMetric({
    required this.id,
    required this.name,
    required this.dimension,
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
    required this.attempts,
    required this.correctCount,
    required this.accuracy,
    required this.stage,
    required this.recommendedAction,
    this.isRemediationRequired = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dimension': dimension,
        if (subjectId != null) 'subjectId': subjectId,
        if (subjectName != null) 'subjectName': subjectName,
        if (topicId != null) 'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
        'attempts': attempts,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'stage': stage.name,
        'recommendedAction': recommendedAction,
        'isRemediationRequired': isRemediationRequired,
      };

  factory WeakAreaMetric.fromJson(Map<String, dynamic> json) => WeakAreaMetric(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        dimension: json['dimension'] as String? ?? 'objective',
        subjectId: json['subjectId'] as String?,
        subjectName: json['subjectName'] as String?,
        topicId: json['topicId'] as String?,
        topicName: json['topicName'] as String?,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        stage: ProgressionStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => ProgressionStage.notStarted,
        ),
        recommendedAction: json['recommendedAction'] as String? ?? '',
        isRemediationRequired: json['isRemediationRequired'] as bool? ?? false,
      );
}

/// Detailed performance breakdown for an individual learning objective.
@immutable
class ObjectiveAnalytics {
  final String objectiveId;
  final String title;
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final String subjectTitle;
  final int attempts;
  final int correctCount;
  final double accuracy;
  double get accuracyPercentage => accuracy * 100.0;
  final ProgressionStage stage;
  final DateTime? lastAttemptAt;
  final String? recommendedAction;

  const ObjectiveAnalytics({
    required this.objectiveId,
    required this.title,
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    required this.subjectTitle,
    required this.attempts,
    required this.correctCount,
    required this.accuracy,
    required this.stage,
    this.lastAttemptAt,
    this.recommendedAction,
  });

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'title': title,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'subjectId': subjectId,
        'subjectTitle': subjectTitle,
        'attempts': attempts,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'stage': stage.name,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toIso8601String(),
        if (recommendedAction != null) 'recommendedAction': recommendedAction,
      };

  factory ObjectiveAnalytics.fromJson(Map<String, dynamic> json) =>
      ObjectiveAnalytics(
        objectiveId: json['objectiveId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        topicId: json['topicId'] as String? ?? '',
        topicTitle: json['topicTitle'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        subjectTitle: json['subjectTitle'] as String? ?? '',
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        stage: ProgressionStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => ProgressionStage.notStarted,
        ),
        lastAttemptAt: json['lastAttemptAt'] != null
            ? DateTime.parse(json['lastAttemptAt'] as String).toUtc()
            : null,
        recommendedAction: json['recommendedAction'] as String?,
      );
}

/// Aggregate performance breakdown for a curriculum topic (unit).
@immutable
class TopicAnalytics {
  final String topicId;
  final String title;
  final String subjectId;
  final String subjectTitle;
  final int questionsAttempted;
  final int correctCount;
  final double accuracy;
  double get accuracyPercentage => accuracy * 100.0;
  final int totalObjectives;
  final int objectivesAttempted;
  final int objectivesMastered;
  final double progress;
  double get progressPercentage => progress * 100.0;
  final List<ObjectiveAnalytics> objectives;

  TopicAnalytics({
    required this.topicId,
    required this.title,
    required this.subjectId,
    required this.subjectTitle,
    required this.questionsAttempted,
    required this.correctCount,
    required this.accuracy,
    required this.totalObjectives,
    required this.objectivesAttempted,
    required this.objectivesMastered,
    required this.progress,
    List<ObjectiveAnalytics>? objectives,
  }) : objectives = List.unmodifiable(objectives ?? const []);

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'title': title,
        'subjectId': subjectId,
        'subjectTitle': subjectTitle,
        'questionsAttempted': questionsAttempted,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'totalObjectives': totalObjectives,
        'objectivesAttempted': objectivesAttempted,
        'objectivesMastered': objectivesMastered,
        'progress': progress,
        'objectives': objectives.map((o) => o.toJson()).toList(),
      };

  factory TopicAnalytics.fromJson(Map<String, dynamic> json) => TopicAnalytics(
        topicId: json['topicId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        subjectTitle: json['subjectTitle'] as String? ?? '',
        questionsAttempted: (json['questionsAttempted'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        totalObjectives: (json['totalObjectives'] as num?)?.toInt() ?? 0,
        objectivesAttempted:
            (json['objectivesAttempted'] as num?)?.toInt() ?? 0,
        objectivesMastered: (json['objectivesMastered'] as num?)?.toInt() ?? 0,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        objectives: (json['objectives'] as List<dynamic>?)
            ?.map((o) => ObjectiveAnalytics.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

/// Aggregate performance breakdown for a curriculum subject (domain).
@immutable
class SubjectAnalytics {
  final String subjectId;
  final String title;
  final String examId;
  final int questionsAttempted;
  final int correctCount;
  final double accuracy;
  double get accuracyPercentage => accuracy * 100.0;
  final int totalObjectives;
  final int objectivesAttempted;
  final int objectivesMastered;
  final double progress;
  double get progressPercentage => progress * 100.0;
  final List<TopicAnalytics> topics;

  SubjectAnalytics({
    required this.subjectId,
    required this.title,
    required this.examId,
    required this.questionsAttempted,
    required this.correctCount,
    required this.accuracy,
    required this.totalObjectives,
    required this.objectivesAttempted,
    required this.objectivesMastered,
    required this.progress,
    List<TopicAnalytics>? topics,
  }) : topics = List.unmodifiable(topics ?? const []);

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'title': title,
        'examId': examId,
        'questionsAttempted': questionsAttempted,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'totalObjectives': totalObjectives,
        'objectivesAttempted': objectivesAttempted,
        'objectivesMastered': objectivesMastered,
        'progress': progress,
        'topics': topics.map((t) => t.toJson()).toList(),
      };

  factory SubjectAnalytics.fromJson(Map<String, dynamic> json) =>
      SubjectAnalytics(
        subjectId: json['subjectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        questionsAttempted: (json['questionsAttempted'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        totalObjectives: (json['totalObjectives'] as num?)?.toInt() ?? 0,
        objectivesAttempted:
            (json['objectivesAttempted'] as num?)?.toInt() ?? 0,
        objectivesMastered: (json['objectivesMastered'] as num?)?.toInt() ?? 0,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        topics: (json['topics'] as List<dynamic>?)
            ?.map((t) => TopicAnalytics.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

/// Telemetry metrics for faculty-managed curriculum content items.
@immutable
class FacultyAnalyticsSummary {
  /// Identifier of the specific faculty member, or null if aggregated across all faculty.
  final String? authorId;

  /// Total content items authored/managed.
  final int totalContentItems;

  /// Managed questions authored.
  final int totalQuestions;

  /// Managed remedial lessons authored.
  final int totalRemedialLessons;

  /// Managed learning materials authored.
  final int totalLearningMaterials;

  /// Currently published content items.
  final int publishedCount;

  /// Content items in draft status.
  final int draftCount;

  /// Content items unpublished.
  final int unpublishedCount;

  /// Total learner attempts against faculty-created questions.
  final int learnerAttemptsOnManagedContent;

  /// Overall learner accuracy on faculty-created content [0.0, 1.0].
  final double learnerAccuracyOnManagedContent;

  /// Total active (published) content count available to learners.
  int get activeContentCount => publishedCount;

  const FacultyAnalyticsSummary({
    this.authorId,
    this.totalContentItems = 0,
    this.totalQuestions = 0,
    this.totalRemedialLessons = 0,
    this.totalLearningMaterials = 0,
    this.publishedCount = 0,
    this.draftCount = 0,
    this.unpublishedCount = 0,
    this.learnerAttemptsOnManagedContent = 0,
    this.learnerAccuracyOnManagedContent = 0.0,
  });

  Map<String, dynamic> toJson() => {
        if (authorId != null) 'authorId': authorId,
        'totalContentItems': totalContentItems,
        'totalQuestions': totalQuestions,
        'totalRemedialLessons': totalRemedialLessons,
        'totalLearningMaterials': totalLearningMaterials,
        'publishedCount': publishedCount,
        'draftCount': draftCount,
        'unpublishedCount': unpublishedCount,
        'learnerAttemptsOnManagedContent': learnerAttemptsOnManagedContent,
        'learnerAccuracyOnManagedContent': learnerAccuracyOnManagedContent,
      };

  factory FacultyAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      FacultyAnalyticsSummary(
        authorId: json['authorId'] as String?,
        totalContentItems: (json['totalContentItems'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        totalRemedialLessons:
            (json['totalRemedialLessons'] as num?)?.toInt() ?? 0,
        totalLearningMaterials:
            (json['totalLearningMaterials'] as num?)?.toInt() ?? 0,
        publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
        draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
        unpublishedCount: (json['unpublishedCount'] as num?)?.toInt() ?? 0,
        learnerAttemptsOnManagedContent:
            (json['learnerAttemptsOnManagedContent'] as num?)?.toInt() ?? 0,
        learnerAccuracyOnManagedContent:
            (json['learnerAccuracyOnManagedContent'] as num?)?.toDouble() ??
                0.0,
      );
}

/// Root aggregate report model containing comprehensive authoritative learning analytics.
@immutable
class LearnerAnalyticsReport {
  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (e.g. 'upsc_prelims_gs1').
  final String examId;

  /// UTC timestamp when this report was computed.
  final DateTime generatedAt;

  /// High-level performance metrics summary.
  final LearnerPerformanceSummary summary;

  /// Distribution of objectives across all progression stages.
  final Map<ProgressionStage, int> masteryDistribution;

  /// Chronological sequence of performance trend points.
  final List<PerformanceTrendPoint> performanceTrends;

  /// Ranked weak area metrics (diagnosed needs for improvement).
  final List<WeakAreaMetric> weakAreas;

  /// Hierarchical curriculum performance by subject.
  final List<SubjectAnalytics> subjects;

  /// Faculty content metrics, if available.
  final FacultyAnalyticsSummary? facultySummary;

  LearnerAnalyticsReport({
    required String learnerId,
    required String examId,
    required this.generatedAt,
    required this.summary,
    required Map<ProgressionStage, int> masteryDistribution,
    List<PerformanceTrendPoint>? performanceTrends,
    List<WeakAreaMetric>? weakAreas,
    List<SubjectAnalytics>? subjects,
    this.facultySummary,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        masteryDistribution = Map.unmodifiable(masteryDistribution),
        performanceTrends = List.unmodifiable(performanceTrends ?? const []),
        weakAreas = List.unmodifiable(weakAreas ?? const []),
        subjects = List.unmodifiable(subjects ?? const []) {
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
  }

  /// Whether the report has any learning activity or attempt records.
  bool get hasData => summary.totalAttempts > 0;

  /// Whether the report represents a completely clean/new learner state.
  bool get isEmpty =>
      summary.totalAttempts == 0 && summary.objectivesAttempted == 0;

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'examId': examId,
        'generatedAt': generatedAt.toIso8601String(),
        'summary': summary.toJson(),
        'masteryDistribution': {
          for (final entry in masteryDistribution.entries)
            entry.key.name: entry.value,
        },
        'performanceTrends': performanceTrends.map((p) => p.toJson()).toList(),
        'weakAreas': weakAreas.map((w) => w.toJson()).toList(),
        'subjects': subjects.map((s) => s.toJson()).toList(),
        if (facultySummary != null) 'facultySummary': facultySummary!.toJson(),
      };

  factory LearnerAnalyticsReport.fromJson(Map<String, dynamic> json) =>
      LearnerAnalyticsReport(
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        generatedAt: DateTime.parse(json['generatedAt'] as String).toUtc(),
        summary: LearnerPerformanceSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        masteryDistribution:
            (json['masteryDistribution'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(
                          ProgressionStage.values.firstWhere(
                            (s) => s.name == k,
                            orElse: () => ProgressionStage.notStarted,
                          ),
                          (v as num).toInt(),
                        )) ??
                const {},
        performanceTrends: (json['performanceTrends'] as List<dynamic>?)
            ?.map((p) =>
                PerformanceTrendPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        weakAreas: (json['weakAreas'] as List<dynamic>?)
            ?.map((w) => WeakAreaMetric.fromJson(w as Map<String, dynamic>))
            .toList(),
        subjects: (json['subjects'] as List<dynamic>?)
            ?.map((s) => SubjectAnalytics.fromJson(s as Map<String, dynamic>))
            .toList(),
        facultySummary: json['facultySummary'] != null
            ? FacultyAnalyticsSummary.fromJson(
                json['facultySummary'] as Map<String, dynamic>)
            : null,
      );
}
