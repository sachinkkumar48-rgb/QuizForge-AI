import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/curriculum_domain.dart';
import 'package:garuda_learning/domain/entities/curriculum_framework.dart';
import 'package:garuda_learning/domain/entities/curriculum_unit.dart';
import 'package:garuda_learning/domain/entities/curriculum_version.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/service/bloom_analytics_evaluator.dart';

void main() {
  group('BloomAnalyticsEvaluator Service Tests (P23 Stage 3)', () {
    const evaluator = BloomAnalyticsEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);

    final objectives = [
      LearningObjective(
        id: 'lo_rem_1',
        unitId: 'unit_1',
        title: 'Remember Article Numbers',
        description: 'Factual recall',
        bloomLevel: BloomTaxonomyLevel.remember,
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_und_1',
        unitId: 'unit_1',
        title: 'Understand Doctrine of Basic Structure',
        description: 'Conceptual comprehension',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_app_1',
        unitId: 'unit_1',
        title: 'Apply Writ Jurisdiction',
        description: 'Case analysis',
        bloomLevel: BloomTaxonomyLevel.apply,
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_ana_1',
        unitId: 'unit_1',
        title: 'Analyze Judicial Review Limitations',
        description: 'Comparative analysis',
        bloomLevel: BloomTaxonomyLevel.analyze,
        provenance: 'test_p17',
      ),
    ];

    test('1. Valid cognitive level distribution evaluation with mixed evidence',
        () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_rem_1',
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_und_1',
          attemptCount: 5,
          correctCount: 4,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_app_1',
          attemptCount: 5,
          correctCount: 2,
          status: LearnerObjectiveStatus.inProgress,
        ),
        // lo_ana_1 unattempted
      ];

      final distribution = evaluator.evaluate(
        learnerId: 'learner_001',
        scopeId: 'scope_gs2',
        objectives: objectives,
        progressList: progressList,
        minimumLevelEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(distribution.learnerId, equals('learner_001'));
      expect(distribution.scopeId, equals('scope_gs2'));
      expect(
          distribution.totalAttemptsAcrossAllLevels, equals(20)); // 10 + 5 + 5
      expect(distribution.totalCorrectAcrossAllLevels, equals(15)); // 9 + 4 + 2
      expect(distribution.overallAccuracy, closeTo(0.75, 0.001));

      // Remember level
      final rememberMetric = distribution.levels[BloomTaxonomyLevel.remember]!;
      expect(rememberMetric.totalObjectivesCount, equals(1));
      expect(rememberMetric.attemptedObjectivesCount, equals(1));
      expect(rememberMetric.achievedObjectivesCount, equals(1));
      expect(rememberMetric.totalAttemptsCount, equals(10));
      expect(rememberMetric.totalCorrectCount, equals(9));
      expect(rememberMetric.observedAccuracy, closeTo(0.90, 0.001));
      expect(rememberMetric.hasSufficientEvidence, isTrue);

      // Analyze level (unattempted)
      final analyzeMetric = distribution.levels[BloomTaxonomyLevel.analyze]!;
      expect(analyzeMetric.totalObjectivesCount, equals(1));
      expect(analyzeMetric.attemptedObjectivesCount, equals(0));
      expect(analyzeMetric.achievedObjectivesCount, equals(0));
      expect(analyzeMetric.totalAttemptsCount, equals(0));
      expect(analyzeMetric.totalCorrectCount, equals(0));
      expect(analyzeMetric.observedAccuracy, isNull);
      expect(analyzeMetric.hasSufficientEvidence, isFalse);

      // Evaluate level (zero objectives in list)
      final evaluateMetric = distribution.levels[BloomTaxonomyLevel.evaluate]!;
      expect(evaluateMetric.totalObjectivesCount, equals(0));
      expect(evaluateMetric.attemptedObjectivesCount, equals(0));
      expect(evaluateMetric.observedAccuracy, isNull);
      expect(evaluateMetric.hasSufficientEvidence, isFalse);
    });

    test('2. Empty objectives input evaluates cleanly across all Bloom levels',
        () {
      final distribution = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: const [],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(distribution.totalAttemptsAcrossAllLevels, equals(0));
      expect(distribution.overallAccuracy, isNull);
      expect(
          distribution.levels.length, equals(BloomTaxonomyLevel.values.length));
    });

    test('3. Argument validations: empty learnerId, invalid evidence threshold',
        () {
      expect(
        () => evaluator.evaluate(
          learnerId: '',
          objectives: const [],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: 'l_1',
          objectives: const [],
          progressList: const [],
          minimumLevelEvidenceThreshold: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('4. Deterministic evaluation contract', () {
      final d1 = evaluator.evaluate(
        learnerId: 'l_1',
        objectives: objectives,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      final d2 = evaluator.evaluate(
        learnerId: 'l_1',
        objectives: objectives,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('5. Deduplication of duplicate objective inputs', () {
      final duplicateObjectives = [
        ...objectives,
        objectives.first, // Duplicate
      ];

      final d1 = evaluator.evaluate(
        learnerId: 'l_1',
        objectives: duplicateObjectives,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      final rememberMetric = d1.levels[BloomTaxonomyLevel.remember]!;
      expect(rememberMetric.totalObjectivesCount, equals(1));
    });

    test('6. evaluateFromDomain and evaluateFromFramework convenience methods',
        () {
      final domain = CurriculumDomain(
        id: 'dom_1',
        title: 'Domain 1',
        description: 'Domain 1 description',
        provenance: 'test',
        units: [
          CurriculumUnit(
            id: 'unit_1',
            domainId: 'dom_1',
            title: 'Unit 1',
            description: 'Unit 1 description',
            provenance: 'test',
          ),
        ],
      );

      final framework = CurriculumFramework(
        id: 'fw_1',
        title: 'Framework 1',
        description: 'Framework 1 description',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-08-25',
          provenance: 'test',
        ),
        provenance: 'test',
        domains: [domain],
      );

      final fromDomain = evaluator.evaluateFromDomain(
        domain: domain,
        learnerId: 'learner_001',
        allObjectives: objectives,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(fromDomain.scopeId, equals('dom_1'));
      expect(fromDomain.metadata['domainTitle'], equals('Domain 1'));

      final fromFramework = evaluator.evaluateFromFramework(
        framework: framework,
        learnerId: 'learner_001',
        allObjectives: objectives,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(fromFramework.scopeId, equals('fw_1'));
      expect(fromFramework.metadata['frameworkTitle'], equals('Framework 1'));
    });
  });
}
