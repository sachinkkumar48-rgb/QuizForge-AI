import 'package:garuda_learning/garuda_learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningSession Domain Model Tests (TITAN-KO-019.0 P19)', () {
    late SessionConfiguration validConfig;

    setUp(() {
      validConfig = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_fr_art21'],
        questionLimit: 5,
      );
    });

    test('LearningSession initializes cleanly in created state', () {
      final session = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1', 'q_2', 'q_3'],
      );

      expect(session.sessionId, 'lsess_001');
      expect(session.learnerId, 'learner_101');
      expect(session.totalQuestions, 3);
      expect(session.currentQuestionIndex, 0);
      expect(session.currentQuestionId, 'q_1');
      expect(session.answeredCount, 0);
      expect(session.state, LearningSessionState.created);
      expect(session.isFinished, false);
    });

    test('LearningSession rejects empty sessionId or learnerId', () {
      expect(
        () => LearningSession(
          sessionId: '',
          learnerId: 'learner_101',
          configuration: validConfig,
          orderedQuestionIds: ['q_1'],
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningSession(
          sessionId: 'lsess_001',
          learnerId: '   ',
          configuration: validConfig,
          orderedQuestionIds: ['q_1'],
        ),
        throwsArgumentError,
      );
    });

    test(
        'LearningSession state transitions start, recordAttempt, pause, resume, complete',
        () {
      var session = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1', 'q_2'],
      );

      expect(session.state, LearningSessionState.created);

      // Start session
      session = session.start();
      expect(session.state, LearningSessionState.active);

      // Pause session
      session = session.pause();
      expect(session.state, LearningSessionState.paused);
      expect(session.pausedAt, isNotNull);

      // Resume session
      session = session.resume();
      expect(session.state, LearningSessionState.active);

      // Record first attempt
      session = session.recordAttempt('att_1');
      expect(session.answeredCount, 1);
      expect(session.currentQuestionIndex, 1);
      expect(session.currentQuestionId, 'q_2');
      expect(session.state, LearningSessionState.active);

      // Record second attempt -> finishes session
      session = session.recordAttempt('att_2');
      expect(session.answeredCount, 2);
      expect(session.currentQuestionIndex, 2);
      expect(session.currentQuestionId, isNull);
      expect(session.state, LearningSessionState.completed);
      expect(session.isFinished, true);
    });

    test('LearningSession throws StateError on invalid state transitions', () {
      final session = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1'],
        state: LearningSessionState.created,
      );

      // Cannot pause a created session before starting
      expect(() => session.pause(), throwsStateError);

      // Cancel terminal session throws StateError if cancelled twice
      final cancelled = session.cancel();
      expect(cancelled.state, LearningSessionState.cancelled);
      expect(() => cancelled.start(), throwsStateError);
    });

    test('LearningSession serializes to and from JSON correctly', () {
      final session = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1', 'q_2'],
        submittedAttemptIds: ['att_1'],
        state: LearningSessionState.active,
        assessmentSessionId: 'p18_sess_001',
      );

      final json = session.toJson();
      final roundTrip = LearningSession.fromJson(json);

      expect(roundTrip, session);
      expect(roundTrip.sessionId, 'lsess_001');
      expect(roundTrip.assessmentSessionId, 'p18_sess_001');
    });

    test('LearningSession value equality and hash code work as expected', () {
      final s1 = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1', 'q_2'],
      );

      final s2 = LearningSession(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        configuration: validConfig,
        orderedQuestionIds: ['q_1', 'q_2'],
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });
}
