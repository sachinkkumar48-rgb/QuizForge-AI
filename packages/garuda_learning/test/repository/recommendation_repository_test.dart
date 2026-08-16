import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('InMemoryRecommendationRepository Tests', () {
    late InMemoryRecommendationRepository repo;

    setUp(() {
      repo = InMemoryRecommendationRepository();
    });

    final sampleConfig = SessionConfiguration(
      learnerId: 'learner_1',
      objectiveIds: const ['lo_1'],
      questionLimit: 10,
    );

    test('saves, retrieves, filters, and clears queues', () async {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final rec1 = LearningRecommendation(
        recommendationId: 'rec_1',
        learnerId: 'learner_1',
        objectiveId: 'lo_1',
        type: RecommendationType.spacedReview,
        priorityScore: 0.90,
        rationale: 'Review due',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final rec2 = LearningRecommendation(
        recommendationId: 'rec_2',
        learnerId: 'learner_1',
        objectiveId: 'lo_2',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.70,
        rationale: 'Advance',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final queue = RecommendationQueue(
        learnerId: 'learner_1',
        items: [rec1, rec2],
        generatedAt: now,
      );

      await repo.saveQueue(queue);

      final retrieved = await repo.getQueue('learner_1');
      expect(retrieved, isNotNull);
      expect(retrieved?.length, equals(2));

      final allRecs = await repo.getRecommendationsForLearner('learner_1');
      expect(allRecs.length, equals(2));

      final spacedOnly = await repo.getRecommendationsForLearner(
        'learner_1',
        type: RecommendationType.spacedReview,
      );
      expect(spacedOnly.length, equals(1));
      expect(spacedOnly.first.recommendationId, equals('rec_1'));

      await repo.clearQueue('learner_1');
      final cleared = await repo.getQueue('learner_1');
      expect(cleared, isNull);
    });
  });
}
