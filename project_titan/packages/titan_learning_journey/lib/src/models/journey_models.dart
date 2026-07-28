import 'package:meta/meta.dart';

/// Enums for Learning Journey components

enum JourneyStageStatus {
  notStarted,
  inProgress,
  completed,
  locked,
}

enum MilestoneStatus {
  pending,
  active,
  achieved,
  overdue,
}

enum TaskStatus {
  todo,
  inProgress,
  completed,
  skipped,
}

enum CheckpointStatus {
  locked,
  pendingEvaluation,
  passed,
  failed,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

enum InsightType {
  strength,
  bottleneck,
  recommendation,
  risk,
  milestone,
}

enum HealthLevel {
  critical,
  atRisk,
  moderate,
  good,
  excellent,
}

enum GoalDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// 1. JourneyConfiguration
@immutable
class JourneyConfiguration {
  final String journeyId;
  final String targetExam;
  final DateTime targetExamDate;
  final int dailyTimeBudgetMinutes;
  final double targetConfidenceScore; // 0.0 to 1.0
  final List<String> preferredSubjects;
  final Map<String, dynamic> customSettings;

  const JourneyConfiguration({
    required this.journeyId,
    required this.targetExam,
    required this.targetExamDate,
    required this.dailyTimeBudgetMinutes,
    required this.targetConfidenceScore,
    this.preferredSubjects = const [],
    this.customSettings = const {},
  });

  JourneyConfiguration copyWith({
    String? journeyId,
    String? targetExam,
    DateTime? targetExamDate,
    int? dailyTimeBudgetMinutes,
    double? targetConfidenceScore,
    List<String>? preferredSubjects,
    Map<String, dynamic>? customSettings,
  }) {
    return JourneyConfiguration(
      journeyId: journeyId ?? this.journeyId,
      targetExam: targetExam ?? this.targetExam,
      targetExamDate: targetExamDate ?? this.targetExamDate,
      dailyTimeBudgetMinutes:
          dailyTimeBudgetMinutes ?? this.dailyTimeBudgetMinutes,
      targetConfidenceScore:
          targetConfidenceScore ?? this.targetConfidenceScore,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'targetExam': targetExam,
      'targetExamDate': targetExamDate.toIso8601String(),
      'dailyTimeBudgetMinutes': dailyTimeBudgetMinutes,
      'targetConfidenceScore': targetConfidenceScore,
      'preferredSubjects': preferredSubjects,
      'customSettings': customSettings,
    };
  }

