import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Use Cases Tests', () {
    late LearningJourneyRepository repository;
    late LearningJourneyEngine engine;
    late EcosystemJourneyIntegrator integrator;

    setUp(() {
      repository = LearningJourneyRepositoryImpl();
      engine = const LearningJourneyEngine();
      integrator = const EcosystemJourneyIntegrator();
    });

    test('GenerateJourneyUseCase generates and persists new journey', () async {
      final useCase = GenerateJourneyUseCase(
        repository: repository,
        engine: engine,
        integrator: integrator,
      );

      final config = JourneyConfiguration(
        journeyId: 'j_uc_1',
        targetExam: 'UPSC CSE',
        targetExamDate: DateTime.now().add(const Duration(days: 120)),
        dailyTimeBudgetMinutes: 90,
        targetConfidenceScore: 0.85,
      );

      final journey = await useCase.execute(
        learnerId: 'learner_uc',
        config: config,
      );

      expect(journey.learnerId, equals('learner_uc'));
      final saved = await repository.getJourney('learner_uc');
      expect(saved, isNotNull);
    });

    test('UpdateJourneyProgressUseCase completes task and updates progress',
        () async {
      final genUseCase = GenerateJourneyUseCase(
        repository: repository,
        engine: engine,
        integrator: integrator,
      );
      final updateUseCase = UpdateJourneyProgressUseCase(
        repository: repository,
        engine: engine,
      );

      final config = JourneyConfiguration(
        journeyId: 'j_uc_2',
        targetExam: 'UPSC CSE',
        targetExamDate: DateTime.now().add(const Duration(days: 120)),
        dailyTimeBudgetMinutes: 90,
        targetConfidenceScore: 0.85,
      );

      await genUseCase.execute(
        learnerId: 'learner_uc2',
        config: config,
      );

      final updated = await updateUseCase.execute(
        learnerId: 'learner_uc2',
        taskId: 'task_s1_t1',
        newStatus: TaskStatus.completed,
      );

      expect(updated.progress.completedTasksCount, equals(1));
    });
  });
}
