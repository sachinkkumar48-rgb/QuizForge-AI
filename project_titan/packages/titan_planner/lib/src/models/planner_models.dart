import 'package:meta/meta.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';

/// Immutable model representing an individual task in a daily study plan.
@immutable
class StudyTask {
  final String id;
  final String title;
  final String topic;
  final String
      category; // 'Revision', 'Concept Learning', 'Practice & PYQ', 'Current Affairs'
  final String priority; // 'Urgent', 'High', 'Medium', 'Low'
  final int estimatedDurationMinutes;
  final DateTime? scheduledStartTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isRollover; // Carried forward from previous plan
  final String? sourceRecommendationId;

  const StudyTask({
    required this.id,
    required this.title,
    required this.topic,
    required this.category,
    required this.priority,
    required this.estimatedDurationMinutes,
    this.scheduledStartTime,
    this.isCompleted = false,
    this.completedAt,
    this.isRollover = false,
    this.sourceRecommendationId,
  });

  StudyTask copyWith({
    String? id,
    String? title,
    String? topic,
    String? category,
    String? priority,
    int? estimatedDurationMinutes,
    DateTime? scheduledStartTime,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isRollover,
    String? sourceRecommendationId,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isRollover: isRollover ?? this.isRollover,
      sourceRecommendationId:
          sourceRecommendationId ?? this.sourceRecommendationId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          topic == other.topic &&
          category == other.category &&
          priority == other.priority &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          scheduledStartTime == other.scheduledStartTime &&
          isCompleted == other.isCompleted &&
          completedAt == other.completedAt &&
          isRollover == other.isRollover &&
          sourceRecommendationId == other.sourceRecommendationId;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        topic,
        category,
        priority,
        estimatedDurationMinutes,
        scheduledStartTime,
        isCompleted,
        completedAt,
        isRollover,
        sourceRecommendationId,
      );
}

/// Immutable model representing aggregate metrics for a daily study plan.
@immutable
class StudySummary {
  final int totalTasksCount;
  final int completedTasksCount;
  final int totalAllocatedMinutes;
  final int completedMinutes;
  final int revisionMinutes;
  final int learningMinutes;
  final int practiceMinutes;
  final int currentAffairsMinutes;
  final double completionPercentage;
  final String topFocusTopic;

  const StudySummary({
    required this.totalTasksCount,
    required this.completedTasksCount,
    required this.totalAllocatedMinutes,
    required this.completedMinutes,
    required this.revisionMinutes,
    required this.learningMinutes,
    required this.practiceMinutes,
    required this.currentAffairsMinutes,
    required this.completionPercentage,
    required this.topFocusTopic,
  });