  factory JourneyConfiguration.fromJson(Map<String, dynamic> json) {
    return JourneyConfiguration(
      journeyId: json['journeyId'] as String,
      targetExam: json['targetExam'] as String,
      targetExamDate: DateTime.parse(json['targetExamDate'] as String),
      dailyTimeBudgetMinutes: json['dailyTimeBudgetMinutes'] as int,
      targetConfidenceScore: (json['targetConfidenceScore'] as num).toDouble(),
      preferredSubjects:
          (json['preferredSubjects'] as List<dynamic>?)?.cast<String>() ?? [],
      customSettings:
          (json['customSettings'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyConfiguration &&
          runtimeType == other.runtimeType &&
          journeyId == other.journeyId &&
          targetExam == other.targetExam &&
          targetExamDate == other.targetExamDate &&
          dailyTimeBudgetMinutes == other.dailyTimeBudgetMinutes &&
          targetConfidenceScore == other.targetConfidenceScore;

  @override
  int get hashCode =>
      journeyId.hashCode ^
      targetExam.hashCode ^
      targetExamDate.hashCode ^
      dailyTimeBudgetMinutes.hashCode ^
      targetConfidenceScore.hashCode;
}

/// 2. JourneyTask
@immutable
class JourneyTask {
  final String id;
  final String title;
  final String description;
  final String moduleSource; // e.g. 'titan_academy', 'titan_video', etc.
  final String resourceId;
  final int estimatedMinutes;
  final TaskStatus status;
  final DateTime? completedAt;

  const JourneyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.moduleSource,
    required this.resourceId,
    required this.estimatedMinutes,
    this.status = TaskStatus.todo,
    this.completedAt,
  });

  JourneyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? moduleSource,
    String? resourceId,
    int? estimatedMinutes,
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return JourneyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      moduleSource: moduleSource ?? this.moduleSource,
      resourceId: resourceId ?? this.resourceId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'moduleSource': moduleSource,
      'resourceId': resourceId,
      'estimatedMinutes': estimatedMinutes,
      'status': status.name,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory JourneyTask.fromJson(Map<String, dynamic> json) {
    return JourneyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      moduleSource: json['moduleSource'] as String,
      resourceId: json['resourceId'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ status.hashCode;
}

/// 3. JourneyMilestone
@immutable
class JourneyMilestone {
  final String id;
  final String stageId;
  final String title;
  final String description;
  final DateTime targetDate;
  final MilestoneStatus status;
  final double progress; // 0.0 to 1.0
  final List<JourneyTask> tasks;
  final DateTime? achievedAt;

  const JourneyMilestone({
    required this.id,
    required this.stageId,
    required this.title,
    required this.description,
    required this.targetDate,
    this.status = MilestoneStatus.pending,
    this.progress = 0.0,
    this.tasks = const [],
    this.achievedAt,
  });

  JourneyMilestone copyWith({
    String? id,
    String? stageId,
    String? title,
    String? description,
    DateTime? targetDate,
    MilestoneStatus? status,
    double? progress,
    List<JourneyTask>? tasks,
    DateTime? achievedAt,
  }) {
    return JourneyMilestone(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      tasks: tasks ?? this.tasks,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageId': stageId,
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'status': status.name,
      'progress': progress,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'achievedAt': achievedAt?.toIso8601String(),
    };
  }

  factory JourneyMilestone.fromJson(Map<String, dynamic> json) {
    return JourneyMilestone(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MilestoneStatus.pending,
      ),
      progress: (json['progress'] as num).toDouble(),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => JourneyTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievedAt: json['achievedAt'] != null
          ? DateTime.parse(json['achievedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyMilestone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stageId == other.stageId &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode =>
      id.hashCode ^ stageId.hashCode ^ status.hashCode ^ progress.hashCode;
}

/// 4. JourneyCheckpoint
@immutable
class JourneyCheckpoint {
  final String id;
  final String stageId;
  final String title;
  final String description;
  final double requiredScore; // 0.0 to 100.0
  final double achievedScore;
  final CheckpointStatus status;
  final List<String> prerequisiteTopicIds;
  final DateTime? evaluatedAt;

  const JourneyCheckpoint({
    required this.id,
    required this.stageId,
    required this.title,
    required this.description,
    required this.requiredScore,
    this.achievedScore = 0.0,
    this.status = CheckpointStatus.locked,
    this.prerequisiteTopicIds = const [],
    this.evaluatedAt,
  });

  JourneyCheckpoint copyWith({
    String? id,
    String? stageId,
    String? title,
    String? description,
    double? requiredScore,
    double? achievedScore,
    CheckpointStatus? status,
    List<String>? prerequisiteTopicIds,
    DateTime? evaluatedAt,
  }) {
    return JourneyCheckpoint(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredScore: requiredScore ?? this.requiredScore,
      achievedScore: achievedScore ?? this.achievedScore,
      status: status ?? this.status,
      prerequisiteTopicIds: prerequisiteTopicIds ?? this.prerequisiteTopicIds,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageId': stageId,
      'title': title,
      'description': description,
      'requiredScore': requiredScore,
      'achievedScore': achievedScore,
      'status': status.name,
      'prerequisiteTopicIds': prerequisiteTopicIds,
      'evaluatedAt': evaluatedAt?.toIso8601String(),
    };
  }

  factory JourneyCheckpoint.fromJson(Map<String, dynamic> json) {
    return JourneyCheckpoint(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredScore: (json['requiredScore'] as num).toDouble(),
      achievedScore: (json['achievedScore'] as num).toDouble(),
      status: CheckpointStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CheckpointStatus.locked,
      ),
      prerequisiteTopicIds:
          (json['prerequisiteTopicIds'] as List<dynamic>?)?.cast<String>() ??
              [],
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.parse(json['evaluatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyCheckpoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stageId == other.stageId &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ stageId.hashCode ^ status.hashCode;
}

/// 5. JourneyStage
@immutable
class JourneyStage {
  final String id;
  final String journeyId;
  final int orderIndex;
  final String title;
  final String description;
  final JourneyStageStatus status;
  final double progress; // 0.0 to 1.0
  final List<JourneyMilestone> milestones;
  final JourneyCheckpoint? checkpoint;

  const JourneyStage({
    required this.id,
    required this.journeyId,
    required this.orderIndex,
    required this.title,
    required this.description,
    this.status = JourneyStageStatus.notStarted,
    this.progress = 0.0,
    this.milestones = const [],
    this.checkpoint,
  });

  JourneyStage copyWith({
    String? id,
    String? journeyId,
    int? orderIndex,
    String? title,
    String? description,
    JourneyStageStatus? status,
    double? progress,
    List<JourneyMilestone>? milestones,
    JourneyCheckpoint? checkpoint,
  }) {
    return JourneyStage(
      id: id ?? this.id,
      journeyId: journeyId ?? this.journeyId,
      orderIndex: orderIndex ?? this.orderIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      milestones: milestones ?? this.milestones,
      checkpoint: checkpoint ?? this.checkpoint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journeyId': journeyId,
      'orderIndex': orderIndex,
      'title': title,
      'description': description,
      'status': status.name,
      'progress': progress,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'checkpoint': checkpoint?.toJson(),
    };
  }

  factory JourneyStage.fromJson(Map<String, dynamic> json) {
    return JourneyStage(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      orderIndex: json['orderIndex'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: JourneyStageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => JourneyStageStatus.notStarted,
      ),
      progress: (json['progress'] as num).toDouble(),
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((e) => JourneyMilestone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      checkpoint: json['checkpoint'] != null
          ? JourneyCheckpoint.fromJson(
              json['checkpoint'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyStage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          journeyId == other.journeyId &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode =>
      id.hashCode ^ journeyId.hashCode ^ status.hashCode ^ progress.hashCode;
}

/// 6. JourneyGoal
@immutable
class JourneyGoal {
  final String id;
  final String title;
  final String description;
  final GoalDifficulty difficulty;
  final DateTime deadline;
  final double targetScore;
  final double currentScore;
  final bool isCompleted;

  const JourneyGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.deadline,
    required this.targetScore,
    this.currentScore = 0.0,
    this.isCompleted = false,
  });

  JourneyGoal copyWith({
    String? id,
    String? title,
    String? description,
    GoalDifficulty? difficulty,
    DateTime? deadline,
    double? targetScore,
    double? currentScore,
    bool? isCompleted,
  }) {
    return JourneyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      deadline: deadline ?? this.deadline,
      targetScore: targetScore ?? this.targetScore,
      currentScore: currentScore ?? this.currentScore,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'deadline': deadline.toIso8601String(),
      'targetScore': targetScore,
      'currentScore': currentScore,
      'isCompleted': isCompleted,
    };
  }

  factory JourneyGoal.fromJson(Map<String, dynamic> json) {
    return JourneyGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: GoalDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => GoalDifficulty.intermediate,
      ),
      deadline: DateTime.parse(json['deadline'] as String),
      targetScore: (json['targetScore'] as num).toDouble(),
      currentScore: (json['currentScore'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isCompleted.hashCode;
}

/// 7. JourneyRecommendation
@immutable
class JourneyRecommendation {
  final String id;
  final String sourceModule; // e.g., titan_recommendation, titan_ai_tutor
  final String title;
  final String rationale;
  final String actionType;
  final String targetResourceId;
  final int priorityScore; // 1 to 100
  final Map<String, dynamic> payload;

  const JourneyRecommendation({
    required this.id,
    required this.sourceModule,
    required this.title,
    required this.rationale,
    required this.actionType,
    required this.targetResourceId,
    required this.priorityScore,
    this.payload = const {},
  });

  JourneyRecommendation copyWith({
    String? id,
    String? sourceModule,
    String? title,
    String? rationale,
    String? actionType,
    String? targetResourceId,
    int? priorityScore,
    Map<String, dynamic>? payload,
  }) {
    return JourneyRecommendation(
      id: id ?? this.id,
      sourceModule: sourceModule ?? this.sourceModule,
      title: title ?? this.title,
      rationale: rationale ?? this.rationale,
      actionType: actionType ?? this.actionType,
      targetResourceId: targetResourceId ?? this.targetResourceId,
      priorityScore: priorityScore ?? this.priorityScore,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceModule': sourceModule,
      'title': title,
      'rationale': rationale,
      'actionType': actionType,
      'targetResourceId': targetResourceId,
      'priorityScore': priorityScore,
      'payload': payload,
    };
  }

  factory JourneyRecommendation.fromJson(Map<String, dynamic> json) {
    return JourneyRecommendation(
      id: json['id'] as String,
      sourceModule: json['sourceModule'] as String,
      title: json['title'] as String,
      rationale: json['rationale'] as String,
      actionType: json['actionType'] as String,
      targetResourceId: json['targetResourceId'] as String,
      priorityScore: json['priorityScore'] as int,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyRecommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceModule == other.sourceModule &&
          priorityScore == other.priorityScore;

  @override
  int get hashCode =>
      id.hashCode ^ sourceModule.hashCode ^ priorityScore.hashCode;
}

/// 8. JourneyProgress
@immutable
class JourneyProgress {
  final String journeyId;
  final double overallProgress; // 0.0 to 1.0
  final int completedMilestonesCount;
  final int totalMilestonesCount;
  final int completedTasksCount;
  final int totalTasksCount;
  final double weeklyVelocityMinutes;
  final int streakDays;
  final DateTime lastActiveAt;

  const JourneyProgress({
    required this.journeyId,
    required this.overallProgress,
    required this.completedMilestonesCount,
    required this.totalMilestonesCount,
    required this.completedTasksCount,
    required this.totalTasksCount,
    required this.weeklyVelocityMinutes,
    required this.streakDays,
    required this.lastActiveAt,
  });

  JourneyProgress copyWith({
    String? journeyId,
    double? overallProgress,
    int? completedMilestonesCount,
    int? totalMilestonesCount,
    int? completedTasksCount,
    int? totalTasksCount,
    double? weeklyVelocityMinutes,
    int? streakDays,
    DateTime? lastActiveAt,
  }) {
    return JourneyProgress(
      journeyId: journeyId ?? this.journeyId,
      overallProgress: overallProgress ?? this.overallProgress,
      completedMilestonesCount:
          completedMilestonesCount ?? this.completedMilestonesCount,
      totalMilestonesCount: totalMilestonesCount ?? this.totalMilestonesCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      totalTasksCount: totalTasksCount ?? this.totalTasksCount,
      weeklyVelocityMinutes:
          weeklyVelocityMinutes ?? this.weeklyVelocityMinutes,
      streakDays: streakDays ?? this.streakDays,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'overallProgress': overallProgress,
      'completedMilestonesCount': completedMilestonesCount,
      'totalMilestonesCount': totalMilestonesCount,
      'completedTasksCount': completedTasksCount,
      'totalTasksCount': totalTasksCount,
      'weeklyVelocityMinutes': weeklyVelocityMinutes,
      'streakDays': streakDays,
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    return JourneyProgress(
      journeyId: json['journeyId'] as String,
      overallProgress: (json['overallProgress'] as num).toDouble(),
      completedMilestonesCount: json['completedMilestonesCount'] as int,
      totalMilestonesCount: json['totalMilestonesCount'] as int,
      completedTasksCount: json['completedTasksCount'] as int,
      totalTasksCount: json['totalTasksCount'] as int,
      weeklyVelocityMinutes: (json['weeklyVelocityMinutes'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyProgress &&
          runtimeType == other.runtimeType &&
          journeyId == other.journeyId &&
          overallProgress == other.overallProgress &&
          streakDays == other.streakDays;

  @override
  int get hashCode =>
      journeyId.hashCode ^ overallProgress.hashCode ^ streakDays.hashCode;
}

/// 9. JourneyAchievement
@immutable
class JourneyAchievement {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final AchievementRarity rarity;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const JourneyAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.rarity,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  JourneyAchievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconAsset,
    AchievementRarity? rarity,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return JourneyAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconAsset': iconAsset,
      'rarity': rarity.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory JourneyAchievement.fromJson(Map<String, dynamic> json) {
    return JourneyAchievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconAsset: json['iconAsset'] as String,
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyAchievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isUnlocked == other.isUnlocked;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isUnlocked.hashCode;
}

/// 10. JourneyTimeline
@immutable
class JourneyTimeline {
  final String journeyId;
  final List<JourneyTimelineEvent> events;

  const JourneyTimeline({
    required this.journeyId,
    this.events = const [],
  });

  JourneyTimeline copyWith({
    String? journeyId,
    List<JourneyTimelineEvent>? events,
  }) {
    return JourneyTimeline(
      journeyId: journeyId ?? this.journeyId,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory JourneyTimeline.fromJson(Map<String, dynamic> json) {
    return JourneyTimeline(
      journeyId: json['journeyId'] as String,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) =>
                  JourneyTimelineEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@immutable
class JourneyTimelineEvent {
  final String id;
  final String title;
  final String description;
  final String category; // 'milestone', 'checkpoint', 'achievement', 'study'
  final DateTime timestamp;

  const JourneyTimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory JourneyTimelineEvent.fromJson(Map<String, dynamic> json) {
    return JourneyTimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// 11. JourneyInsight
@immutable
class JourneyInsight {
  final String id;
  final InsightType type;
  final String title;
  final String summary;
  final String detail;
  final double impactScore; // 0.0 to 100.0
  final DateTime createdAt;

  const JourneyInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.detail,
    required this.impactScore,
    required this.createdAt,
  });

  JourneyInsight copyWith({
    String? id,
    InsightType? type,
    String? title,
    String? summary,
    String? detail,
    double? impactScore,
    DateTime? createdAt,
  }) {
    return JourneyInsight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      detail: detail ?? this.detail,
      impactScore: impactScore ?? this.impactScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'summary': summary,
      'detail': detail,
      'impactScore': impactScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JourneyInsight.fromJson(Map<String, dynamic> json) {
    return JourneyInsight(
      id: json['id'] as String,
      type: InsightType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsightType.recommendation,
      ),
      title: json['title'] as String,
      summary: json['summary'] as String,
      detail: json['detail'] as String,
      impactScore: (json['impactScore'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyInsight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ title.hashCode;
}

/// 12. JourneyForecast
@immutable
class JourneyForecast {
  final String journeyId;
  final DateTime predictedCompletionDate;
  final double examReadinessProbability; // 0.0 to 1.0 (0% to 100%)
  final double projectedFinalScore; // 0.0 to 100.0
  final double velocityTrend; // >1.0 accelerating, <1.0 slowing down
  final String forecastSummary;
  final DateTime generatedAt;

  const JourneyForecast({
    required this.journeyId,
    required this.predictedCompletionDate,
    required this.examReadinessProbability,
    required this.projectedFinalScore,
    required this.velocityTrend,
    required this.forecastSummary,
    required this.generatedAt,
  });

  JourneyForecast copyWith({
    String? journeyId,
    DateTime? predictedCompletionDate,
    double? examReadinessProbability,
    double? projectedFinalScore,
    double? velocityTrend,
    String? forecastSummary,
    DateTime? generatedAt,
  }) {
    return JourneyForecast(
      journeyId: journeyId ?? this.journeyId,
      predictedCompletionDate:
          predictedCompletionDate ?? this.predictedCompletionDate,
      examReadinessProbability:
          examReadinessProbability ?? this.examReadinessProbability,
      projectedFinalScore: projectedFinalScore ?? this.projectedFinalScore,
      velocityTrend: velocityTrend ?? this.velocityTrend,
      forecastSummary: forecastSummary ?? this.forecastSummary,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'predictedCompletionDate': predictedCompletionDate.toIso8601String(),
      'examReadinessProbability': examReadinessProbability,
      'projectedFinalScore': projectedFinalScore,
      'velocityTrend': velocityTrend,
      'forecastSummary': forecastSummary,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory JourneyForecast.fromJson(Map<String, dynamic> json) {
    return JourneyForecast(
      journeyId: json['journeyId'] as String,
      predictedCompletionDate:
          DateTime.parse(json['predictedCompletionDate'] as String),
      examReadinessProbability:
          (json['examReadinessProbability'] as num).toDouble(),
      projectedFinalScore: (json['projectedFinalScore'] as num).toDouble(),
      velocityTrend: (json['velocityTrend'] as num).toDouble(),
      forecastSummary: json['forecastSummary'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyForecast &&
          runtimeType == other.runtimeType &&
          journeyId == other.journeyId &&
          examReadinessProbability == other.examReadinessProbability;

  @override
  int get hashCode => journeyId.hashCode ^ examReadinessProbability.hashCode;
}

/// 13. JourneyHealth
@immutable
class JourneyHealth {
  final String journeyId;
  final double score; // 0.0 to 100.0
  final HealthLevel level;
  final double consistencyScore; // 0.0 to 100.0
  final double retentionScore; // 0.0 to 100.0
  final double assessmentReadinessScore; // 0.0 to 100.0
  final double activityPaceScore; // 0.0 to 100.0
  final List<String> healthFactors;

  const JourneyHealth({
    required this.journeyId,
    required this.score,
    required this.level,
    required this.consistencyScore,
    required this.retentionScore,
    required this.assessmentReadinessScore,
    required this.activityPaceScore,
    this.healthFactors = const [],
  });

  JourneyHealth copyWith({
    String? journeyId,
    double? score,
    HealthLevel? level,
    double? consistencyScore,
    double? retentionScore,
    double? assessmentReadinessScore,
    double? activityPaceScore,
    List<String>? healthFactors,
  }) {
    return JourneyHealth(
      journeyId: journeyId ?? this.journeyId,
      score: score ?? this.score,
      level: level ?? this.level,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      retentionScore: retentionScore ?? this.retentionScore,
      assessmentReadinessScore:
          assessmentReadinessScore ?? this.assessmentReadinessScore,
      activityPaceScore: activityPaceScore ?? this.activityPaceScore,
      healthFactors: healthFactors ?? this.healthFactors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'score': score,
      'level': level.name,
      'consistencyScore': consistencyScore,
      'retentionScore': retentionScore,
      'assessmentReadinessScore': assessmentReadinessScore,
      'activityPaceScore': activityPaceScore,
      'healthFactors': healthFactors,
    };
  }

  factory JourneyHealth.fromJson(Map<String, dynamic> json) {
    return JourneyHealth(
      journeyId: json['journeyId'] as String,
      score: (json['score'] as num).toDouble(),
      level: HealthLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => HealthLevel.moderate,
      ),
      consistencyScore: (json['consistencyScore'] as num).toDouble(),
      retentionScore: (json['retentionScore'] as num).toDouble(),
      assessmentReadinessScore:
          (json['assessmentReadinessScore'] as num).toDouble(),
      activityPaceScore: (json['activityPaceScore'] as num).toDouble(),
      healthFactors:
          (json['healthFactors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyHealth &&
          runtimeType == other.runtimeType &&
          journeyId == other.journeyId &&
          score == other.score &&
          level == other.level;

  @override
  int get hashCode => journeyId.hashCode ^ score.hashCode ^ level.hashCode;
}

/// 14. JourneySnapshot
@immutable
class JourneySnapshot {
  final String id;
  final String journeyId;
  final JourneyProgress progress;
  final JourneyHealth health;
  final JourneyForecast forecast;
  final DateTime capturedAt;

  const JourneySnapshot({
    required this.id,
    required this.journeyId,
    required this.progress,
    required this.health,
    required this.forecast,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journeyId': journeyId,
      'progress': progress.toJson(),
      'health': health.toJson(),
      'forecast': forecast.toJson(),
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory JourneySnapshot.fromJson(Map<String, dynamic> json) {
    return JourneySnapshot(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      progress:
          JourneyProgress.fromJson(json['progress'] as Map<String, dynamic>),
      health: JourneyHealth.fromJson(json['health'] as Map<String, dynamic>),
      forecast:
          JourneyForecast.fromJson(json['forecast'] as Map<String, dynamic>),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}

/// 15. LearningJourney (Root Aggregate)
@immutable
class LearningJourney {
  final String id;
  final String learnerId;
  final JourneyConfiguration config;
  final List<JourneyStage> stages;
  final List<JourneyGoal> goals;
  final List<JourneyAchievement> achievements;
  final JourneyHealth health;
  final JourneyForecast forecast;
  final JourneyProgress progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningJourney({
    required this.id,
    required this.learnerId,
    required this.config,
    required this.stages,
    required this.goals,
    required this.achievements,
    required this.health,
    required this.forecast,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  LearningJourney copyWith({
    String? id,
    String? learnerId,
    JourneyConfiguration? config,
    List<JourneyStage>? stages,
    List<JourneyGoal>? goals,
    List<JourneyAchievement>? achievements,
    JourneyHealth? health,
    JourneyForecast? forecast,
    JourneyProgress? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningJourney(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      config: config ?? this.config,
      stages: stages ?? this.stages,
      goals: goals ?? this.goals,
      achievements: achievements ?? this.achievements,
      health: health ?? this.health,
      forecast: forecast ?? this.forecast,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'learnerId': learnerId,
      'config': config.toJson(),
      'stages': stages.map((s) => s.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'health': health.toJson(),
      'forecast': forecast.toJson(),
      'progress': progress.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearningJourney.fromJson(Map<String, dynamic> json) {
    return LearningJourney(
      id: json['id'] as String,
      learnerId: json['learnerId'] as String,
      config:
          JourneyConfiguration.fromJson(json['config'] as Map<String, dynamic>),
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => JourneyStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => JourneyGoal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map(
                  (e) => JourneyAchievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      health: JourneyHealth.fromJson(json['health'] as Map<String, dynamic>),
      forecast:
          JourneyForecast.fromJson(json['forecast'] as Map<String, dynamic>),
      progress:
          JourneyProgress.fromJson(json['progress'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningJourney &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          learnerId == other.learnerId &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ learnerId.hashCode ^ updatedAt.hashCode;
}
