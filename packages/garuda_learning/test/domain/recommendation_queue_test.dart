import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('RecommendationQueue Aggregate Root Tests', () {
    final sampleConfig = SessionConfiguration(
      learnerId: 'learner_1',
      objectiveIds: const ['lo_1'],
      questionLimit: 10,
    );

    test(
        'orders items deterministically by priorityScore descending and objectiveId tie-breaker',
        () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final itemA = LearningRecommendation(
        recommendationId: 'rec_a',
        learnerId: 'learner_1',
        objectiveId: 'lo_z_objective',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.80,
        rationale: 'Reason A',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final itemB = LearningRecommendation(
        recommendationId: 'rec_b',
        learnerId: 'learner_1',
        objectiveId: 'lo_a_objective',
        type: RecommendationType.spacedReview,
        priorityScore:
            0.80, // Same score as itemA, should sort first by objectiveId 'lo_a_objective' < 'lo_z_objective'
        rationale: 'Reason B',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final itemC = LearningRecommendation(
        recommendationId: 'rec_c',
        learnerId: 'learner_1',
        objectiveId: 'lo_top',
        type: RecommendationType.prerequisiteGap,
        priorityScore: 0.95, // Higher score, should be first
        rationale: 'Reason C',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final queue = RecommendationQueue(
        learnerId: 'learner_1',
        items: [itemA, itemB, itemC],
        generatedAt: now,
      );

      expect(queue.length, equals(3));
      expect(queue.items[0].recommendationId, equals('rec_c')); // score 0.95
      expect(queue.items[1].recommendationId,
          equals('rec_b')); // score 0.80, 'lo_a_objective'
      expect(queue.items[2].recommendationId,
          equals('rec_a')); // score 0.80, 'lo_z_objective'
      expect(queue.topRecommendation?.recommendationId, equals('rec_c'));
    });

    test('empty queue handles getters cleanly', () {
      final queue = RecommendationQueue(
        learnerId: 'learner_empty',
        items: const [],
      );

      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
      expect(queue.length, equals(0));
      expect(queue.topRecommendation, isNull);
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final item = LearningRecommendation(
        recommendationId: 'rec_1',
        learnerId: 'learner_1',
        objectiveId: 'lo_basic_structure_doctrine',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.85,
        rationale: 'Curriculum next',
        suggestedConfig: sampleConfig,
        generatedAt: now,
      );

      final queue = RecommendationQueue(
        learnerId: 'learner_1',
        items: [item],
        generatedAt: now,
      );

      final json = queue.toJson();
      final restored = RecommendationQueue.fromJson(json);

      expect(restored, equals(queue));
      expect(restored.length, equals(1));
    });
  });
}