  StudySummary copyWith({
    int? totalTasksCount,
    int? completedTasksCount,
    int? totalAllocatedMinutes,
    int? completedMinutes,
    int? revisionMinutes,
    int? learningMinutes,
    int? practiceMinutes,
    int? currentAffairsMinutes,
    double? completionPercentage,
    String? topFocusTopic,
  }) {
    return StudySummary(
      totalTasksCount: totalTasksCount ?? this.totalTasksCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      totalAllocatedMinutes:
          totalAllocatedMinutes ?? this.totalAllocatedMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      revisionMinutes: revisionMinutes ?? this.revisionMinutes,
      learningMinutes: learningMinutes ?? this.learningMinutes,
      practiceMinutes: practiceMinutes ?? this.practiceMinutes,
      currentAffairsMinutes:
          currentAffairsMinutes ?? this.currentAffairsMinutes,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      topFocusTopic: topFocusTopic ?? this.topFocusTopic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySummary &&
          runtimeType == other.runtimeType &&
          totalTasksCount == other.totalTasksCount &&
          completedTasksCount == other.completedTasksCount &&
          totalAllocatedMinutes == other.totalAllocatedMinutes &&
          completedMinutes == other.completedMinutes &&
          revisionMinutes == other.revisionMinutes &&
          learningMinutes == other.learningMinutes &&
          practiceMinutes == other.practiceMinutes &&
          currentAffairsMinutes == other.currentAffairsMinutes &&
          completionPercentage == other.completionPercentage &&
          topFocusTopic == other.topFocusTopic;

  @override
  int get hashCode => Object.hash(
        totalTasksCount,
        completedTasksCount,
        totalAllocatedMinutes,
        completedMinutes,
        revisionMinutes,
        learningMinutes,
        practiceMinutes,
        currentAffairsMinutes,
        completionPercentage,
        topFocusTopic,
      );
}

/// Immutable domain model representing a personalized daily study plan.
@immutable
class StudyPlan {
  final String id;
  final String userId;
  final DateTime planDate;
  final int targetStudyTimeMinutes;
  final List<StudyTask> tasks;
  final StudySummary summary;
  final DateTime generatedAt;
  final bool isArchived;

  StudyPlan({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.targetStudyTimeMinutes,
    required List<StudyTask> tasks,
    required this.summary,
    required this.generatedAt,
    this.isArchived = false,
  }) : tasks = List<StudyTask>.unmodifiable(tasks);

  StudyPlan copyWith({
    String? id,
    String? userId,
    DateTime? planDate,
    int? targetStudyTimeMinutes,
    List<StudyTask>? tasks,
    StudySummary? summary,
    DateTime? generatedAt,
    bool? isArchived,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planDate: planDate ?? this.planDate,
      targetStudyTimeMinutes:
          targetStudyTimeMinutes ?? this.targetStudyTimeMinutes,
      tasks: tasks ?? this.tasks,
      summary: summary ?? this.summary,
      generatedAt: generatedAt ?? this.generatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          planDate == other.planDate &&
          targetStudyTimeMinutes == other.targetStudyTimeMinutes &&
          summary == other.summary &&
          generatedAt == other.generatedAt &&
          isArchived == other.isArchived &&
          _listEquals(tasks, other.tasks);

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        planDate,
        targetStudyTimeMinutes,
        summary,
        generatedAt,
        isArchived,
        Object.hashAll(tasks),
      );
}

/// Immutable context snapshot used by StudyPlannerEngine to generate study plans.
@immutable
class PlannerContext {
  final LearningProfile profile;
  final RevisionQueue revisionQueue;
  final List<Recommendation> recommendations;
  final int availableTimeMinutes;
  final List<StudyTask> previousUncompletedTasks;
  final DateTime planDate;

  PlannerContext({
    required this.profile,
    required this.revisionQueue,
    required List<Recommendation> recommendations,
    this.availableTimeMinutes = 180,
    List<StudyTask>? previousUncompletedTasks,
    required this.planDate,
  })  : recommendations = List<Recommendation>.unmodifiable(recommendations),
        previousUncompletedTasks =
            List<StudyTask>.unmodifiable(previousUncompletedTasks ?? const []);

  PlannerContext copyWith({
    LearningProfile? profile,
    RevisionQueue? revisionQueue,
    List<Recommendation>? recommendations,
    int? availableTimeMinutes,
    List<StudyTask>? previousUncompletedTasks,
    DateTime? planDate,
  }) {
    return PlannerContext(
      profile: profile ?? this.profile,
      revisionQueue: revisionQueue ?? this.revisionQueue,
      recommendations: recommendations ?? this.recommendations,
      availableTimeMinutes: availableTimeMinutes ?? this.availableTimeMinutes,
      previousUncompletedTasks:
          previousUncompletedTasks ?? this.previousUncompletedTasks,
      planDate: planDate ?? this.planDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannerContext &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          revisionQueue == other.revisionQueue &&
          availableTimeMinutes == other.availableTimeMinutes &&
          planDate == other.planDate &&
          _listEquals(recommendations, other.recommendations) &&
          _listEquals(previousUncompletedTasks, other.previousUncompletedTasks);

  @override
  int get hashCode => Object.hash(
        profile,
        revisionQueue,
        availableTimeMinutes,
        planDate,
        Object.hashAll(recommendations),
        Object.hashAll(previousUncompletedTasks),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
