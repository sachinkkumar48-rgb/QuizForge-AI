import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Roadmap Tests', () {
    late LearningJourneyEngine engine;

    setUp(() {
      engine = const LearningJourneyEngine();
    });

    test(
        'evaluateCheckpoint passes checkpoint and completes stage when score exceeds requirement',
        () {
      final config = JourneyConfiguration(
        journeyId: 'j_rm_1',
        targetExam: 'UPSC CSE 2026',
        targetExamDate: DateTime.now().add(const Duration(days: 90)),
        dailyTimeBudgetMinutes: 90,
        targetConfidenceScore: 0.80,
      );

      final journey = engine.generateRoadmap(learnerId: 'u1', config: config);
      final stage1 = journey.stages.first;

      final updatedStage1 = engine.evaluateCheckpoint(
        stage: stage1,
        testScore: 85.0,
      );

      expect(updatedStage1.status, equals(JourneyStageStatus.completed));
      expect(updatedStage1.checkpoint!.status, equals(CheckpointStatus.passed));
      expect(updatedStage1.checkpoint!.achievedScore, equals(85.0));
    });
  });
}
