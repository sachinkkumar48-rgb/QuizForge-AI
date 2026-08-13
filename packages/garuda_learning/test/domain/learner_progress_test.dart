import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('LearnerProgress Domain Model Tests (TITAN-KO-018.0 P18)', () {
    test('LearnerProgress initializes cleanly with default values', () {
      final progress = LearnerProgress(
        learnerId: 'learner_101',
        objectiveId: 'lo_basic_structure_doctrine',
      );

      expect(progress.learnerId, equals('learner_101'));
      expect(progress.objectiveId, equals('lo_basic_structure_doctrine'));
      expect(progress.attemptCount, equals(0));
      expect(progress.correctCount, equals(0));
      expect(progress.successRate, equals(0.0));
      expect(progress.status, equals(LearnerObjectiveStatus.notStarted));
      expect(progress.isAchieved, isFalse);
      expect(progress.lastAttemptAt, isNull);
      expect(progress.achievedAt, isNull);
    });

    test(
        'LearnerProgress calculates success rate accurately when attempts exist',
        () {
      final progress = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 5,
        correctCount: 4,
        status: LearnerObjectiveStatus.achieved,
      );

      expect(progress.attemptCount, equals(5));
      expect(progress.correctCount, equals(4));
      expect(progress.successRate, equals(0.80));
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);
    });

    test('LearnerProgress rejects empty learnerId or objectiveId', () {
      expect(
        () => LearnerProgress(learnerId: '', objectiveId: 'o1'),
        throwsArgumentError,
      );
      expect(
        () => LearnerProgress(learnerId: 'l1', objectiveId: '  '),
        throwsArgumentError,
      );
    });

    test(
        'LearnerProgress rejects negative attemptCount or invalid correctCount',
        () {
      expect(
        () => LearnerProgress(
          learnerId: 'l1',
          objectiveId: 'o1',
          attemptCount: -1,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearnerProgress(
          learnerId: 'l1',
          objectiveId: 'o1',
          attemptCount: 3,
          correctCount: 4,
        ),
        throwsArgumentError,
      );
    });

    test('LearnerProgress serializes to and from JSON correctly', () {
      final now = DateTime.now().toUtc();
      final p1 = LearnerProgress(
        learnerId: 'learner_55',
        objectiveId: 'lo_art21',
        attemptCount: 10,
        correctCount: 9,
        successRate: 0.90,
        lastAttemptAt: now,
        status: LearnerObjectiveStatus.achieved,
        achievedAt: now,
      );

      final json = p1.toJson();
      final p2 = LearnerProgress.fromJson(json);

      expect(p2.learnerId, equals(p1.learnerId));
      expect(p2.objectiveId, equals(p1.objectiveId));
      expect(p2.attemptCount, equals(p1.attemptCount));
      expect(p2.correctCount, equals(p1.correctCount));
      expect(p2.successRate, equals(p1.successRate));
      expect(p2.lastAttemptAt, equals(p1.lastAttemptAt));
      expect(p2.status, equals(p1.status));
      expect(p2.achievedAt, equals(p1.achievedAt));
      expect(p2, equals(p1));
    });

    test('LearnerProgress equality and hash code work as expected', () {
      final p1 = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 5,
        correctCount: 4,
        status: LearnerObjectiveStatus.achieved,
      );
      final p2 = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 5,
        correctCount: 4,
        status: LearnerObjectiveStatus.achieved,
      );
      final p3 = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 5,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('LearnerProgress carries only allowed terminology (no mastery claims)',
        () {
      final p = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 5,
        correctCount: 5,
        status: LearnerObjectiveStatus.achieved,
      );

      final jsonStr = p.toJson().toString();
      expect(jsonStr, isNot(contains('understands')));
      expect(jsonStr, isNot(contains('comprehends')));
      expect(jsonStr, isNot(contains('mastered')));
      expect(p.status.displayName, equals('Achieved'));
    });
  });
}
