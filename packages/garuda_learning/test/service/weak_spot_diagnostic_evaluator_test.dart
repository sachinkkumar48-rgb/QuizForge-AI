import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/attempt_result.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/evaluation_method.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/domain/entities/question_attempt.dart';
import 'package:garuda_learning/service/weak_spot_diagnostic_evaluator.dart';

void main() {
  group('WeakSpotDiagnosticEvaluator Service Tests (P23 Stage 4)', () {
    const evaluator = WeakSpotDiagnosticEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);

    LearningObjective makeObjective(
      String id, {
      BloomTaxonomyLevel bloomLevel = BloomTaxonomyLevel.understand,
    }) {
      return LearningObjective(
        id: id,
        unitId: 'unit_1',
        title: 'Objective $id',
        description: 'Description for $id',
        bloomLevel: bloomLevel,
        provenance: 'test_p17',
      );
    }

    LearnerProgress makeProgress(
      String objectiveId, {
      String learnerId = 'learner_001',
      required int attemptCount,
      required int correctCount,
      LearnerObjectiveStatus status = LearnerObjectiveStatus.inProgress,
      DateTime? lastAttemptAt,
    }) {
      return LearnerProgress(
        learnerId: learnerId,
        objectiveId: objectiveId,
        attemptCount: attemptCount,
        correctCount: correctCount,
        status: status,
        lastAttemptAt: lastAttemptAt,
      );
    }

    test('1. Zero-attempt objectives excluded from weak spots', () {
      final objectives = [makeObjective('lo_1'), makeObjective('lo_2')];
      final progressList = <LearnerProgress>[]; // no progress at all

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalEvaluatedObjectives, equals(2));
      expect(profile.evaluatedWithSufficientEvidence, equals(0));
      expect(profile.hasWeakSpots, isFalse);
      expect(profile.weakObjectives, isEmpty);
    });

    test('2. Sparse attempts below threshold excluded from weak spots', () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1',
            attemptCount: 3, correctCount: 0), // below default threshold 5
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.evaluatedWithSufficientEvidence, equals(0));
      expect(profile.hasWeakSpots, isFalse);
    });

    test(
        '3. Threshold boundary: exactly at threshold with low accuracy is weak',
        () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1',
            attemptCount: 5, correctCount: 2), // accuracy 0.4 < 0.6
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
      );

      expect(profile.evaluatedWithSufficientEvidence, equals(1));
      expect(profile.hasWeakSpots, isTrue);
      expect(profile.weakObjectives.length, equals(1));
      expect(profile.weakObjectives.first.objectiveId, equals('lo_1'));
    });

    test('4. Weak objective below 0.60 threshold diagnosed correctly', () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1', attemptCount: 10, correctCount: 3),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.hasWeakSpots, isTrue);
      final diag = profile.weakObjectives.first;
      expect(diag.objectiveId, equals('lo_1'));
      expect(diag.observedAccuracy, closeTo(0.30, 0.001));
      expect(diag.attemptCount, equals(10));
      expect(diag.correctCount, equals(3));
    });

    test('5. Non-weak objective >= 0.60 threshold excluded from diagnostics',
        () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1', attemptCount: 10, correctCount: 7), // 0.7 >= 0.6
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.evaluatedWithSufficientEvidence, equals(1));
      expect(profile.hasWeakSpots, isFalse);
    });

    test('6. Deficiency score calculation correct', () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1', attemptCount: 10, correctCount: 2), // accuracy 0.2
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      final diag = profile.weakObjectives.first;
      // deficiency = 1.0 - 0.2 = 0.8
      expect(diag.deficiencyScore, closeTo(0.8, 0.001));
    });

    test('7. Consecutive incorrect derivation from attempt history', () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1',
            attemptCount: 6,
            correctCount: 1,
            lastAttemptAt: DateTime.utc(2026, 8, 24, 10, 0, 0)),
      ];

      // Build raw attempt history: 1 correct, then 5 incorrect at the tail
      final attempts = [
        QuestionAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'A',
            attemptedAt: DateTime.utc(2026, 8, 20, 10, 0, 0)),
        // correct ↑
        QuestionAttempt(
            attemptId: 'a_2',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'B',
            attemptedAt: DateTime.utc(2026, 8, 21, 10, 0, 0)),
        QuestionAttempt(
            attemptId: 'a_3',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'C',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 0, 0)),
        QuestionAttempt(
            attemptId: 'a_4',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'D',
            attemptedAt: DateTime.utc(2026, 8, 23, 10, 0, 0)),
        QuestionAttempt(
            attemptId: 'a_5',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'B',
            attemptedAt: DateTime.utc(2026, 8, 24, 9, 0, 0)),
        QuestionAttempt(
            attemptId: 'a_6',
            learnerId: 'learner_001',
            questionId: 'q_1',
            objectiveId: 'lo_1',
            submittedAnswer: 'C',
            attemptedAt: DateTime.utc(2026, 8, 24, 10, 0, 0)),
      ];

      final attemptResults = [
        AttemptResult(
            attemptId: 'a_1',
            isCorrect: true,
            score: 1.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
        AttemptResult(
            attemptId: 'a_2',
            isCorrect: false,
            score: 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
        AttemptResult(
            attemptId: 'a_3',
            isCorrect: false,
            score: 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
        AttemptResult(
            attemptId: 'a_4',
            isCorrect: false,
            score: 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
        AttemptResult(
            attemptId: 'a_5',
            isCorrect: false,
            score: 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
        AttemptResult(
            attemptId: 'a_6',
            isCorrect: false,
            score: 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        attempts: attempts,
        attemptResults: attemptResults,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
      );

      expect(profile.hasWeakSpots, isTrue);
      final diag = profile.weakObjectives.first;
      // 5 consecutive incorrect at tail (a_2 through a_6)
      expect(diag.consecutiveIncorrectCount, equals(5));
    });

    test('8. Fallback when attempt history absent: consecutiveIncorrect = 0',
        () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1', attemptCount: 10, correctCount: 2),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        // NO attempts or attemptResults provided
        evaluatedAt: fixedTime,
      );

      expect(profile.hasWeakSpots, isTrue);
      expect(profile.weakObjectives.first.consecutiveIncorrectCount, equals(0));
    });

    test('9. Deterministic sorting: deficiencyScore DESC, objectiveId ASC', () {
      final objectives = [
        makeObjective('lo_c'),
        makeObjective('lo_a'),
        makeObjective('lo_b'),
      ];
      final progressList = [
        makeProgress('lo_c',
            attemptCount: 10, correctCount: 3), // accuracy 0.3, deficiency 0.7
        makeProgress('lo_a',
            attemptCount: 10, correctCount: 1), // accuracy 0.1, deficiency 0.9
        makeProgress('lo_b',
            attemptCount: 10, correctCount: 3), // accuracy 0.3, deficiency 0.7
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.weakObjectives.length, equals(3));
      // lo_a first (highest deficiency 0.9)
      expect(profile.weakObjectives[0].objectiveId, equals('lo_a'));
      // lo_b before lo_c (same deficiency 0.7, alphabetical tie-break)
      expect(profile.weakObjectives[1].objectiveId, equals('lo_b'));
      expect(profile.weakObjectives[2].objectiveId, equals('lo_c'));
    });

    test('10. Objective ID tie-break with equal deficiency scores', () {
      final objectives = [
        makeObjective('lo_z'),
        makeObjective('lo_a'),
      ];
      final progressList = [
        makeProgress('lo_z',
            attemptCount: 10, correctCount: 4), // accuracy 0.4, def 0.6
        makeProgress('lo_a',
            attemptCount: 10, correctCount: 4), // accuracy 0.4, def 0.6
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.weakObjectives.length, equals(2));
      expect(profile.weakObjectives[0].objectiveId, equals('lo_a'));
      expect(profile.weakObjectives[1].objectiveId, equals('lo_z'));
    });

    test('11. Bloom taxonomy level integration', () {
      final objectives = [
        makeObjective('lo_1', bloomLevel: BloomTaxonomyLevel.analyze),
      ];
      final progressList = [
        makeProgress('lo_1', attemptCount: 10, correctCount: 2),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.weakObjectives.first.bloomLevel,
          equals(BloomTaxonomyLevel.analyze));
    });

    test('12. Multiple learners isolated', () {
      final objectives = [makeObjective('lo_1')];
      final progressList = [
        makeProgress('lo_1',
            learnerId: 'learner_001',
            attemptCount: 10,
            correctCount: 2), // weak
        makeProgress('lo_1',
            learnerId: 'learner_999',
            attemptCount: 10,
            correctCount: 1), // different learner
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        objectives: objectives,
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      expect(profile.weakObjectives.length, equals(1));
      // Only learner_001's progress used
      expect(profile.weakObjectives.first.correctCount, equals(2));
    });

    test('13. Invalid learnerId throws ArgumentError', () {
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
          learnerId: '   ',
          objectives: const [],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('14. Invalid threshold throws ArgumentError', () {
      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          objectives: const [],
          progressList: const [],
          minimumEvidenceThreshold: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('15. Invalid weakness threshold throws ArgumentError', () {
      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          objectives: const [],
          progressList: const [],
          weaknessThreshold: -0.1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          objectives: const [],
          progressList: const [],
          weaknessThreshold: 1.1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });
  });
}
