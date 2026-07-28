import '../engine/learning_journey_engine.dart';
import '../integration/ecosystem_journey_integrator.dart';
import '../models/journey_models.dart';
import '../repository/learning_journey_repository.dart';

/// 1. GenerateJourneyUseCase
class GenerateJourneyUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;
  final EcosystemJourneyIntegrator integrator;

  const GenerateJourneyUseCase({
    required this.repository,
    required this.engine,
    required this.integrator,
  });

  Future<LearningJourney> execute({
    required String learnerId,
    required JourneyConfiguration config,
  }) async {
    final journey = engine.generateRoadmap(
      learnerId: learnerId,
      config: config,
    );

    await repository.saveJourney(journey);
    await integrator.syncMilestonesToPlanner(
      learnerId: learnerId,
      milestones: journey.stages.expand((s) => s.milestones).toList(),
    );

    return journey;
  }
}

/// 2. UpdateJourneyProgressUseCase
class UpdateJourneyProgressUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const UpdateJourneyProgressUseCase({
    required this.repository,
    required this.engine,
  });

  Future<LearningJourney> execute({
    required String learnerId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) {
      throw StateError('Journey not found for learner: $learnerId');
    }

    final updatedStages = journey.stages.map((stage) {
      final updatedMilestones = stage.milestones.map((milestone) {
        final taskIndex = milestone.tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex >= 0) {
          final updatedTasks = List<JourneyTask>.from(milestone.tasks);
          updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(
            status: newStatus,
            completedAt:
                newStatus == TaskStatus.completed ? DateTime.now() : null,
          );
          return engine.updateMilestoneProgress(
            milestone: milestone,
            updatedTasks: updatedTasks,
          );
        }
        return milestone;
      }).toList();

      return stage.copyWith(milestones: updatedMilestones);
    }).toList();

    final updatedProgress = engine.calculateProgress(
      journeyId: journey.id,
      stages: updatedStages,
      streakDays: journey.progress.streakDays,
      weeklyVelocityMinutes: journey.progress.weeklyVelocityMinutes + 30.0,
    );

    final updatedHealth = engine.calculateHealth(
      journeyId: journey.id,
      progress: updatedProgress,
      averageAssessmentScore: journey.health.assessmentReadinessScore,
      revisionRetentionRate: journey.health.retentionScore / 100.0,
    );

    final updatedForecast = engine.calculateForecast(
      journeyId: journey.id,
      config: journey.config,
      progress: updatedProgress,
      health: updatedHealth,
    );

    final updatedAchievements = engine.evaluateAchievements(
      completedMilestonesCount: updatedProgress.completedMilestonesCount,
      completedTasksCount: updatedProgress.completedTasksCount,
      streakDays: updatedProgress.streakDays,
      checkpointsPassed: updatedStages
          .where((s) => s.checkpoint?.status == CheckpointStatus.passed)
          .length,
      healthScore: updatedHealth.score,
    );

    final updatedJourney = journey.copyWith(
      stages: updatedStages,
      progress: updatedProgress,
      health: updatedHealth,
      forecast: updatedForecast,
      achievements: updatedAchievements,
      updatedAt: DateTime.now(),
    );

    await repository.saveJourney(updatedJourney);

    await repository.saveSnapshot(JourneySnapshot(
      id: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      journeyId: journey.id,
      progress: updatedProgress,
      health: updatedHealth,
      forecast: updatedForecast,
      capturedAt: DateTime.now(),
    ));

    return updatedJourney;
  }
}

/// 3. EvaluateCheckpointUseCase
class EvaluateCheckpointUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const EvaluateCheckpointUseCase({
    required this.repository,
    required this.engine,
  });

  Future<LearningJourney> execute({
    required String learnerId,
    required String stageId,
    required double testScore,
  }) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) {
      throw StateError('Journey not found for learner: $learnerId');
    }

    final updatedStages = journey.stages.map((stage) {
      if (stage.id == stageId) {
        return engine.evaluateCheckpoint(stage: stage, testScore: testScore);
      }
      return stage;
    }).toList();

    // Unlock next stage if current stage was completed
    for (int i = 0; i < updatedStages.length - 1; i++) {
      if (updatedStages[i].status == JourneyStageStatus.completed &&
          updatedStages[i + 1].status == JourneyStageStatus.locked) {
        updatedStages[i + 1] = updatedStages[i + 1].copyWith(
          status: JourneyStageStatus.inProgress,
        );
      }
    }

    final updatedProgress = engine.calculateProgress(
      journeyId: journey.id,
      stages: updatedStages,
      streakDays: journey.progress.streakDays,
      weeklyVelocityMinutes: journey.progress.weeklyVelocityMinutes,
    );

    final updatedHealth = engine.calculateHealth(
      journeyId: journey.id,
      progress: updatedProgress,
      averageAssessmentScore: testScore,
      revisionRetentionRate: journey.health.retentionScore / 100.0,
    );

    final updatedForecast = engine.calculateForecast(
      journeyId: journey.id,
      config: journey.config,
      progress: updatedProgress,
      health: updatedHealth,
    );

    final updatedJourney = journey.copyWith(
      stages: updatedStages,
      progress: updatedProgress,
      health: updatedHealth,
      forecast: updatedForecast,
      updatedAt: DateTime.now(),
    );

    await repository.saveJourney(updatedJourney);
    return updatedJourney;
  }
}

