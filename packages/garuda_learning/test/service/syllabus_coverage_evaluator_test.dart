import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/curriculum_domain.dart';
import 'package:garuda_learning/domain/entities/curriculum_framework.dart';
import 'package:garuda_learning/domain/entities/curriculum_unit.dart';
import 'package:garuda_learning/domain/entities/curriculum_version.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/service/syllabus_coverage_evaluator.dart';

void main() {
  group('SyllabusCoverageEvaluator Service Tests (P23 Stage 3)', () {
    const evaluator = SyllabusCoverageEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);

    final domain = CurriculumDomain(
      id: 'pol_domain_judiciary',
      title: 'Union Judiciary',
      description: 'Supreme Court and High Courts',
      provenance: 'test_p17',
      units: [
        CurriculumUnit(
          id: 'unit_judiciary_sc',
          domainId: 'pol_domain_judiciary',
          title: 'Supreme Court',
          description: 'Articles 124-147',
          provenance: 'test_p17',
        ),
      ],
    );

    final framework = CurriculumFramework(
      id: 'upsc_prelims_gs2',
      title: 'UPSC Prelims GS-II / Polity',
      description: 'Complete Indian Polity and Governance',
      version: CurriculumVersion(
        version: '1.0.0',
        effectiveDate: '2026-08-15',
        provenance: 'test_p17',
      ),
      provenance: 'test_p17',
      domains: [domain],
    );

    final objectives = [
      LearningObjective(
        id: 'lo_sc_jurisdiction',
        unitId: 'unit_judiciary_sc',
        title: 'Original & Appellate Jurisdiction',
        description: 'Articles 131-134A',
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_sc_writs',
        unitId: 'unit_judiciary_sc',
        title: 'Writ Jurisdiction',
        description: 'Article 32 & types of writs',
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_sc_appointment',
        unitId: 'unit_judiciary_sc',
        title: 'Judicial Appointments',
        description: 'Collegium system and landmark judgments',
        provenance: 'test_p17',
      ),
      LearningObjective(
        id: 'lo_sc_removal',
        unitId: 'unit_judiciary_sc',
        title: 'Removal of Judges',
        description: 'Judges Inquiry Act 1968',
        provenance: 'test_p17',
      ),
    ];

    test('1. Valid partial coverage evaluation across domain scope', () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_sc_jurisdiction',
          attemptCount: 8,
          correctCount: 7,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_sc_writs',
          attemptCount: 5,
          correctCount: 3,
          status: LearnerObjectiveStatus.inProgress,
        ),
      ];

      final summary = evaluator.evaluateFromDomain(
        domain: domain,
        learnerId: 'learner_001',
        allObjectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(summary.scopeId, equals('pol_domain_judiciary'));
      expect(summary.learnerId, equals('learner_001'));
      expect(summary.totalObjectives, equals(4));
      expect(summary.attemptedObjectives, equals(2));
      expect(summary.achievedObjectives, equals(1));
      expect(summary.inProgressObjectives, equals(1));
      expect(summary.unattemptedObjectives, equals(2));
      expect(summary.coverageRatio, closeTo(0.50, 0.001)); // 2 / 4
      expect(summary.achievementRatio, closeTo(0.25, 0.001)); // 1 / 4
      expect(summary.isFullyAttempted, isFalse);
      expect(summary.isFullyAchieved, isFalse);
      expect(summary.evaluatedAt, equals(fixedTime));
    });

    test('2. Full coverage and full achievement evaluation across framework',
        () {
      final progressList = objectives.map((obj) {
        return LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: obj.id,
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
        );
      }).toList();

      final summary = evaluator.evaluateFromFramework(
        framework: framework,
        learnerId: 'learner_001',
        allObjectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(summary.scopeId, equals('upsc_prelims_gs2'));
      expect(summary.totalObjectives, equals(4));
      expect(summary.attemptedObjectives, equals(4));
      expect(summary.achievedObjectives, equals(4));
      expect(summary.inProgressObjectives, equals(0));
      expect(summary.unattemptedObjectives, equals(0));
      expect(summary.coverageRatio, equals(1.0));
      expect(summary.achievementRatio, equals(1.0));
      expect(summary.isFullyAttempted, isTrue);
      expect(summary.isFullyAchieved, isTrue);
    });

    test('3. Zero objectives scope produces 0.0 ratios safely', () {
      final summary = evaluator.evaluate(
        scopeId: 'empty_scope',
        learnerId: 'learner_001',
        scopedObjectiveIds: const [],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(summary.totalObjectives, equals(0));
      expect(summary.attemptedObjectives, equals(0));
      expect(summary.achievedObjectives, equals(0));
      expect(summary.coverageRatio, equals(0.0));
      expect(summary.achievementRatio, equals(0.0));
    });

    test('4. Argument validations: empty scopeId, empty learnerId', () {
      expect(
        () => evaluator.evaluate(
          scopeId: '',
          learnerId: 'l_1',
          scopedObjectiveIds: const ['lo_1'],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          scopeId: 'scope_1',
          learnerId: '',
          scopedObjectiveIds: const ['lo_1'],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('6. Unit scope evaluation and multi-learner progress isolation', () {
      final unit = domain.units.first;
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_sc_jurisdiction',
          attemptCount: 5,
          correctCount: 4,
          status: LearnerObjectiveStatus.achieved,
        ),
        LearnerProgress(
          learnerId: 'learner_002', // Different learner
          objectiveId: 'lo_sc_writs',
          attemptCount: 10,
          correctCount: 10,
          status: LearnerObjectiveStatus.achieved,
        ),
      ];

      final summary = evaluator.evaluateFromUnit(
        unit: unit,
        learnerId: 'learner_001',
        allObjectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(summary.scopeId, equals('unit_judiciary_sc'));
      expect(summary.totalObjectives, equals(4));
      expect(summary.attemptedObjectives,
          equals(1)); // only learner_001 progress counted
      expect(summary.achievedObjectives, equals(1));
      expect(summary.coverageRatio, equals(0.25));
      expect(summary.achievementRatio, equals(0.25));
    });
  });
}
