import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('QuestionAttempt Domain Model Tests (TITAN-KO-018.0 P18)', () {
    test('QuestionAttempt initializes cleanly with valid fields', () {
      final now = DateTime.now().toUtc();
      final attempt = QuestionAttempt(
        attemptId: 'att_001',
        learnerId: 'learner_101',
        questionId: 'qa:case:KESAVANANDA:issue:0',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'Basic Structure Doctrine limits Article 368',
        attemptedAt: now,
        sessionId: 'sess_555',
      );

      expect(attempt.attemptId, equals('att_001'));
      expect(attempt.learnerId, equals('learner_101'));
      expect(attempt.questionId, equals('qa:case:KESAVANANDA:issue:0'));
      expect(attempt.objectiveId, equals('lo_basic_structure_doctrine'));
      expect(attempt.submittedAnswer,
          equals('Basic Structure Doctrine limits Article 368'));
      expect(attempt.attemptedAt, equals(now));
      expect(attempt.sessionId, equals('sess_555'));
    });

    test('QuestionAttempt rejects empty attemptId', () {
      expect(
        () => QuestionAttempt(
          attemptId: '',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'ans',
        ),
        throwsArgumentError,
      );
    });

    test('QuestionAttempt rejects empty learnerId', () {
      expect(
        () => QuestionAttempt(
          attemptId: 'a1',
          learnerId: '  ',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'ans',
        ),
        throwsArgumentError,
      );
    });

    test('QuestionAttempt rejects empty questionId', () {
      expect(
        () => QuestionAttempt(
          attemptId: 'a1',
          learnerId: 'l1',
          questionId: '',
          objectiveId: 'o1',
          submittedAnswer: 'ans',
        ),
        throwsArgumentError,
      );
    });

    test('QuestionAttempt rejects empty objectiveId', () {
      expect(
        () => QuestionAttempt(
          attemptId: 'a1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: '',
          submittedAnswer: 'ans',
        ),
        throwsArgumentError,
      );
    });

    test('QuestionAttempt serializes to and from JSON correctly', () {
      final a1 = QuestionAttempt(
        attemptId: 'att_999',
        learnerId: 'learner_88',
        questionId: 'q_kesavananda',
        objectiveId: 'lo_basic_structure',
        submittedAnswer: 'A',
        attemptedAt: DateTime.utc(2026, 8, 15, 10, 30),
        sessionId: 'sess_123',
      );

      final json = a1.toJson();
      final a2 = QuestionAttempt.fromJson(json);

      expect(a2.attemptId, equals(a1.attemptId));
      expect(a2.learnerId, equals(a1.learnerId));
      expect(a2.questionId, equals(a1.questionId));
      expect(a2.objectiveId, equals(a1.objectiveId));
      expect(a2.submittedAnswer, equals(a1.submittedAnswer));
      expect(a2.attemptedAt, equals(a1.attemptedAt));
      expect(a2.sessionId, equals(a1.sessionId));
      expect(a2, equals(a1));
    });

    test('QuestionAttempt value equality and hash code work correctly', () {
      final a1 = QuestionAttempt(
        attemptId: 'a1',
        learnerId: 'l1',
        questionId: 'q1',
        objectiveId: 'o1',
        submittedAnswer: 'ans',
        sessionId: 's1',
      );
      final a2 = QuestionAttempt(
        attemptId: 'a1',
        learnerId: 'l1',
        questionId: 'q1',
        objectiveId: 'o1',
        submittedAnswer: 'ans',
        sessionId: 's1',
      );
      final a3 = QuestionAttempt(
        attemptId: 'a2',
        learnerId: 'l1',
        questionId: 'q1',
        objectiveId: 'o1',
        submittedAnswer: 'ans',
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(a3)));
    });

    test('QuestionAttempt toString exposes key metadata', () {
      final attempt = QuestionAttempt(
        attemptId: 'att_77',
        learnerId: 'l_5',
        questionId: 'q_10',
        objectiveId: 'o_2',
        submittedAnswer: 'ans',
      );
      expect(attempt.toString(), contains('att_77'));
      expect(attempt.toString(), contains('l_5'));
      expect(attempt.toString(), contains('q_10'));
    });
  });
}
