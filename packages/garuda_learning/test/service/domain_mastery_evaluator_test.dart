import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_mastery_distribution.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/curriculum_domain.dart';
import 'package:garuda_learning/domain/entities/curriculum_unit.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/service/domain_mastery_evaluator.dart';

void main() {
  group('DomainMasteryEvaluator Service Tests (P23 Stage 3)', () {
    const evaluator = DomainMasteryEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);

    final domain = CurriculumDomain(
      id: 'pol_domain_fr',
      title: 'Fundamental Rights',
      description: 'Constitutional Fundamental Rights scope',
      provenance: 'test_p17',
      units: [
        CurriculumUnit(
          id: 'unit_fr_core',
          domainId: 'pol_domain_fr',
          title: 'Core Rights',
          description: 'Core fundamental rights articles',
          provenance: 'test_p17',
        ),
      ],
    );

    final objectives = [
      LearningObjective(
        id: 'lo_fr_art14',
        unitId: 'unit_fr_core',
        title: 'Equality before Law',
        description: 'Article 14 scope and nuances',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_fr_art19',
        unitId: 'unit_fr_core',
        title: 'Six Freedoms',
        description: 'Article 19 freedoms and reasonable restrictions',
        bloomLevel: BloomTaxonomyLevel.apply,
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_fr_art21',
        unitId: 'unit_fr_core',
        title: 'Right to Life',
        description: 'Article 21 procedure established by law vs due process',
        bloomLevel: BloomTaxonomyLevel.analyze,
        provenance: 'test_p17',
      ),
    ];

    test('1. Fully evaluated domain with sufficient evidence', () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_fr_art14',
          attemptCount: 6,
          correctCount: 5,
          successRate: 5 / 6,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_fr_art19',
          attemptCount: 4,
          correctCount: 3,
          successRate: 3 / 4,
          status: LearnerObjectiveStatus.inProgress,
        ),
      ];

      final profile = evaluator.evaluateFromDomain(
        learnerId: 'learner_001',
        domain: domain,
        allObjectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.domainId, equals('pol_domain_fr'));
      expect(profile.learnerId, equals('learner_001'));
      expect(profile.totalObjectivesCount, equals(3));
      expect(profile.attemptedObjectivesCount, equals(2));
      expect(profile.achievedObjectivesCount, equals(1));
      expect(profile.totalAttemptsCount, equals(10)); // 6 + 4
      expect(profile.totalCorrectCount, equals(8)); // 5 + 3
      expect(profile.observedAccuracy, closeTo(0.80, 0.001));
      expect(profile.observedMasteryScore, closeTo(0.80, 0.001));
      expect(profile.hasSufficientEvidence, isTrue);
      expect(profile.calculatedAt, equals(fixedTime));
      expect(profile.supportingObjectiveIds.length, equals(3));
      expect(profile.supportingObjectiveIds,
          equals(['lo_fr_art14', 'lo_fr_art19', 'lo_fr_art21']));
    });

    test(
        '2. Zero attempts by learner produces null metrics and insufficient evidence',
        () {
      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_fr',
        objectiveIds: ['lo_fr_art14', 'lo_fr_art19', 'lo_fr_art21'],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.totalObjectivesCount, equals(3));
      expect(profile.attemptedObjectivesCount, equals(0));
      expect(profile.achievedObjectivesCount, equals(0));
      expect(profile.totalAttemptsCount, equals(0));
      expect(profile.totalCorrectCount, equals(0));
      expect(profile.observedAccuracy, isNull);
      expect(profile.observedMasteryScore, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
    });

    test(
        '3. Sparse attempts below threshold yields observed accuracy but null mastery score',
        () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_fr_art14',
          attemptCount: 2, // below threshold 5
          correctCount: 2,
          successRate: 1.0,
          status: LearnerObjectiveStatus.inProgress,
        ),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_fr',
        objectiveIds: ['lo_fr_art14'],
        progressList: progressList,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalAttemptsCount, equals(2));
      expect(profile.observedAccuracy, equals(1.0));
      expect(profile.observedMasteryScore, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
    });

    test('4. Empty domain objectives handled safely', () {
      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_empty',
        objectiveIds: const [],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.totalObjectivesCount, equals(0));
      expect(profile.attemptedObjectivesCount, equals(0));
      expect(profile.observedAccuracy, isNull);
      expect(profile.observedMasteryScore, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.coverageRatio, equals(0.0));
      expect(profile.achievementRatio, equals(0.0));
    });

    test(
        '5. Argument validations: empty learnerId, empty domainId, invalid threshold',
        () {
      expect(
        () => evaluator.evaluate(
          learnerId: '',
          domainId: 'pol_domain_fr',
          objectiveIds: const ['lo_1'],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: 'l_1',
          domainId: '',
          objectiveIds: const ['lo_1'],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: 'l_1',
          domainId: 'd_1',
          objectiveIds: const ['lo_1'],
          progressList: const [],
          minimumEvidenceThreshold: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '6. Deterministic evaluation contract: identical inputs produce identical profiles',
        () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_fr_art14',
          attemptCount: 6,
          correctCount: 5,
          successRate: 5 / 6,
          status: LearnerObjectiveStatus.achieved,
        ),
      ];

      final profile1 = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_fr',
        objectiveIds: const ['lo_fr_art19', 'lo_fr_art14'], // unsorted
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      final profile2 = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_fr',
        objectiveIds: const ['lo_fr_art14', 'lo_fr_art19'], // sorted
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
      expect(profile1.supportingObjectiveIds,
          equals(['lo_fr_art14', 'lo_fr_art19']));
    });

    test('7. Bloom distribution integration and multi-learner isolation', () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_fr_art14',
          attemptCount: 6,
          correctCount: 6,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_999', // other learner, must be ignored
          objectiveId: 'lo_fr_art19',
          attemptCount: 20,
          correctCount: 20,
          status: LearnerObjectiveStatus.achieved,
        ),
      ];

      final bloomDist = BloomMasteryDistribution(
        learnerId: 'learner_001',
        scopeId: 'pol_domain_fr',
        levels: {
          BloomTaxonomyLevel.understand: BloomLevelMetric(
            level: BloomTaxonomyLevel.understand,
            totalObjectivesCount: 1,
            attemptedObjectivesCount: 1,
            achievedObjectivesCount: 1,
            totalAttemptsCount: 6,
            totalCorrectCount: 6,
          ),
        },
        calculatedAt: fixedTime,
      );

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        domainId: 'pol_domain_fr',
        objectiveIds: ['lo_fr_art14', 'lo_fr_art19'],
        progressList: progressList,
        bloomDistribution: bloomDist,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalAttemptsCount, equals(6));
      expect(profile.totalCorrectCount, equals(6));
      expect(profile.attemptedObjectivesCount, equals(1));
      expect(profile.achievedObjectivesCount, equals(1));
      expect(profile.bloomDistribution, equals(bloomDist));
    });
  });
}
