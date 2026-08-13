import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('SessionManager Service Tests (TITAN-KO-018.0 P18)', () {
    late InMemoryLearnerRepository learnerRepo;
    late SessionManager sessionManager;
    late Learner validLearner;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      sessionManager = SessionManager(learnerRepository: learnerRepo);

      validLearner = Learner(id: 'learner_101', name: 'Alice');
      learnerRepo.save(validLearner);
    });

    test('startSession creates a new session for verified learner', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
        objectiveIds: const ['lo_1', 'lo_2'],
        questionIds: const ['q_1', 'q_2'],
      );

      expect(session.sessionId, isNotEmpty);
      expect(session.learnerId, equals(validLearner.id));
      expect(session.objectiveIds, equals(const ['lo_1', 'lo_2']));
      expect(session.questionIds, equals(const ['q_1', 'q_2']));
      expect(session.isCompleted, isFalse);
    });

    test('startSession rejects non-existent learner', () {
      expect(
        () => sessionManager.startSession(learnerId: 'l_nonexistent'),
        throwsArgumentError,
      );
    });

    test('startSession rejects duplicate sessionId', () {
      sessionManager.startSession(
        learnerId: validLearner.id,
        sessionId: 'sess_fixed',
      );

      expect(
        () => sessionManager.startSession(
          learnerId: validLearner.id,
          sessionId: 'sess_fixed',
        ),
        throwsStateError,
      );
    });

    test('addAttemptToSession appends attempt to active session', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
        sessionId: 'sess_active',
      );

      final attempt = QuestionAttempt(
        attemptId: 'att_101',
        learnerId: validLearner.id,
        questionId: 'q1',
        objectiveId: 'lo1',
        submittedAnswer: 'A',
        sessionId: session.sessionId,
      );

      final updatedSession = sessionManager.addAttemptToSession(
        sessionId: session.sessionId,
        attempt: attempt,
      );

      expect(updatedSession.attemptIds, contains('att_101'));
      expect(updatedSession.attemptIds.length, equals(1));
    });

    test('addAttemptToSession rejects attempt with mismatched learner ID', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
      );

      final mismatchedAttempt = QuestionAttempt(
        attemptId: 'att_bad',
        learnerId: 'learner_other',
        questionId: 'q1',
        objectiveId: 'lo1',
        submittedAnswer: 'A',
      );

      expect(
        () => sessionManager.addAttemptToSession(
          sessionId: session.sessionId,
          attempt: mismatchedAttempt,
        ),
        throwsArgumentError,
      );
    });

    test('completeSession marks active session completed', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
      );

      final completed = sessionManager.completeSession(session.sessionId);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);

      final fetched = sessionManager.getSession(session.sessionId);
      expect(fetched!.isCompleted, isTrue);
    });

    test('addAttemptToSession throws error on completed session', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
      );
      sessionManager.completeSession(session.sessionId);

      final attempt = QuestionAttempt(
        attemptId: 'att_late',
        learnerId: validLearner.id,
        questionId: 'q1',
        objectiveId: 'lo1',
        submittedAnswer: 'A',
      );

      expect(
        () => sessionManager.addAttemptToSession(
          sessionId: session.sessionId,
          attempt: attempt,
        ),
        throwsStateError,
      );
    });

    test('getSessionsForLearner retrieves all sessions in chronological order',
        () {
      sessionManager.startSession(
        learnerId: validLearner.id,
        sessionId: 's1',
      );
      sessionManager.startSession(
        learnerId: validLearner.id,
        sessionId: 's2',
      );

      final sessions = sessionManager.getSessionsForLearner(validLearner.id);
      expect(sessions.length, equals(2));
      expect(sessions.map((s) => s.sessionId), equals(['s1', 's2']));
    });

    test('clear removes all stored sessions', () {
      sessionManager.startSession(learnerId: validLearner.id, sessionId: 's1');
      expect(sessionManager.getSessionsForLearner(validLearner.id), isNotEmpty);
      sessionManager.clear();
      expect(sessionManager.getSessionsForLearner(validLearner.id), isEmpty);
    });
  });
}
