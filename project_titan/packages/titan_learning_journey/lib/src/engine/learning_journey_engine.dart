import '../models/journey_models.dart';

/// Pure Dart core business logic engine for Project TITAN Learning Journey.
/// 100% Flutter independent.
class LearningJourneyEngine {
  const LearningJourneyEngine();

  /// 1. Roadmap Generation
  LearningJourney generateRoadmap({
    required String learnerId,
    required JourneyConfiguration config,
  }) {
    final now = DateTime.now();
    final journeyId = 'journey_${learnerId}_${now.millisecondsSinceEpoch}';

    const stage1Tasks = [
      JourneyTask(
        id: 'task_s1_t1',
        title: 'Complete Foundation Syllabus Overview',
        description: 'Review main topics and foundational concepts',
        moduleSource: 'titan_academy',
        resourceId: 'course_foundations_101',
        estimatedMinutes: 60,
      ),
      JourneyTask(
        id: 'task_s1_t2',
        title: 'Baseline Diagnostic Assessment',
        description: 'Take adaptive test to evaluate starting knowledge',
        moduleSource: 'titan_smart_assessment',
        resourceId: 'assessment_diag_01',
        estimatedMinutes: 45,
      ),
    ];

    const stage1Checkpoint = JourneyCheckpoint(
      id: 'chk_stage_1',
      stageId: 'stage_1',
      title: 'Foundation Gate Checkpoint',
      description:
          'Validate prerequisite foundation mastery before core topics',
      requiredScore: 60.0,
      status: CheckpointStatus.pendingEvaluation,
    );

    final stage1Milestone = JourneyMilestone(
      id: 'ms_stage_1_1',
      stageId: 'stage_1',
      title: 'Foundational Knowledge Setup',
      description: 'Establish foundational concepts across key topics',
      targetDate: now.add(const Duration(days: 7)),
      status: MilestoneStatus.active,
      tasks: stage1Tasks,
    );

    final stage1 = JourneyStage(
      id: 'stage_1',
      journeyId: journeyId,
      orderIndex: 0,
      title: 'Foundation Building',
      description: 'Build basic conceptual grounding and baseline profile',
      status: JourneyStageStatus.inProgress,
      milestones: [stage1Milestone],
      checkpoint: stage1Checkpoint,
    );

    const stage2Tasks = [
      JourneyTask(
        id: 'task_s2_t1',
        title: 'Core Topic Module 1',
        description: 'Study core syllabus chapters and take key notes',
        moduleSource: 'titan_learning_content',
        resourceId: 'content_core_01',
        estimatedMinutes: 90,
      ),
      JourneyTask(
        id: 'task_s2_t2',
        title: 'Topic Practice Quiz',
        description: 'Practice conceptual questions on core topics',
        moduleSource: 'titan_smart_assessment',
        resourceId: 'quiz_core_01',
        estimatedMinutes: 30,
      ),
    ];

    final stage2Milestone = JourneyMilestone(
      id: 'ms_stage_2_1',
      stageId: 'stage_2',
      title: 'Core Syllabus Mastery',
      description: 'Complete core curriculum subjects and practice sets',
      targetDate: now.add(const Duration(days: 21)),
      status: MilestoneStatus.pending,
      tasks: stage2Tasks,
    );

    const stage2Checkpoint = JourneyCheckpoint(
      id: 'chk_stage_2',
      stageId: 'stage_2',
      title: 'Core Mastery Gate Checkpoint',
      description: 'Validate core topic proficiency',
      requiredScore: 70.0,
      status: CheckpointStatus.locked,
    );

    final stage2 = JourneyStage(
      id: 'stage_2',
      journeyId: journeyId,
      orderIndex: 1,
      title: 'Core Concept Mastery',
      description:
          'Deep dive into essential subject matter and problem solving',
      status: JourneyStageStatus.locked,
      milestones: [stage2Milestone],
      checkpoint: stage2Checkpoint,
    );

    final stage3Milestone = JourneyMilestone(
      id: 'ms_stage_3_1',
      stageId: 'stage_3',
      title: 'Advanced Practice & Spaced Revision',
      description: 'Engage in spaced repetition and high-level problem solving',
      targetDate: now.add(const Duration(days: 45)),
      status: MilestoneStatus.pending,
      tasks: const [
        JourneyTask(
          id: 'task_s3_t1',
          title: 'Spaced Repetition Queue',
          description: 'Clear scheduled revision flashcards',
          moduleSource: 'titan_revision',
          resourceId: 'revision_queue_01',
          estimatedMinutes: 40,
        ),
      ],
    );

    const stage3Checkpoint = JourneyCheckpoint(
      id: 'chk_stage_3',
      stageId: 'stage_3',
      title: 'Advanced Readiness Gate',
      description: 'Assess advanced retention and accuracy',
      requiredScore: 75.0,
      status: CheckpointStatus.locked,
    );

    final stage3 = JourneyStage(
      id: 'stage_3',
      journeyId: journeyId,
      orderIndex: 2,
      title: 'Advanced Application & Practice',
      description:
          'Application of concepts, speed building, and targeted revision',
      status: JourneyStageStatus.locked,
      milestones: [stage3Milestone],
      checkpoint: stage3Checkpoint,
    );

    final stage4Milestone = JourneyMilestone(
      id: 'ms_stage_4_1',
      stageId: 'stage_4',
      title: 'Full Mock Exam Series',
      description:
          'Complete full-length exam simulations under timed conditions',
      targetDate: config.targetExamDate.subtract(const Duration(days: 5)),
      status: MilestoneStatus.pending,
      tasks: const [
        JourneyTask(
          id: 'task_s4_t1',
          title: 'Full Mock Exam #1',
          description: 'Simulated full length exam',
          moduleSource: 'titan_smart_assessment',
          resourceId: 'mock_exam_full_01',
          estimatedMinutes: 120,
        ),
      ],
    );

    const stage4Checkpoint = JourneyCheckpoint(
      id: 'chk_stage_4',
      stageId: 'stage_4',
      title: 'Final Exam Gate Checkpoint',
      description: 'Final readiness validation before official exam date',
      requiredScore: 80.0,
      status: CheckpointStatus.locked,
    );

    final stage4 = JourneyStage(
      id: 'stage_4',
      journeyId: journeyId,
      orderIndex: 3,
      title: 'Exam Readiness & Mock Drills',
      description:
          'Final exam simulations, error log reviews, and confidence boosting',
      status: JourneyStageStatus.locked,
      milestones: [stage4Milestone],
      checkpoint: stage4Checkpoint,
    );

    final stages = [stage1, stage2, stage3, stage4];

    final initialGoal = JourneyGoal(
      id: 'goal_main',
      title: 'Target Exam Qualification',
      description: 'Qualify ${config.targetExam} with target confidence',
      difficulty: GoalDifficulty.intermediate,
      deadline: config.targetExamDate,
      targetScore: config.targetConfidenceScore * 100,
    );

    final initialProgress = calculateProgress(
      journeyId: journeyId,
      stages: stages,
      streakDays: 1,
      weeklyVelocityMinutes: 0.0,
    );

    final initialHealth = calculateHealth(
      journeyId: journeyId,
      progress: initialProgress,
      averageAssessmentScore: 60.0,
      revisionRetentionRate: 0.70,
    );

    final initialForecast = calculateForecast(
      journeyId: journeyId,
      config: config,
      progress: initialProgress,
      health: initialHealth,
    );

    final defaultAchievements = evaluateAchievements(
      completedMilestonesCount: 0,
      completedTasksCount: 0,
      streakDays: 1,
      checkpointsPassed: 0,
      healthScore: initialHealth.score,
    );

    return LearningJourney(
      id: journeyId,
      learnerId: learnerId,
      config: config,
      stages: stages,
      goals: [initialGoal],
      achievements: defaultAchievements,
      health: initialHealth,
      forecast: initialForecast,
      progress: initialProgress,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 2. Adaptive Sequencing
  LearningJourney sequenceJourney({
    required LearningJourney journey,
    required Map<String, double> topicMastery,
  }) {
    // Adaptively update stages and milestones based on topic mastery scores
    final updatedStages = journey.stages.map((stage) {
      final updatedMilestones = stage.milestones.map((milestone) {
        double updatedProgress = milestone.progress;
        if (topicMastery.isNotEmpty) {
          final avgMastery =
              topicMastery.values.reduce((a, b) => a + b) / topicMastery.length;
          updatedProgress =
              (milestone.progress + avgMastery * 0.1).clamp(0.0, 1.0);
        }
        return milestone.copyWith(progress: updatedProgress);
      }).toList();

      return stage.copyWith(milestones: updatedMilestones);
    }).toList();

    final updatedProgress = calculateProgress(
      journeyId: journey.id,
      stages: updatedStages,
      streakDays: journey.progress.streakDays,
      weeklyVelocityMinutes: journey.progress.weeklyVelocityMinutes,
    );

    final updatedHealth = calculateHealth(
      journeyId: journey.id,
      progress: updatedProgress,
      averageAssessmentScore: topicMastery.values.isEmpty
          ? 60.0
          : (topicMastery.values.reduce((a, b) => a + b) /
                  topicMastery.length) *
              100,
      revisionRetentionRate: 0.75,
    );

    final updatedForecast = calculateForecast(
      journeyId: journey.id,
      config: journey.config,
      progress: updatedProgress,
      health: updatedHealth,
    );

    return journey.copyWith(
      stages: updatedStages,
      progress: updatedProgress,
      health: updatedHealth,
      forecast: updatedForecast,
      updatedAt: DateTime.now(),
    );
  }

  /// 3. Milestone Management
  JourneyMilestone updateMilestoneProgress({
    required JourneyMilestone milestone,
    required List<JourneyTask> updatedTasks,
  }) {
    final completedCount =
        updatedTasks.where((t) => t.status == TaskStatus.completed).length;
    final totalCount = updatedTasks.length;
    final double progress =
        totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);

    MilestoneStatus status = milestone.status;
    DateTime? achievedAt = milestone.achievedAt;

    if (progress >= 1.0) {
      status = MilestoneStatus.achieved;
      achievedAt ??= DateTime.now();
    } else if (progress > 0.0) {
      status = MilestoneStatus.active;
    }

    return milestone.copyWith(
      tasks: updatedTasks,
      progress: progress,
      status: status,
      achievedAt: achievedAt,
    );
  }

  /// 4. Learning Health Scoring
  JourneyHealth calculateHealth({
    required String journeyId,
    required JourneyProgress progress,
    required double averageAssessmentScore,
    required double revisionRetentionRate,
  }) {
    // 1. Consistency Score (based on streak & activity)
    final double consistencyScore =
        (progress.streakDays * 10.0 + progress.overallProgress * 30.0)
            .clamp(0.0, 100.0);

    // 2. Retention Score (based on revision performance 0..1 to 0..100)
    final double retentionScore =
        (revisionRetentionRate * 100.0).clamp(0.0, 100.0);

    // 3. Assessment Readiness Score (0..100)
    final double assessmentReadinessScore =
        averageAssessmentScore.clamp(0.0, 100.0);

    // 4. Activity Pace Score
    final double activityPaceScore =
        (progress.weeklyVelocityMinutes > 0 ? 85.0 : 40.0).clamp(0.0, 100.0);

    // Weighted Overall Score
    final double overallScore = (consistencyScore * 0.25) +
        (retentionScore * 0.25) +
        (assessmentReadinessScore * 0.35) +
        (activityPaceScore * 0.15);

    HealthLevel level;
    if (overallScore >= 90.0) {
      level = HealthLevel.excellent;
    } else if (overallScore >= 75.0) {
      level = HealthLevel.good;
    } else if (overallScore >= 60.0) {
      level = HealthLevel.moderate;
    } else if (overallScore >= 40.0) {
      level = HealthLevel.atRisk;
    } else {
      level = HealthLevel.critical;
    }

    final healthFactors = <String>[];
    if (consistencyScore > 75.0) {
      healthFactors.add('High study streak & consistency');
    }
    if (retentionScore > 75.0) {
      healthFactors.add('Strong memory retention');
    }
    if (assessmentReadinessScore < 60.0) {
      healthFactors.add('Assessment scores need boost');
    }
    if (activityPaceScore > 70.0) {
      healthFactors.add('Pace is on track with target budget');
    }

    return JourneyHealth(
      journeyId: journeyId,
      score: double.parse(overallScore.toStringAsFixed(1)),
      level: level,
      consistencyScore: double.parse(consistencyScore.toStringAsFixed(1)),
      retentionScore: double.parse(retentionScore.toStringAsFixed(1)),
      assessmentReadinessScore:
          double.parse(assessmentReadinessScore.toStringAsFixed(1)),
      activityPaceScore: double.parse(activityPaceScore.toStringAsFixed(1)),
      healthFactors: healthFactors,
    );
  }

  /// 5. Readiness Forecasting
  JourneyForecast calculateForecast({
    required String journeyId,
    required JourneyConfiguration config,
    required JourneyProgress progress,
    required JourneyHealth health,
  }) {
    final now = DateTime.now();
    final daysRemaining = config.targetExamDate.difference(now).inDays;

    final double completionFraction = progress.overallProgress;
    final double readinessProb = ((completionFraction * 0.50) +
            (health.score / 100.0 * 0.35) +
            (health.assessmentReadinessScore / 100.0 * 0.15))
        .clamp(0.0, 1.0);

    final double projectedScore = (readinessProb * 100.0).clamp(0.0, 100.0);

    final double velocityTrend = progress.weeklyVelocityMinutes > 0
        ? (progress.weeklyVelocityMinutes / (config.dailyTimeBudgetMinutes * 7))
            .clamp(0.1, 2.0)
        : 1.0;

    final int additionalDaysNeeded = daysRemaining > 0
        ? ((1.0 - completionFraction) *
                60 /
                (velocityTrend > 0 ? velocityTrend : 1.0))
            .round()
        : 0;

    final predictedDate = now.add(Duration(days: additionalDaysNeeded));

    String summary;
    if (readinessProb >= 0.80) {
      summary =
          'High readiness probability for ${config.targetExam}. Keep current pace!';
    } else if (readinessProb >= 0.60) {
      summary =
          'On track for ${config.targetExam}. Increase quiz practice for optimal readiness.';
    } else {
      summary =
          'Readiness score is lagging. Increase daily study hours to hit goal.';
    }

    return JourneyForecast(
      journeyId: journeyId,
      predictedCompletionDate: predictedDate,
      examReadinessProbability: double.parse(readinessProb.toStringAsFixed(2)),
      projectedFinalScore: double.parse(projectedScore.toStringAsFixed(1)),
      velocityTrend: double.parse(velocityTrend.toStringAsFixed(2)),
      forecastSummary: summary,
      generatedAt: now,
    );
  }

  /// 6. Achievement Generation
  List<JourneyAchievement> evaluateAchievements({
    required int completedMilestonesCount,
    required int completedTasksCount,
    required int streakDays,
    required int checkpointsPassed,
    required double healthScore,
  }) {
    final achievements = <JourneyAchievement>[
      JourneyAchievement(
        id: 'ach_first_step',
        title: 'First Step',
        description: 'Complete your first learning task',
        iconAsset: 'assets/achievements/first_step.png',
        rarity: AchievementRarity.common,
        isUnlocked: completedTasksCount >= 1,
        unlockedAt: completedTasksCount >= 1 ? DateTime.now() : null,
      ),
      JourneyAchievement(
        id: 'ach_milestone_master',
        title: 'Milestone Master',
        description: 'Complete 5 journey milestones',
        iconAsset: 'assets/achievements/milestone_master.png',
        rarity: AchievementRarity.uncommon,
        isUnlocked: completedMilestonesCount >= 5,
        unlockedAt: completedMilestonesCount >= 5 ? DateTime.now() : null,
      ),
      JourneyAchievement(
        id: 'ach_consistency_champion',
        title: 'Consistency Champion',
        description: 'Maintain a 7-day study streak',
        iconAsset: 'assets/achievements/streak_champion.png',
        rarity: AchievementRarity.rare,
        isUnlocked: streakDays >= 7,
        unlockedAt: streakDays >= 7 ? DateTime.now() : null,
      ),
      JourneyAchievement(
        id: 'ach_checkpoint_conqueror',
        title: 'Checkpoint Conqueror',
        description: 'Pass your first stage gate checkpoint',
        iconAsset: 'assets/achievements/checkpoint_conqueror.png',
        rarity: AchievementRarity.epic,
        isUnlocked: checkpointsPassed >= 1,
        unlockedAt: checkpointsPassed >= 1 ? DateTime.now() : null,
      ),
      JourneyAchievement(
        id: 'ach_mastery_legend',
        title: 'Mastery Legend',
        description: 'Achieve a Journey Health score of 90+',
        iconAsset: 'assets/achievements/mastery_legend.png',
        rarity: AchievementRarity.legendary,
        isUnlocked: healthScore >= 90.0,
        unlockedAt: healthScore >= 90.0 ? DateTime.now() : null,
      ),
    ];

    return achievements;
  }

  /// 7. Checkpoint Evaluation
  JourneyStage evaluateCheckpoint({
    required JourneyStage stage,
    required double testScore,
  }) {
    if (stage.checkpoint == null) return stage;

    final checkpoint = stage.checkpoint!;
    final bool passed = testScore >= checkpoint.requiredScore;

    final updatedCheckpoint = checkpoint.copyWith(
      achievedScore: testScore,
      status: passed ? CheckpointStatus.passed : CheckpointStatus.failed,
      evaluatedAt: DateTime.now(),
    );

    final stageStatus =
        passed ? JourneyStageStatus.completed : JourneyStageStatus.inProgress;

    return stage.copyWith(
      status: stageStatus,
      progress: passed ? 1.0 : stage.progress,
      checkpoint: updatedCheckpoint,
    );
  }

  /// 8. Progress Calculation
  JourneyProgress calculateProgress({
    required String journeyId,
    required List<JourneyStage> stages,
    required int streakDays,
    required double weeklyVelocityMinutes,
  }) {
    int totalMilestones = 0;
    int completedMilestones = 0;
    int totalTasks = 0;
    int completedTasks = 0;

    for (final stage in stages) {
      for (final milestone in stage.milestones) {
        totalMilestones++;
        if (milestone.status == MilestoneStatus.achieved) {
          completedMilestones++;
        }
        for (final task in milestone.tasks) {
          totalTasks++;
          if (task.status == TaskStatus.completed) {
            completedTasks++;
          }
        }
      }
    }

    final double overallProgress = totalMilestones == 0
        ? 0.0
        : (completedMilestones / totalMilestones).clamp(0.0, 1.0);

    return JourneyProgress(
      journeyId: journeyId,
      overallProgress: double.parse(overallProgress.toStringAsFixed(2)),
      completedMilestonesCount: completedMilestones,
      totalMilestonesCount: totalMilestones,
      completedTasksCount: completedTasks,
      totalTasksCount: totalTasks,
      weeklyVelocityMinutes: weeklyVelocityMinutes,
      streakDays: streakDays,
      lastActiveAt: DateTime.now(),
    );
  }

  /// 9. Long-term Planning & Adaptive Rescheduling
  List<JourneyStage> rescheduleJourneyStages({
    required List<JourneyStage> stages,
    required double velocityFactor, // >1.0 faster, <1.0 slower
  }) {
    return stages.map((stage) {
      final updatedMilestones = stage.milestones.map((m) {
        final remainingDays = m.targetDate.difference(DateTime.now()).inDays;
        final adjustedDays =
            (remainingDays / (velocityFactor > 0 ? velocityFactor : 1.0))
                .round();
        return m.copyWith(
          targetDate: DateTime.now()
              .add(Duration(days: adjustedDays > 0 ? adjustedDays : 1)),
        );
      }).toList();
      return stage.copyWith(milestones: updatedMilestones);
    }).toList();
  }

  /// 10. Learning Timeline Generation
  JourneyTimeline generateTimeline({
    required LearningJourney journey,
  }) {
    final events = <JourneyTimelineEvent>[];

    events.add(JourneyTimelineEvent(
      id: 'evt_created',
      title: 'Journey Started',
      description:
          'Learner journey initialized for ${journey.config.targetExam}',
      category: 'journey',
      timestamp: journey.createdAt,
    ));

    for (final stage in journey.stages) {
      for (final milestone in stage.milestones) {
        if (milestone.status == MilestoneStatus.achieved &&
            milestone.achievedAt != null) {
          events.add(JourneyTimelineEvent(
            id: 'evt_ms_${milestone.id}',
            title: 'Milestone Achieved: ${milestone.title}',
            description: milestone.description,
            category: 'milestone',
            timestamp: milestone.achievedAt!,
          ));
        }
      }

      if (stage.checkpoint != null &&
          stage.checkpoint!.status == CheckpointStatus.passed &&
          stage.checkpoint!.evaluatedAt != null) {
        events.add(JourneyTimelineEvent(
          id: 'evt_chk_${stage.checkpoint!.id}',
          title: 'Checkpoint Passed: ${stage.checkpoint!.title}',
          description: 'Achieved score ${stage.checkpoint!.achievedScore}%',
          category: 'checkpoint',
          timestamp: stage.checkpoint!.evaluatedAt!,
        ));
      }
    }

    for (final ach in journey.achievements) {
      if (ach.isUnlocked && ach.unlockedAt != null) {
        events.add(JourneyTimelineEvent(
          id: 'evt_ach_${ach.id}',
          title: 'Achievement Unlocked: ${ach.title}',
          description: ach.description,
          category: 'achievement',
          timestamp: ach.unlockedAt!,
        ));
      }
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return JourneyTimeline(
      journeyId: journey.id,
      events: events,
    );
  }
}
