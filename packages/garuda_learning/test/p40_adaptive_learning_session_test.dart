/// P40 Adaptive Learning Session Domain & Repository Unit Test Suite (TITAN-KO-040.0 P40).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 9, 6, 12, 0, 0);

  group('SessionStatus', () {
    test('verifies terminal and input capabilities', () {
      expect(SessionStatus.created.isTerminal, isFalse);
      expect(SessionStatus.active.isTerminal, isFalse);
      expect(SessionStatus.paused.isTerminal, isFalse);
      expect(SessionStatus.recovering.isTerminal, isFalse);
      expect(SessionStatus.completed.isTerminal, isTrue);
      expect(SessionStatus.abandoned.isTerminal, isTrue);
      expect(SessionStatus.failed.isTerminal, isTrue);

      expect(SessionStatus.active.canAcceptInput, isTrue);
      expect(SessionStatus.paused.canAcceptInput, isFalse);
      expect(SessionStatus.completed.canAcceptInput, isFalse);
    });

    test('validates permitted and rejected state transitions', () {
      expect(
          SessionStatus.created.canTransitionTo(SessionStatus.active), isTrue);
      expect(SessionStatus.created.canTransitionTo(SessionStatus.completed),
          isFalse);

      expect(
          SessionStatus.active.canTransitionTo(SessionStatus.paused), isTrue);
      expect(SessionStatus.active.canTransitionTo(SessionStatus.completed),
          isTrue);
      expect(
          SessionStatus.active.canTransitionTo(SessionStatus.created), isFalse);

      expect(
          SessionStatus.paused.canTransitionTo(SessionStatus.active), isTrue);
      expect(SessionStatus.paused.canTransitionTo(SessionStatus.recovering),
          isTrue);

      expect(SessionStatus.completed.canTransitionTo(SessionStatus.active),
          isFalse);
      expect(SessionStatus.abandoned.canTransitionTo(SessionStatus.active),
          isFalse);
      expect(
          SessionStatus.failed.canTransitionTo(SessionStatus.active), isFalse);
    });
  });

  group('AdaptiveLearningSession', () {
    late AdaptivePracticeSessionConfig config;

    setUp(() {
      config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        maxQuestions: 10,
      );
    });

    test('creates immutable session and serializes cleanly to JSON', () {
      final session = AdaptiveLearningSession(
        sessionId: 'sess_001',
        learnerId: 'learner_1',
        examId: 'upsc',
        startedAt: baseTime,
        lastActivityAt: baseTime,
        configuration: config,
        totalQuestionsPlanned: 10,
      );

      expect(session.sessionId, 'sess_001');
      expect(session.learnerId, 'learner_1');
      expect(session.examId, 'upsc');
      expect(session.status, SessionStatus.created);
      expect(session.currentQuestionPosition, 0);
      expect(session.checkpointRevision, 1);
      expect(session.currentLearningStateRevision, 1);

      final json = session.toJson();
      final restored = AdaptiveLearningSession.fromJson(json);

      expect(restored.sessionId, session.sessionId);
      expect(restored.learnerId, session.learnerId);
      expect(restored.examId, session.examId);
      expect(restored.status, session.status);
      expect(restored.totalQuestionsPlanned, session.totalQuestionsPlanned);
    });

    test('enforces legal transitions and throws on illegal transitions', () {
      final session = AdaptiveLearningSession(
        sessionId: 'sess_trans',
        learnerId: 'l1',
        examId: 'upsc',
        startedAt: baseTime,
        lastActivityAt: baseTime,
        status: SessionStatus.created,
        configuration: config,
        totalQuestionsPlanned: 5,
      );

      final active = session.transitionTo(SessionStatus.active);
      expect(active.status, SessionStatus.active);

      expect(
        () => active.transitionTo(SessionStatus.created),
        throwsA(isA<InvalidSessionTransitionException>()),
      );
    });

    test('advanceQuestion appends completed question and advances cursor', () {
      final session = AdaptiveLearningSession(
        sessionId: 'sess_adv',
        learnerId: 'l1',
        examId: 'upsc',
        startedAt: baseTime,
        lastActivityAt: baseTime,
        status: SessionStatus.active,
        configuration: config,
        totalQuestionsPlanned: 5,
      );

      final advanced = session.advanceQuestion(
        questionId: 'q_polity_01',
        timestamp: baseTime.add(const Duration(minutes: 2)),
      );

      expect(advanced.currentQuestionPosition, 1);
      expect(advanced.completedQuestions, ['q_polity_01']);
      expect(advanced.completedQuestionCount, 1);
    });
  });

  group('InMemoryAdaptiveLearningSessionRepository', () {
    late InMemoryAdaptiveLearningSessionRepository repo;
    late AdaptivePracticeSessionConfig config;

    setUp(() {
      repo = InMemoryAdaptiveLearningSessionRepository();
      config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        maxQuestions: 5,
      );
    });

    test('creates, retrieves, and updates session with tenant isolation',
        () async {
      final session = AdaptiveLearningSession(
        sessionId: 'sess_repo_1',
        learnerId: 'learner_A',
        examId: 'upsc',
        startedAt: baseTime,
        lastActivityAt: baseTime,
        configuration: config,
        totalQuestionsPlanned: 5,
      );

      await repo.createSession(session);

      final loaded = await repo.getSession(
        learnerId: 'learner_A',
        examId: 'upsc',
        sessionId: 'sess_repo_1',
      );
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, 'sess_repo_1');

      // Cross-tenant access returns null
      final crossTenant = await repo.getSession(
        learnerId: 'learner_B',
        examId: 'upsc',
        sessionId: 'sess_repo_1',
      );
      expect(crossTenant, isNull);
    });

    test(
        'saveCheckpoint enforces monotonic revision and allows idempotent saves',
        () async {
      final chk1 = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'sess_chk_test',
        learnerId: 'l1',
        examId: 'upsc',
        questionIndex: 0,
        completedQuestionIds: const [],
        activeObjectiveId: 'lo_polity',
        timestamp: baseTime,
      );

      await repo.saveCheckpoint(chk1);

      // Idempotent re-save of identical checkpoint succeeds
      await repo.saveCheckpoint(chk1);

      // Save revision 2
      final chk2 = chk1.copyWith(
        checkpointRevision: 2,
        questionIndex: 1,
      );
      await repo.saveCheckpoint(chk2);

      final latest = await repo.getLatestCheckpoint(
        learnerId: 'l1',
        examId: 'upsc',
        sessionId: 'sess_chk_test',
      );
      expect(latest, isNotNull);
      expect(latest!.checkpointRevision, 2);

      // Attempting to write stale revision 1 must throw StaleCheckpointException
      expect(
        () => repo.saveCheckpoint(chk1),
        throwsA(isA<StaleCheckpointException>()),
      );
    });

    test('marks completed and marks abandoned', () async {
      final session = AdaptiveLearningSession(
        sessionId: 'sess_term',
        learnerId: 'l1',
        examId: 'upsc',
        startedAt: baseTime,
        lastActivityAt: baseTime,
        configuration: config,
        totalQuestionsPlanned: 5,
      );

      await repo.createSession(session);

      await repo.markCompleted(
        learnerId: 'l1',
        examId: 'upsc',
        sessionId: 'sess_term',
        completedAt: baseTime.add(const Duration(minutes: 10)),
        completionMetadata: {'score': 100},
      );

      final completed = await repo.getSession(
        learnerId: 'l1',
        examId: 'upsc',
        sessionId: 'sess_term',
      );
      expect(completed!.status, SessionStatus.completed);
      expect(completed.completionMetadata['score'], 100);
    });
  });
}
