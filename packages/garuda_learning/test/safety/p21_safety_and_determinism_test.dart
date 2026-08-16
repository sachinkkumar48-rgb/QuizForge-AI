import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P21 Safety & Determinism Verification Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryProgressRepository progressRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryReviewScheduleRepository reviewScheduleRepo;
    late SpacedRepetitionService spacedRepetitionService;
    late AdaptiveRecommendationService service;

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      progressRepo = InMemoryProgressRepository();
      attemptRepo = InMemoryAttemptRepository();
      reviewScheduleRepo = InMemoryReviewScheduleRepository();
      spacedRepetitionService =
          SpacedRepetitionService(repository: reviewScheduleRepo);

      service = AdaptiveRecommendationService(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        spacedRepetitionService: spacedRepetitionService,
      );
    });

    test('deterministic ranking produces identical output across multiple runs',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'determ_learner';

      final queue1 = await service.generateRecommendations(
        learnerId: learnerId,
        asOfDate: asOf,
      );

      final queue2 = await service.generateRecommendations(
        learnerId: learnerId,
        asOfDate: asOf,
      );

      expect(queue1.length, equals(queue2.length));
      for (int i = 0; i < queue1.length; i++) {
        expect(
            queue1.items[i].objectiveId, equals(queue2.items[i].objectiveId));
        expect(queue1.items[i].priorityScore,
            equals(queue2.items[i].priorityScore));
        expect(queue1.items[i].type, equals(queue2.items[i].type));
        expect(queue1.items[i].rationale, equals(queue2.items[i].rationale));
      }
    });

    test(
        'all factors and final composite scores are strictly bounded in [0.0, 1.0]',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'clamping_learner';

      final queue = await service.generateRecommendations(
        learnerId: learnerId,
        asOfDate: asOf,
      );

      for (final rec in queue.items) {
        expect(rec.priorityScore >= 0.0 && rec.priorityScore <= 1.0, isTrue);
        final meta = rec.metadata;
        expect(
            (meta['uReview'] as double) >= 0.0 &&
                (meta['uReview'] as double) <= 1.0,
            isTrue);
        expect(
            (meta['sPrereq'] as double) >= 0.0 &&
                (meta['sPrereq'] as double) <= 1.0,
            isTrue);
        expect(
            (meta['gWeak'] as double) >= 0.0 &&
                (meta['gWeak'] as double) <= 1.0,
            isTrue);
        expect(
            (meta['pCurric'] as double) >= 0.0 &&
                (meta['pCurric'] as double) <= 1.0,
            isTrue);
        expect(
            (meta['hDensity'] as double) >= 0.0 &&
                (meta['hDensity'] as double) <= 1.0,
            isTrue);
      }
    });

    test(
        'educational safety: rationales contain NO unsupported mastery or guarantee claims',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'safety_learner';

      final queue = await service.generateRecommendations(
        learnerId: learnerId,
        asOfDate: asOf,
      );

      final bannedKeywords = [
        'mastered',
        'mastery',
        'expert',
        'expertise',
        'exam ready',
        'guaranteed',
        'upsc rank',
        'score improvement',
      ];

      for (final rec in queue.items) {
        final lower = rec.rationale.toLowerCase();
        for (final banned in bannedKeywords) {
          expect(
            lower.contains(banned),
            isFalse,
            reason:
                'Rationale "${rec.rationale}" should not contain forbidden keyword "$banned"',
          );
        }
      }
    });

    test('missing data safety: invalid objective lookup returns null safely',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final rec = await service.evaluateObjective(
        learnerId: 'test_learner',
        objectiveId: 'non_existent_objective_id',
        asOfDate: asOf,
      );

      expect(rec, isNull);
    });
  });
}
