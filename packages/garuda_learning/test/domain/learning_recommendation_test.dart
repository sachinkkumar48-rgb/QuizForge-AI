import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('LearningRecommendation Domain Entity Tests', () {
    final sampleConfig = SessionConfiguration(
      learnerId: 'learner_1',
      objectiveIds: const ['lo_basic_structure_doctrine'],
      questionLimit: 10,
      selectionPolicy: QuestionSelectionPolicy.allObjectiveQuestions,
      sequencerPolicy: QuestionSequencerPolicy.curriculumOrder,
    );

    test('instantiates valid recommendation with clamped priority score', () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final rec = LearningRecommendation(
        recommendationId: 'rec_101',
        learnerId: 'learner_1',
        objectiveId: 'lo_basic_structure_doctrine',
        type: RecommendationType.spacedReview,
        priorityScore: 1.45, // Should clamp to 1.0
        rationale: 'Review overdue by 48 hours.',
        suggestedConfig: sampleConfig,
        generatedAt: now,
        metadata: const {'overdueHours': 48.0},
      );

      expect(rec.recommendationId, equals('rec_101'));
      expect(rec.priorityScore, equals(1.0));
      expect(rec.type, equals(RecommendationType.spacedReview));
      expect(rec.rationale, equals('Review overdue by 48 hours.'));
      expect(rec.generatedAt, equals(now));
      expect(rec.metadata['overdueHours'], equals(48.0));
    });

    test('throws ArgumentError on blank required fields', () {
      expect(
        () => LearningRecommendation(
          recommendationId: '',
          learnerId: 'learner_1',
          objectiveId: 'lo_1',
          type: RecommendationType.curriculumAdvance,
          priorityScore: 0.5,
          rationale: 'test',
          suggestedConfig: sampleConfig,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningRecommendation(
          recommendationId: 'rec_1',
          learnerId: '  ',
          objectiveId: 'lo_1',
          type: RecommendationType.curriculumAdvance,
          priorityScore: 0.5,
          rationale: 'test',
          suggestedConfig: sampleConfig,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningRecommendation(
          recommendationId: 'rec_1',
          learnerId: 'learner_1',
          objectiveId: '',
          type: RecommendationType.curriculumAdvance,
          priorityScore: 0.5,
          rationale: 'test',
          suggestedConfig: sampleConfig,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningRecommendation(
          recommendationId: 'rec_1',
          learnerId: 'learner_1',
          objectiveId: 'lo_1',
          type: RecommendationType.curriculumAdvance,
          priorityScore: 0.5,
          rationale: '   ',
          suggestedConfig: sampleConfig,
        ),
        throwsArgumentError,
      );
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final now = DateTime.utc(2026, 8, 16, 10, 30, 0);
      final rec = LearningRecommendation(
        recommendationId: 'rec_202',
        learnerId: 'learner_2',
        objectiveId: 'lo_article_21_foundations',
        type: RecommendationType.weakDomainRemediation,
        priorityScore: 0.725,
        rationale: 'Domain accuracy is 42.0% across 6 attempts.',
        suggestedConfig: sampleConfig,
        generatedAt: now,
        metadata: const {'domainAccuracy': 0.42},
      );

      final json = rec.toJson();
      final restored = LearningRecommendation.fromJson(json);

      expect(restored, equals(rec));
      expect(restored.type, equals(RecommendationType.weakDomainRemediation));
      expect(restored.priorityScore, closeTo(0.725, 0.0001));
    });

    test('RecommendationType displayNames are well-formed', () {
      for (final type in RecommendationType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
      }
    });
  });
}