/// 4. GenerateMilestonesUseCase
class GenerateMilestonesUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const GenerateMilestonesUseCase({
    required this.repository,
    required this.engine,
  });

  Future<List<JourneyMilestone>> execute({
    required String learnerId,
    required String stageId,
    required List<String> topicNames,
  }) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) return const [];

    final milestones = topicNames.map((topic) {
      final id = 'ms_${stageId}_${topic.toLowerCase().replaceAll(' ', '_')}';
      return JourneyMilestone(
        id: id,
        stageId: stageId,
        title: 'Mastery of $topic',
        description:
            'Complete syllabus readings, flashcards, and quizzes for $topic',
        targetDate: DateTime.now().add(const Duration(days: 14)),
        status: MilestoneStatus.pending,
        tasks: [
          JourneyTask(
            id: 'task_${id}_quiz',
            title: '$topic Concept Quiz',
            description: 'Topic assessment quiz',
            moduleSource: 'titan_smart_assessment',
            resourceId: 'quiz_$id',
            estimatedMinutes: 30,
          ),
        ],
      );
    }).toList();

    for (final ms in milestones) {
      await repository.saveMilestone(journey.id, ms);
    }

    return milestones;
  }
}

/// 5. ForecastReadinessUseCase
class ForecastReadinessUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const ForecastReadinessUseCase({
    required this.repository,
    required this.engine,
  });

  Future<JourneyForecast> execute({required String learnerId}) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) {
      throw StateError('Journey not found for learner: $learnerId');
    }

    final forecast = engine.calculateForecast(
      journeyId: journey.id,
      config: journey.config,
      progress: journey.progress,
      health: journey.health,
    );

    await repository.saveForecast(forecast);
    return forecast;
  }
}

/// 6. GenerateAchievementsUseCase
class GenerateAchievementsUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const GenerateAchievementsUseCase({
    required this.repository,
    required this.engine,
  });

  Future<List<JourneyAchievement>> execute({required String learnerId}) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) return const [];

    final checkpointsPassed = journey.stages
        .where((s) => s.checkpoint?.status == CheckpointStatus.passed)
        .length;

    final achievements = engine.evaluateAchievements(
      completedMilestonesCount: journey.progress.completedMilestonesCount,
      completedTasksCount: journey.progress.completedTasksCount,
      streakDays: journey.progress.streakDays,
      checkpointsPassed: checkpointsPassed,
      healthScore: journey.health.score,
    );

    await repository.saveAchievements(journey.id, achievements);
    return achievements;
  }
}

/// 7. GetJourneyInsightsUseCase
class GetJourneyInsightsUseCase {
  final LearningJourneyRepository repository;

  const GetJourneyInsightsUseCase({required this.repository});

  Future<List<JourneyInsight>> execute({required String learnerId}) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) return const [];

    final insights = <JourneyInsight>[];
    final now = DateTime.now();

    if (journey.health.score >= 80.0) {
      insights.add(JourneyInsight(
        id: 'ins_01',
        type: InsightType.strength,
        title: 'Strong Learning Health',
        summary:
            'Your overall journey health is in top tier (${journey.health.score}%).',
        detail: 'Consistency and retention scores are high across all stages.',
        impactScore: 90.0,
        createdAt: now,
      ));
    } else {
      insights.add(JourneyInsight(
        id: 'ins_02',
        type: InsightType.bottleneck,
        title: 'Pace Acceleration Needed',
        summary:
            'Target exam date is approaching. Focus on completing open milestones.',
        detail:
            'Weekly study velocity needs a 15% increase to hit forecasted targets.',
        impactScore: 85.0,
        createdAt: now,
      ));
    }

    if (journey.forecast.examReadinessProbability >= 0.75) {
      insights.add(JourneyInsight(
        id: 'ins_03',
        type: InsightType.milestone,
        title: 'High Exam Readiness',
        summary:
            'Projected exam score is ${journey.forecast.projectedFinalScore}%.',
        detail:
            'Keep up scheduled mock test drills to maintain readiness peak.',
        impactScore: 95.0,
        createdAt: now,
      ));
    }

    return insights;
  }
}

/// 8. ContinueJourneyUseCase
class ContinueJourneyUseCase {
  final LearningJourneyRepository repository;
  final EcosystemJourneyIntegrator integrator;

  const ContinueJourneyUseCase({
    required this.repository,
    required this.integrator,
  });

  Future<JourneyTask?> execute({required String learnerId}) async {
    final journey = await repository.getJourney(learnerId);
    if (journey == null) return null;

    for (final stage in journey.stages) {
      if (stage.status == JourneyStageStatus.inProgress) {
        for (final milestone in stage.milestones) {
          for (final task in milestone.tasks) {
            if (task.status == TaskStatus.todo ||
                task.status == TaskStatus.inProgress) {
              return task;
            }
          }
        }
      }
    }
    return null;
  }
}

/// 9. ResetJourneyUseCase
class ResetJourneyUseCase {
  final LearningJourneyRepository repository;
  final LearningJourneyEngine engine;

  const ResetJourneyUseCase({
    required this.repository,
    required this.engine,
  });

  Future<LearningJourney> execute({
    required String learnerId,
    required JourneyConfiguration newConfig,
  }) async {
    final freshJourney = engine.generateRoadmap(
      learnerId: learnerId,
      config: newConfig,
    );

    await repository.saveJourney(freshJourney);
    return freshJourney;
  }
}
