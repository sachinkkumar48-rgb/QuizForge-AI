import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Achievement Tests', () {
    late LearningJourneyEngine engine;

    setUp(() {
      engine = const LearningJourneyEngine();
    });

    test(
        'evaluateAchievements unlocks First Step and Consistency Champion when conditions met',
        () {
      final achievements = engine.evaluateAchievements(
        completedMilestonesCount: 2,
        completedTasksCount: 3,
        streakDays: 7,
        checkpointsPassed: 1,
        healthScore: 92.0,
      );

      final firstStep =
          achievements.firstWhere((a) => a.id == 'ach_first_step');
      final streakChamp =
          achievements.firstWhere((a) => a.id == 'ach_consistency_champion');
      final legend =
          achievements.firstWhere((a) => a.id == 'ach_mastery_legend');

      expect(firstStep.isUnlocked, isTrue);
      expect(streakChamp.isUnlocked, isTrue);
      expect(legend.isUnlocked, isTrue);
    });
  });
}
