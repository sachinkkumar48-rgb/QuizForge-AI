import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Repository Tests', () {
    late LearningJourneyRepository repository;
    late LearningJourneyEngine engine;

    setUp(() {
      repository = LearningJourneyRepositoryImpl();
      engine = const LearningJourneyEngine();
    });

    test('Save and retrieve learning journey', () async {
      final config = JourneyConfiguration(
        journeyId: 'j_repo_1',
        targetExam: 'UPSC CSE',
        targetExamDate: DateTime.now().add(const Duration(days: 90)),
        dailyTimeBudgetMinutes: 90,
        targetConfidenceScore: 0.80,
      );

      final journey =
          engine.generateRoadmap(learnerId: 'user_1', config: config);
      await repository.saveJourney(journey);

      final retrieved = await repository.getJourney('user_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.learnerId, equals('user_1'));
      expect(retrieved.stages.length, equals(4));
    });

    test('Cache and sync pending changes', () async {
      final config = JourneyConfiguration(
        journeyId: 'j_repo_2',
        targetExam: 'UPSC CSE',
        targetExamDate: DateTime.now().add(const Duration(days: 90)),
        dailyTimeBudgetMinutes: 90,
        targetConfidenceScore: 0.80,
      );

      final journey =
          engine.generateRoadmap(learnerId: 'user_2', config: config);
      await repository.cacheJourney(journey);

      final cached = await repository.getCachedJourney('user_2');
      expect(cached, isNotNull);
      expect(cached!.learnerId, equals('user_2'));

      final synced = await repository.syncPendingChanges('user_2');
      expect(synced, isTrue);
    });
  });
}
