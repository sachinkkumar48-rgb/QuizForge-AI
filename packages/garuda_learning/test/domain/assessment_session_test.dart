import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('AssessmentSession Domain Model Tests (TITAN-KO-018.0 P18)', () {
    test('AssessmentSession initializes cleanly with valid fields', () {
      final now = DateTime.now().toUtc();
      final session = AssessmentSession(
        sessionId: 'sess_101',
        learnerId: 'learner_1',
        objectiveIds: const ['lo_1', 'lo_2'],
        questionIds: const ['q_1', 'q_2'],
        startedAt: now,
      );

      expect(session.sessionId, equals('sess_101'));
      expect(session.learnerId, equals('learner_1'));
      expect(session.objectiveIds, equals(const ['lo_1', 'lo_2']));
      expect(session.questionIds, equals(const ['q_1', 'q_2']));
      expect(session.startedAt, equals(now));
      expect(session.completedAt, isNull);
      expect(session.attemptIds, isEmpty);
      expect(session.isCompleted, isFalse);
    });

    test('AssessmentSession rejects empty sessionId or learnerId', () {
      expect(
        () => AssessmentSession(sessionId: '', learnerId: 'l1'),
        throwsArgumentError,
      );
      expect(
        () => AssessmentSession(sessionId: 's1', learnerId: '   '),
        throwsArgumentError,
      );
    });

    test('AssessmentSession adds attempt cleanly', () {
      final session = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
      );

      final s2 = session.addAttempt('att_100');
      expect(s2.attemptIds, contains('att_100'));
      expect(s2.attemptIds.length, equals(1));
      expect(s2.isCompleted, isFalse);

      final s3 = s2.addAttempt('att_101');
      expect(s3.attemptIds.length, equals(2));
      expect(s3.attemptIds, equals(const ['att_100', 'att_101']));
    });

    test('AssessmentSession transition to complete sets completedAt', () {
      final session = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
      );

      final completionTime = DateTime.utc(2026, 8, 15, 14, 0);
      final completedSession = session.complete(completionTime: completionTime);

      expect(completedSession.isCompleted, isTrue);
      expect(completedSession.completedAt, equals(completionTime));
    });

    test(
        'AssessmentSession throws error when adding attempt to completed session',
        () {
      final session = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
      ).complete();

      expect(
        () => session.addAttempt('att_new'),
        throwsStateError,
      );
    });

    test(
        'AssessmentSession throws error when completing already completed session',
        () {
      final session = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
      ).complete();

      expect(
        () => session.complete(),
        throwsStateError,
      );
    });

    test('AssessmentSession serializes to and from JSON correctly', () {
      final start = DateTime.utc(2026, 8, 15, 10, 0);
      final end = DateTime.utc(2026, 8, 15, 10, 30);
      final s1 = AssessmentSession(
        sessionId: 'sess_888',
        learnerId: 'learner_77',
        objectiveIds: const ['obj_a', 'obj_b'],
        questionIds: const ['q_1', 'q_2'],
        startedAt: start,
        completedAt: end,
        attemptIds: const ['att_1', 'att_2'],
      );

      final json = s1.toJson();
      final s2 = AssessmentSession.fromJson(json);

      expect(s2.sessionId, equals(s1.sessionId));
      expect(s2.learnerId, equals(s1.learnerId));
      expect(s2.objectiveIds, equals(s1.objectiveIds));
      expect(s2.questionIds, equals(s1.questionIds));
      expect(s2.startedAt, equals(s1.startedAt));
      expect(s2.completedAt, equals(s1.completedAt));
      expect(s2.attemptIds, equals(s1.attemptIds));
      expect(s2.isCompleted, isTrue);
      expect(s2, equals(s1));
    });

    test('AssessmentSession equality and hash code work correctly', () {
      final start = DateTime.utc(2026, 1, 1);
      final s1 = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
        objectiveIds: const ['o1'],
        startedAt: start,
        attemptIds: const ['a1'],
      );
      final s2 = AssessmentSession(
        sessionId: 's1',
        learnerId: 'l1',
        objectiveIds: const ['o1'],
        startedAt: start,
        attemptIds: const ['a1'],
      );
      final s3 = AssessmentSession(
        sessionId: 's2',
        learnerId: 'l1',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}
