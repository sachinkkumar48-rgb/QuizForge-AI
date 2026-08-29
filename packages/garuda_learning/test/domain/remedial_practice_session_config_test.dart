import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/question_selection_policy.dart';
import 'package:garuda_learning/domain/entities/question_sequencer_policy.dart';
import 'package:garuda_learning/domain/entities/remedial_practice_session_config.dart';

void main() {
  group('RemedialPracticeSessionConfig Entity Tests (TITAN-KO-025.0 P25)', () {
    final fixedDate = DateTime.utc(2026, 8, 28, 10, 0, 0);

    test('1. Valid construction stores target questions and session limits',
        () {
      final config = RemedialPracticeSessionConfig(
        configId: 'retry_learner1_lo1',
        learnerId: 'learner_100',
        objectiveId: 'lo_const_02',
        remedialLessonId: 'rem_lo_const_02_v1',
        targetQuestionIds: const ['q_101', 'q_102', 'q_103'],
        questionLimit: 3,
        createdAt: fixedDate,
      );

      expect(config.configId, equals('retry_learner1_lo1'));
      expect(config.learnerId, equals('learner_100'));
      expect(config.objectiveId, equals('lo_const_02'));
      expect(config.remedialLessonId, equals('rem_lo_const_02_v1'));
      expect(config.targetQuestionIds, equals(['q_101', 'q_102', 'q_103']));
      expect(config.questionLimit, equals(3));
      expect(config.hasTargetQuestions, isTrue);
      expect(config.createdAt, equals(fixedDate));
    });

    test(
        '2. Rejects empty configId, learnerId, objectiveId, or remedialLessonId',
        () {
      expect(
        () => RemedialPracticeSessionConfig(
          configId: '  ',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          remedialLessonId: 'rem_1',
          targetQuestionIds: const ['q_1'],
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialPracticeSessionConfig(
          configId: 'cfg_1',
          learnerId: '  ',
          objectiveId: 'lo_const_02',
          remedialLessonId: 'rem_1',
          targetQuestionIds: const ['q_1'],
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialPracticeSessionConfig(
          configId: 'cfg_1',
          learnerId: 'learner_100',
          objectiveId: '  ',
          remedialLessonId: 'rem_1',
          targetQuestionIds: const ['q_1'],
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialPracticeSessionConfig(
          configId: 'cfg_1',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          remedialLessonId: '  ',
          targetQuestionIds: const ['q_1'],
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects invalid questionLimit (< 1 or > 50)', () {
      expect(
        () => RemedialPracticeSessionConfig(
          configId: 'cfg_1',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          remedialLessonId: 'rem_1',
          targetQuestionIds: const ['q_1'],
          questionLimit: 0,
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialPracticeSessionConfig(
          configId: 'cfg_1',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          remedialLessonId: 'rem_1',
          targetQuestionIds: const ['q_1'],
          questionLimit: 51,
          createdAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });

    test('4. toSessionConfiguration produces a valid P19 SessionConfiguration',
        () {
      final config = RemedialPracticeSessionConfig(
        configId: 'retry_test',
        learnerId: 'learner_100',
        objectiveId: 'lo_const_02',
        remedialLessonId: 'rem_lo_const_02_v1',
        targetQuestionIds: const ['q_1', 'q_2'],
        questionLimit: 5,
        createdAt: fixedDate,
      );

      final sessionConfig = config.toSessionConfiguration(
        selectionPolicy: QuestionSelectionPolicy.unattemptedOnly,
        sequencerPolicy: QuestionSequencerPolicy.difficultyAscending,
      );

      expect(sessionConfig.learnerId, equals('learner_100'));
      expect(sessionConfig.objectiveIds, equals(['lo_const_02']));
      expect(sessionConfig.questionLimit, equals(5));
      expect(sessionConfig.selectionPolicy,
          equals(QuestionSelectionPolicy.unattemptedOnly));
      expect(sessionConfig.sequencerPolicy,
          equals(QuestionSequencerPolicy.difficultyAscending));
      expect(sessionConfig.allowRepeatAttempts, isFalse);
    });

    test('5. JSON roundtrip preserves all fields', () {
      final config = RemedialPracticeSessionConfig(
        configId: 'retry_json',
        learnerId: 'learner_100',
        objectiveId: 'lo_const_02',
        remedialLessonId: 'rem_lo_const_02_v1',
        targetQuestionIds: const ['q_1', 'q_2'],
        questionLimit: 4,
        createdAt: fixedDate,
        metadata: {'batch': 'aug_2026'},
      );

      final json = config.toJson();
      final restored = RemedialPracticeSessionConfig.fromJson(json);

      expect(restored, equals(config));
      expect(restored.hashCode, equals(config.hashCode));
      expect(restored.targetQuestionIds, equals(['q_1', 'q_2']));
      expect(restored.metadata['batch'], equals('aug_2026'));
    });
  });
}
