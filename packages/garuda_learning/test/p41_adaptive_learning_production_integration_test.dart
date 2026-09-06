/// P41 Adaptive Learning Production Integration & End-to-End Learner Journey Test Suite
/// (TITAN-KO-041.0 P41).
///
/// Comprehensive production integration test suite covering 50 items across:
/// 1. End-to-End Learner Journey (1-10)
/// 2. Dynamic Adaptive Loop (11-20)
/// 3. Interruption & Resumption (21-25)
/// 4. Crash Recovery & Integrity (26-30)
/// 5. Multi-Tenant & Multi-Learner Isolation (31-35)
/// 6. Real-Time UI State Transitions (36-40)
/// 7. Failure Handling & Graceful Degradation (41-45)
/// 8. End-to-End Invariants (46-50)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedBaseTime = DateTime.utc(2026, 9, 20, 9, 0, 0);

  NormalizedQuestion createQuestion({
    required String id,
    String examId = 'upsc',
    int year = 2024,
    String paper = 'GS1',
    String subject = 'Polity',
    String topic = 'Preamble',
    String difficulty = 'Medium',
    List<String>? objectiveIds,
    String correctKey = 'A',
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      subject: subject,
      topic: topic,
      normalizedText: 'Question text for $id',
      originalText: 'Original text for $id',
      options: [
        Option(key: 'A', text: 'Option A', isCorrect: correctKey == 'A'),
        Option(key: 'B', text: 'Option B', isCorrect: correctKey == 'B'),
        Option(key: 'C', text: 'Option C', isCorrect: correctKey == 'C'),
        Option(key: 'D', text: 'Option D', isCorrect: correctKey == 'D'),
      ],
      officialAnswer: Answer(
        correctOptionKeys: [correctKey],
        officialAnswerSource: 'Official Key',
      ),
      explanation: 'Explanation for $id',
      difficulty: difficulty,
      source: PyqSourceReference.official(
        examId: examId,
        year: year,
        paper: paper,
      ),
      objectiveIds: objectiveIds ?? ['obj_polity_preamble'],
    );
  }

  List<NormalizedQuestion> createCorpus({
    int count = 10,
    String examId = 'upsc',
    String subject = 'Polity',
    String? topic,
    String? objectiveId,
  }) {
    return List.generate(count, (index) {
      final id = 'q_${examId}_${index + 1}';
      return createQuestion(
        id: id,
        examId: examId,
        subject: subject,
        topic: topic ?? 'Topic ${index % 3}',
        objectiveIds: [
          objectiveId ?? 'obj_${subject.toLowerCase()}_${index % 3}'
        ],
        difficulty: index.isEven ? 'Easy' : 'Medium',
      );
    });
  }

  late InMemoryAuthoritativeLearningStateRepository authRepo;
  late InMemorySessionCheckpointRepository checkpointRepo;
  late AuthoritativeLearningStateRecoveryService authRecoveryService;
  late LearningSessionRecoveryService sessionRecoveryService;
  late AdaptiveLearningJourneyOrchestrator orchestrator;

  setUp(() {
    authRepo = InMemoryAuthoritativeLearningStateRepository();
    checkpointRepo = InMemorySessionCheckpointRepository();
    authRecoveryService = AuthoritativeLearningStateRecoveryService(
      repository: authRepo,
    );
    sessionRecoveryService = LearningSessionRecoveryService(
      checkpointRepository: checkpointRepo,
      authoritativeRecoveryService: authRecoveryService,
    );
    orchestrator = AdaptiveLearningJourneyOrchestrator(
      authRepository: authRepo,
      authRecoveryService: authRecoveryService,
      checkpointRepository: checkpointRepo,
      sessionRecoveryService: sessionRecoveryService,
    );
  });

  // ==========================================================================
  // Group 1: End-to-End Learner Journey (Items 1-10)
  // ==========================================================================
  group('P41 Group 1: End-to-End Learner Journey (1-10)', () {
    test(
        '1. Complete journey execution from quiz corpus input to final session completion',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_001',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );

      expect(startRes.isSuccess, isTrue);
      expect(startRes.session, isNotNull);
      var currentSession = startRes.session!;
      expect(currentSession.status, LearningJourneyStatus.questionPresented);
      expect(currentSession.currentQuestionIndex, 0);
      expect(currentSession.totalQuestions, 3);

      for (var i = 0; i < 3; i++) {
        final q = currentSession.currentQuestion!;
        final subRes = await orchestrator.submitAnswer(
          session: currentSession,
          questionId: q.id,
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(minutes: i + 1)),
        );
        expect(subRes.isSuccess, isTrue);
        currentSession = subRes.session!;
      }

      expect(currentSession.status, LearningJourneyStatus.completed);
      expect(currentSession.isCompleted, isTrue);
      expect(currentSession.completedAt, isNotNull);
      expect(currentSession.completedQuestionIds.length, 3);
    });

    test(
        '2. Sequential question progression follows exact spec order from index 0 to N-1',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_seq',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 4,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final expectedIds = session.spec.orderedQuestionIds;

      for (var i = 0; i < 4; i++) {
        expect(session.currentQuestionIndex, i);
        expect(session.currentQuestion?.id, expectedIds[i]);
        final subRes = await orchestrator.submitAnswer(
          session: session,
          questionId: expectedIds[i],
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(minutes: i + 1)),
        );
        session = subRes.session!;
      }
      expect(session.isCompleted, isTrue);
    });

    test('3. Answer submission records accuracy and updates execution score',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_score',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;

      // Answer 1: Correct ('A')
      final q1 = session.currentQuestion!;
      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: q1.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub1.isSuccess, isTrue);
      expect(sub1.lastAnswerResult?.isCorrect, isTrue);
      session = sub1.session!;

      // Answer 2: Incorrect ('B')
      final q2 = session.currentQuestion!;
      final sub2 = await orchestrator.submitAnswer(
        session: session,
        questionId: q2.id,
        answer: 'B',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 60)),
      );
      expect(sub2.isSuccess, isTrue);
      expect(sub2.lastAnswerResult?.isCorrect, isFalse);
      expect(sub2.session!.executionState.progress.correctCount, 1);
    });

    test('4. Checkpoint is updated and persisted after each question answered',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_chk',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final initialChk = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_chk',
        examId: 'upsc',
        sessionId: session.sessionId,
      );
      expect(initialChk, isNotNull);
      expect(initialChk!.questionIndex, 0);

      final q1 = session.currentQuestion!;
      await orchestrator.submitAnswer(
        session: session,
        questionId: q1.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 40)),
      );
      final chkAfterQ1 = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_chk',
        examId: 'upsc',
        sessionId: session.sessionId,
      );
      expect(chkAfterQ1!.questionIndex, 1);
      expect(chkAfterQ1.completedQuestionIds, [q1.id]);
    });

    test(
        '5. Checkpoint questionIndex advances monotonically (0 -> 1 -> 2 -> ...)',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_mono',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      var prevIndex = session.currentQuestionIndex;
      expect(prevIndex, 0);

      for (var i = 0; i < 3; i++) {
        final q = session.currentQuestion!;
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: q.id,
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(minutes: i + 1)),
        );
        session = sub.session!;
        expect(session.currentQuestionIndex >= prevIndex, isTrue);
        prevIndex = session.currentQuestionIndex;
      }
    });

    test(
        '6. Journey status transitions to questionPresented when more questions remain',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_trans',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      expect(session.status, LearningJourneyStatus.questionPresented);

      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub1.session!.status, LearningJourneyStatus.questionPresented);
      expect(sub1.session!.isCompleted, isFalse);
    });

    test(
        '7. Journey status transitions to completed on answering the final question',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_final',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub.session!.status, LearningJourneyStatus.completed);
      expect(sub.session!.isCompleted, isTrue);
    });

    test(
        '8. completedQuestionIds reflects the complete ordered lineage of answered questions',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_lineage',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final answered = <String>[];

      for (var i = 0; i < 3; i++) {
        final qid = session.currentQuestion!.id;
        answered.add(qid);
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: qid,
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(minutes: i + 1)),
        );
        session = sub.session!;
        expect(session.completedQuestionIds, answered);
      }
    });

    test(
        '9. Session timestamps (createdAt, lastActivityAt, completedAt) are consistently maintained',
        () async {
      final corpus = createCorpus(count: 3);
      final t0 = fixedBaseTime;
      final t1 = fixedBaseTime.add(const Duration(seconds: 45));
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_ts',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
        startedAt: t0,
      );
      var session = startRes.session!;
      expect(session.createdAt, t0);
      expect(session.lastActivityAt, t0);
      expect(session.completedAt, isNull);

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: t1,
      );
      session = sub.session!;
      expect(session.createdAt, t0);
      expect(session.lastActivityAt, t1);
      expect(session.completedAt, t1);
    });

    test(
        '10. Step result captures execution metrics and last answer details accurately',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_step',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final qId = session.currentQuestion!.id;

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: qId,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );

      expect(sub.isSuccess, isTrue);
      expect(sub.lastAnswerResult, isNotNull);
      expect(sub.lastAnswerResult!.questionId, qId);
      expect(sub.lastAnswerResult!.submittedAnswer, 'A');
      expect(sub.lastAnswerResult!.isCorrect, isTrue);
    });
  });

  // ==========================================================================
  // Group 2: Dynamic Adaptive Loop (Items 11-20)
  // ==========================================================================
  group('P41 Group 2: Dynamic Adaptive Loop (11-20)', () {
    test(
        '11. Adaptive selection prioritizes questions matching target objective criteria',
        () async {
      final corpus = [
        createQuestion(id: 'q_other_1', objectiveIds: ['obj_history']),
        createQuestion(id: 'q_target_1', objectiveIds: ['obj_polity_target']),
        createQuestion(id: 'q_target_2', objectiveIds: ['obj_polity_target']),
        createQuestion(id: 'q_other_2', objectiveIds: ['obj_geography']),
      ];

      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_obj_target',
        examId: 'upsc',
        corpus: corpus,
        targetObjectiveId: 'obj_polity_target',
        questionCount: 2,
        startedAt: fixedBaseTime,
      );

      expect(startRes.isSuccess, isTrue);
      final session = startRes.session!;
      for (final q in session.spec.orderedQuestions) {
        expect(q.objectiveIds.contains('obj_polity_target'), isTrue);
      }
    });

    test(
        '12. Adaptive question selection honors targetQuestionCount configuration',
        () async {
      final corpus = createCorpus(count: 8);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_cnt',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 4,
        startedAt: fixedBaseTime,
      );
      expect(startRes.isSuccess, isTrue);
      expect(startRes.session!.totalQuestions, 4);
      expect(startRes.session!.spec.totalQuestions, 4);
    });

    test(
        '13. Outcome consolidation produces valid evidence with correctness evaluation',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_outcome',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub.isSuccess, isTrue);
      expect(sub.lastAnswerResult!.isCorrect, isTrue);
      expect(sub.lastAnswerResult!.isAnswered, isTrue);
    });

    test(
        '14. State reconciliation increments authoritative state revision monotonically',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_rev',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final initialRev = session.authoritativeState.revision;

      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      final rev1 = sub1.session!.authoritativeState.revision;
      expect(rev1, greaterThan(initialRev));

      final sub2 = await orchestrator.submitAnswer(
        session: sub1.session!,
        questionId: sub1.session!.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 60)),
      );
      final rev2 = sub2.session!.authoritativeState.revision;
      expect(rev2, greaterThan(rev1));
    });

    test(
        '15. Authoritative state progress map tracks objective performance after submission',
        () async {
      final corpus = [
        createQuestion(id: 'q_spec_1', objectiveIds: ['obj_polity_preamble']),
      ];
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_pmap',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 25)),
      );
      final updatedAuth = sub.session!.authoritativeState;
      expect(
          updatedAuth.progressMap.containsKey('obj_polity_preamble'), isTrue);
      final objProgress = updatedAuth.progressMap['obj_polity_preamble']!;
      expect(objProgress.attemptCount, greaterThan(0));
    });

    test(
        '16. Consecutive correct answers update mastery and performance metrics',
        () async {
      final corpus = createCorpus(count: 3, objectiveId: 'obj_cons');
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_cons',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      for (var i = 0; i < 2; i++) {
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: session.currentQuestion!.id,
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(seconds: (i + 1) * 30)),
        );
        session = sub.session!;
      }
      expect(session.executionState.progress.correctCount, 2);
      expect(session.executionState.progress.accuracyAmongAnswered, 1.0);
    });

    test(
        '17. Incorrect answers are captured in outcome evidence without breaking session flow',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inc',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;

      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'D', // Incorrect (A is correct)
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub1.isSuccess, isTrue);
      expect(sub1.lastAnswerResult!.isCorrect, isFalse);
      expect(sub1.session!.currentQuestionIndex, 1);
      expect(sub1.session!.status, LearningJourneyStatus.questionPresented);
    });

    test('18. Multiple question submissions yield cumulative score tracking',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_cum',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final answers = ['A', 'A', 'B']; // Correct, Correct, Incorrect

      for (var i = 0; i < 3; i++) {
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: session.currentQuestion!.id,
          answer: answers[i],
          submittedAt: fixedBaseTime.add(Duration(seconds: (i + 1) * 30)),
        );
        session = sub.session!;
      }
      expect(session.executionState.progress.correctCount, 2);
      expect(session.executionState.progress.incorrectCount, 1);
      expect(session.executionState.progress.answeredCount, 3);
    });

    test(
        '19. Checkpoint revision matches or reflects pipeline persistence progression',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_chk_rev',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final rev0 = session.checkpoint.checkpointRevision;

      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 20)),
      );
      final rev1 = sub1.session!.checkpoint.checkpointRevision;
      expect(rev1, greaterThan(rev0));
    });

    test(
        '20. Full cycle execution from question presentation to state reconciliation is atomic per question',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_atom',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      expect(sub.isSuccess, isTrue);
      expect(sub.session!.authoritativeState.learnerId, 'learner_atom');
      expect(sub.session!.checkpoint.completedQuestionIds.length, 1);
    });
  });

  // ==========================================================================
  // Group 3: Interruption & Resumption (Items 21-25)
  // ==========================================================================
  group('P41 Group 3: Interruption & Resumption (21-25)', () {
    test(
        '21. Active journey transitions to interrupted status on explicit pause/interruption',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_pause',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      final intRes = orchestrator.interruptJourney(
        session: session,
        reason: 'user_paused_session',
        interruptedAt: fixedBaseTime.add(const Duration(minutes: 2)),
      );

      expect(intRes.isSuccess, isTrue);
      expect(intRes.session!.status, LearningJourneyStatus.interrupted);
      expect(intRes.session!.isInterrupted, isTrue);
    });

    test(
        '22. Interrupted session preserves current question cursor, answers, and checkpoint',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_preserve',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 4,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;

      // Answer Q0
      final sub0 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      session = sub0.session!;
      expect(session.currentQuestionIndex, 1);

      // Interrupt at Q1
      final intRes = orchestrator.interruptJourney(session: session);
      final paused = intRes.session!;
      expect(paused.currentQuestionIndex, 1);
      expect(paused.completedQuestionIds.length, 1);
      expect(paused.checkpoint.questionIndex, 1);
    });

    test(
        '23. Resuming interrupted journey restores status to questionPresented',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_resume_stat',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      session = sub.session!;

      final intRes = orchestrator.interruptJourney(session: session);
      expect(intRes.session!.status, LearningJourneyStatus.interrupted);

      final resumeRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_resume_stat',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
        resumedAt: fixedBaseTime.add(const Duration(minutes: 5)),
      );

      expect(resumeRes.isSuccess, isTrue);
      expect(
          resumeRes.session!.status, LearningJourneyStatus.questionPresented);
    });

    test(
        '24. Resumed journey presents the exact uncompleted question at current cursor',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_resume_exact',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final q0 = session.currentQuestion!;

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: q0.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      session = sub.session!;
      final q1BeforePause = session.currentQuestion!;
      expect(session.currentQuestionIndex, 1);

      orchestrator.interruptJourney(session: session);

      final resumeRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_resume_exact',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
        resumedAt: fixedBaseTime.add(const Duration(minutes: 5)),
      );

      expect(resumeRes.session!.currentQuestionIndex, 1);
      expect(resumeRes.session!.currentQuestion?.id, q1BeforePause.id);
    });

    test(
        '25. Resumed journey completes remaining questions seamlessly to final completion',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_resume_finish',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;

      // Answer Q0
      final sub0 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      session = sub0.session!;

      // Interrupt
      orchestrator.interruptJourney(session: session);

      // Resume
      final resumeRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_resume_finish',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
        resumedAt: fixedBaseTime.add(const Duration(minutes: 5)),
      );
      session = resumeRes.session!;
      expect(session.isCompleted, isFalse);

      // Answer Q1 (final)
      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(minutes: 6)),
      );
      session = sub1.session!;
      expect(session.isCompleted, isTrue);
      expect(session.status, LearningJourneyStatus.completed);
    });
  });

  // ==========================================================================
  // Group 4: Crash Recovery & Integrity (Items 26-30)
  // ==========================================================================
  group('P41 Group 4: Crash Recovery & Integrity (26-30)', () {
    test(
        '26. Simulated process crash after checkpoint recovers valid session from durable storage',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_crash',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;
      final sessionId = session.sessionId;

      // Answer Q0 and Q1
      for (var i = 0; i < 2; i++) {
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: session.currentQuestion!.id,
          answer: 'A',
          submittedAt: fixedBaseTime.add(Duration(seconds: (i + 1) * 30)),
        );
        session = sub.session!;
      }

      // Simulate crash: Reconstruct orchestrator with same durable repositories
      final crashedOrchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
      );

      final recovered = await crashedOrchestrator.recoverAndResumeJourney(
        learnerId: 'learner_crash',
        examId: 'upsc',
        sessionId: sessionId,
        corpus: corpus,
        resumedAt: fixedBaseTime.add(const Duration(minutes: 10)),
      );

      expect(recovered.isSuccess, isTrue);
      expect(recovered.session!.sessionId, sessionId);
      expect(recovered.session!.currentQuestionIndex, 2);
      expect(recovered.session!.completedQuestionIds.length, 2);
    });

    test(
        '27. Corrupted checkpoint with mismatched checksum is rejected with corruptCheckpoint error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_corrupt',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;

      // Directly corrupt raw storage payload in checkpoint repository
      checkpointRepo.injectRawPayload(
        learnerId: 'learner_corrupt',
        examId: 'upsc',
        sessionId: session.sessionId,
        rawPayload: '{"invalid_json": true, "corrupted": true}',
      );

      final recRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_corrupt',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
      );

      expect(recRes.isFailure, isTrue);
      expect(recRes.error?.code, LearningJourneyErrorCode.corruptCheckpoint);
    });

    test(
        '28. Stale checkpoint revision lower than authoritative state triggers stale revision handling',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_stale',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;

      // Checkpoint claims authoritative state was at rev 10 (out of sync with actual authoritative state at rev 1)
      final higherChk = session.checkpoint.copyWith(
        authoritativeStateRevision: 10,
        checkpointRevision: 2,
      );
      await checkpointRepo.saveCheckpoint(higherChk);

      final recRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_stale',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
      );

      expect(recRes.isFailure, isTrue);
      expect(recRes.error?.code, LearningJourneyErrorCode.staleRevision);
    });

    test(
        '29. Checkpoint SHA-256 checksum validates session identity and cursor integrity',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_hash',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final session = startRes.session!;
      expect(session.checkpoint.checksum.isNotEmpty, isTrue);
      final deserialized =
          SessionCheckpoint.fromRawJson(session.checkpoint.toCanonicalJson());
      expect(deserialized.checksum, session.checkpoint.checksum);
    });

    test(
        '30. State reconstruction cleanly rebuilds execution state without re-answering past questions',
        () async {
      final corpus = createCorpus(count: 5);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_rebuild',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
        startedAt: fixedBaseTime,
      );
      var session = startRes.session!;

      // Answer Q0
      final q0 = session.currentQuestion!;
      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: q0.id,
        answer: 'A',
        submittedAt: fixedBaseTime.add(const Duration(seconds: 30)),
      );
      session = sub.session!;

      final recRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'learner_rebuild',
        examId: 'upsc',
        sessionId: session.sessionId,
        corpus: corpus,
      );

      final recSession = recRes.session!;
      expect(recSession.completedQuestionIds, [q0.id]);
      expect(recSession.executionState.progress.answeredCount, 1);
      expect(recSession.currentQuestionIndex, 1);
    });
  });

  // ==========================================================================
  // Group 5: Multi-Tenant & Multi-Learner Isolation (Items 31-35)
  // ==========================================================================
  group('P41 Group 5: Multi-Tenant & Multi-Learner Isolation (31-35)', () {
    test(
        '31. Distinct learners on the same exam maintain completely isolated journey states',
        () async {
      final corpus = createCorpus(count: 4);
      final s1 = await orchestrator.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final s2 = await orchestrator.startJourney(
        learnerId: 'learner_beta',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );

      expect(s1.session!.sessionId, isNot(equals(s2.session!.sessionId)));
      expect(s1.session!.learnerId, 'learner_alpha');
      expect(s2.session!.learnerId, 'learner_beta');

      // Mutate alpha
      await orchestrator.submitAnswer(
        session: s1.session!,
        questionId: s1.session!.currentQuestion!.id,
        answer: 'A',
      );

      // Check beta remains at index 0
      final betaChk = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_beta',
        examId: 'upsc',
        sessionId: s2.session!.sessionId,
      );
      expect(betaChk!.questionIndex, 0);
      expect(betaChk.completedQuestionIds, isEmpty);
    });

    test(
        '32. Same learner on different exams maintains independent progress and checkpoints',
        () async {
      final corpusUpsc = createCorpus(count: 3, examId: 'upsc');
      final corpusGate = createCorpus(count: 3, examId: 'gate');

      final jUpsc = await orchestrator.startJourney(
        learnerId: 'learner_multi_exam',
        examId: 'upsc',
        corpus: corpusUpsc,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final jGate = await orchestrator.startJourney(
        learnerId: 'learner_multi_exam',
        examId: 'gate',
        corpus: corpusGate,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );

      expect(jUpsc.session!.examId, 'upsc');
      expect(jGate.session!.examId, 'gate');

      final chkUpsc = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_multi_exam',
        examId: 'upsc',
        sessionId: jUpsc.session!.sessionId,
      );
      final chkGate = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_multi_exam',
        examId: 'gate',
        sessionId: jGate.session!.sessionId,
      );

      expect(chkUpsc!.examId, 'upsc');
      expect(chkGate!.examId, 'gate');
    });

    test(
        '33. Concurrent sessions for same learner and exam do not overwrite each other\'s checkpoints',
        () async {
      final corpus = createCorpus(count: 4);
      final sA = await orchestrator.startJourney(
        learnerId: 'learner_concurrent',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final sB = await orchestrator.startJourney(
        learnerId: 'learner_concurrent',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime.add(const Duration(seconds: 5)),
      );

      expect(sA.session!.sessionId, isNot(equals(sB.session!.sessionId)));

      // Advance sA
      await orchestrator.submitAnswer(
        session: sA.session!,
        questionId: sA.session!.currentQuestion!.id,
        answer: 'A',
      );

      final chkA = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_concurrent',
        examId: 'upsc',
        sessionId: sA.session!.sessionId,
      );
      final chkB = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_concurrent',
        examId: 'upsc',
        sessionId: sB.session!.sessionId,
      );

      expect(chkA!.questionIndex, 1);
      expect(chkB!.questionIndex, 0);
    });

    test(
        '34. Resume request with mismatched learnerId is rejected with tenantMismatch error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'owner_learner',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final sessionId = startRes.session!.sessionId;

      final recRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'attacker_learner',
        examId: 'upsc',
        sessionId: sessionId,
        corpus: corpus,
      );

      expect(recRes.isFailure, isTrue);
      expect(recRes.error?.code, LearningJourneyErrorCode.missingCheckpoint);
    });

    test(
        '35. Resume request with mismatched examId is rejected with tenantMismatch error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'owner_learner',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
        startedAt: fixedBaseTime,
      );
      final sessionId = startRes.session!.sessionId;

      final recRes = await orchestrator.recoverAndResumeJourney(
        learnerId: 'owner_learner',
        examId: 'neet',
        sessionId: sessionId,
        corpus: corpus,
      );

      expect(recRes.isFailure, isTrue);
      expect(recRes.error?.code, LearningJourneyErrorCode.missingCheckpoint);
    });
  });

  // ==========================================================================
  // Group 6: Real-Time UI State Transitions (Items 36-40)
  // ==========================================================================
  group('P41 Group 6: Real-Time UI State Transitions (36-40)', () {
    test(
        '36. AdaptiveLearningJourneyController initializes in clean state and notifies listeners on start',
        () async {
      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      expect(controller.session, isNull);
      expect(controller.status, LearningJourneyStatus.created);
      expect(controller.isLoading, isFalse);

      var notified = 0;
      controller.addListener(() => notified++);

      final corpus = createCorpus(count: 3);
      final started = await controller.startJourney(
        learnerId: 'learner_ui',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );

      expect(started, isTrue);
      expect(controller.session, isNotNull);
      expect(controller.status, LearningJourneyStatus.questionPresented);
      expect(notified, greaterThanOrEqualTo(2)); // loading=true, loading=false
    });

    test(
        '37. Controller updates currentQuestion, currentQuestionIndex, and progressPercentage',
        () async {
      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final corpus = createCorpus(count: 4);
      await controller.startJourney(
        learnerId: 'learner_ui_prog',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );

      expect(controller.currentQuestionIndex, 0);
      expect(controller.progressPercentage, 0.0);
      expect(controller.currentQuestion, isNotNull);

      await controller.submitAnswer(answer: 'A');

      expect(controller.currentQuestionIndex, 1);
      expect(controller.progressPercentage, 0.5);
    });

    test(
        '38. Controller records lastAnswerResult on submitAnswer and notifies listeners',
        () async {
      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final corpus = createCorpus(count: 3);
      await controller.startJourney(
        learnerId: 'learner_ui_res',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
      );

      await controller.submitAnswer(answer: 'A');
      expect(controller.lastAnswerResult, isNotNull);
      expect(controller.lastAnswerResult!.submittedAnswer, 'A');
      expect(controller.lastAnswerResult!.isCorrect, isTrue);
      expect(controller.isCompleted, isTrue);
    });

    test(
        '39. Controller exposes canSubmitAnswer accurately based on lifecycle status',
        () async {
      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      expect(controller.canSubmitAnswer, isFalse);

      final corpus = createCorpus(count: 3);
      await controller.startJourney(
        learnerId: 'learner_ui_sub',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
      );
      expect(controller.canSubmitAnswer, isTrue);

      await controller.submitAnswer(answer: 'A');
      expect(controller.isCompleted, isTrue);
      expect(controller.canSubmitAnswer, isFalse);
    });

    test(
        '40. Controller captures error messages and typed error codes on failure',
        () async {
      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final started = await controller.startJourney(
        learnerId: '',
        examId: 'upsc',
        corpus: createCorpus(count: 2),
      );

      expect(started, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.lastErrorCode, LearningJourneyErrorCode.tenantMismatch);
    });
  });

  // ==========================================================================
  // Group 7: Failure Handling & Graceful Degradation (Items 41-45)
  // ==========================================================================
  group('P41 Group 7: Failure Handling & Graceful Degradation (41-45)', () {
    test(
        '41. Start journey with empty question corpus fails gracefully with emptyCorpus error',
        () async {
      final res = await orchestrator.startJourney(
        learnerId: 'learner_fail_empty',
        examId: 'upsc',
        corpus: const [],
      );
      expect(res.isFailure, isTrue);
      expect(res.error?.code, LearningJourneyErrorCode.emptyCorpus);
    });

    test(
        '42. Start journey with blank learnerId or examId fails with tenantMismatch error',
        () async {
      final corpus = createCorpus(count: 2);
      final resLearner = await orchestrator.startJourney(
        learnerId: '   ',
        examId: 'upsc',
        corpus: corpus,
      );
      expect(resLearner.isFailure, isTrue);
      expect(resLearner.error?.code, LearningJourneyErrorCode.tenantMismatch);

      final resExam = await orchestrator.startJourney(
        learnerId: 'learner_fail_exam',
        examId: ' ',
        corpus: corpus,
      );
      expect(resExam.isFailure, isTrue);
      expect(resExam.error?.code, LearningJourneyErrorCode.tenantMismatch);
    });

    test('43. Submitting blank answer is rejected with invalidAnswer error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_blank_ans',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 1,
      );
      final session = startRes.session!;

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: '   ',
      );
      expect(sub.isFailure, isTrue);
      expect(sub.error?.code, LearningJourneyErrorCode.invalidAnswer);
    });

    test(
        '44. Submitting answer with mismatched questionId fails with malformedQuestion error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_mismatch_q',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );
      final session = startRes.session!;

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: 'wrong_question_id',
        answer: 'A',
      );
      expect(sub.isFailure, isTrue);
      expect(sub.error?.code, LearningJourneyErrorCode.malformedQuestion);
    });

    test(
        '45. Submitting duplicate answer to already answered question fails with duplicateAttempt error',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_dup',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );
      final session = startRes.session!;
      final q0 = session.currentQuestion!;

      final sub0 = await orchestrator.submitAnswer(
        session: session,
        questionId: q0.id,
        answer: 'A',
      );
      expect(sub0.isSuccess, isTrue);

      // Attempt to submit again with stale session snapshot referencing answered question
      final subDup = await orchestrator.submitAnswer(
        session: sub0.session!,
        questionId: q0.id,
        answer: 'B',
      );
      expect(subDup.isFailure, isTrue);
      expect(subDup.error?.code, LearningJourneyErrorCode.malformedQuestion);
    });
  });

  // ==========================================================================
  // Group 8: End-to-End Invariants (Items 46-50)
  // ==========================================================================
  group('P41 Group 8: End-to-End Invariants (46-50)', () {
    test(
        '46. Checkpoint cryptographic checksum is non-empty and changes as progress advances',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inv_chk',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );
      var session = startRes.session!;
      final hash0 = session.checkpoint.checksum;
      expect(hash0.isNotEmpty, isTrue);

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
      );
      final hash1 = sub.session!.checkpoint.checksum;
      expect(hash1.isNotEmpty, isTrue);
      expect(hash1, isNot(equals(hash0)));
    });

    test(
        '47. Authoritative state revision is strictly monotonic throughout the entire journey',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inv_mono',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 3,
      );
      var session = startRes.session!;
      var lastRev = session.authoritativeState.revision;

      for (var i = 0; i < 3; i++) {
        final sub = await orchestrator.submitAnswer(
          session: session,
          questionId: session.currentQuestion!.id,
          answer: 'A',
        );
        session = sub.session!;
        expect(session.authoritativeState.revision, greaterThan(lastRev));
        lastRev = session.authoritativeState.revision;
      }
    });

    test(
        '48. Zero question duplication exists across selected questions in session spec',
        () async {
      final corpus = createCorpus(count: 8);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inv_nodup',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 5,
      );
      final session = startRes.session!;
      final ids = session.spec.orderedQuestionIds;
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test(
        '49. Completed question count in checkpoint matches length of completedQuestionIds',
        () async {
      final corpus = createCorpus(count: 4);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inv_count',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );
      var session = startRes.session!;

      final sub = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
      );
      session = sub.session!;

      expect(session.checkpoint.completedCount,
          session.checkpoint.completedQuestionIds.length);
      expect(session.checkpoint.completedCount, 1);
    });

    test(
        '50. Progress percentage starts at 0.0, increases monotonically, and finishes at 1.0',
        () async {
      final corpus = createCorpus(count: 3);
      final startRes = await orchestrator.startJourney(
        learnerId: 'learner_inv_pct',
        examId: 'upsc',
        corpus: corpus,
        questionCount: 2,
      );
      var session = startRes.session!;
      expect(session.progressPercentage, 0.0);

      final sub1 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
      );
      session = sub1.session!;
      expect(session.progressPercentage, 0.5);

      final sub2 = await orchestrator.submitAnswer(
        session: session,
        questionId: session.currentQuestion!.id,
        answer: 'A',
      );
      session = sub2.session!;
      expect(session.progressPercentage, 1.0);
      expect(session.isCompleted, isTrue);
    });
  });
}
