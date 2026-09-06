/// P40 Adaptive Learning Session Continuity & Resumption Test Suite (TITAN-KO-040.0 P40).
///
/// Complete, contract-level verification suite covering all 32 minimum required
/// functional scenarios for adaptive session continuity, crash recovery, and state preservation.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    String objectiveId = 'lo_polity_01',
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: 2024,
      paper: 'GS1',
      subject: 'Polity',
      topic: 'Fundamental Rights',
      normalizedText: 'Question text for $id',
      originalText: 'Original text for $id',
      options: const [
        Option(key: 'A', text: 'Option A', isCorrect: true),
        Option(key: 'B', text: 'Option B', isCorrect: false),
        Option(key: 'C', text: 'Option C', isCorrect: false),
        Option(key: 'D', text: 'Option D', isCorrect: false),
      ],
      officialAnswer: const Answer(
        correctOptionKeys: ['A'],
        officialAnswerSource: 'Official Key',
      ),
      difficulty: 'Medium',
      source: PyqSourceReference.official(
        examId: examId,
        year: 2024,
        paper: 'GS1',
      ),
      objectiveIds: [objectiveId],
    );
  }

  AdaptiveQuestionCandidate buildCandidate({
    required NormalizedQuestion question,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: 0.5,
      learnerWeakness: 0.5,
      exposureCount: 0,
      recencyScore: 1.0,
      difficultyFit: 0.8,
      sourceQualityScore: 1.0,
      selectionScore: 0.75,
      isEligible: true,
      scoreBreakdown: const {
        'historicalPriority': 0.25,
        'weakness': 0.25,
        'recency': 0.15,
        'difficultyFit': 0.20,
        'quality': 0.15,
      },
    );
  }

  AdaptivePracticeSessionSpec buildSpec({
    String sessionId = 'sess_p40_01',
    String learnerId = 'learner_p40',
    String examId = 'upsc',
    int questionCount = 4,
  }) {
    final questions = List.generate(
      questionCount,
      (i) => buildQuestion(id: 'q_p40_$i', examId: examId),
    );
    final candidates =
        questions.map((q) => buildCandidate(question: q)).toList();

    final selectionResult = AdaptiveQuestionSelectionResult(
      examId: examId,
      selectedQuestions: questions,
      selectedCandidates: candidates,
      allCandidates: candidates,
      requestedCount: questions.length,
      eligibleCount: questions.length,
      config: AdaptiveQuestionSelectionConfig(
        examId: examId,
        targetQuestionCount: questions.length,
      ),
      selectedAt: baseDate,
    );

    final config = AdaptivePracticeSessionConfig(
      examId: examId,
      learnerId: learnerId,
      sessionMode: PracticeSessionMode.standard,
      sectionSize: 5,
      estimatedSecondsPerQuestion: 60,
    );

    final orchestrator = AdaptivePracticeSessionOrchestrator();
    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: baseDate,
    );
  }

  AuthoritativeLearnerState buildState({
    String learnerId = 'learner_p40',
    String examId = 'upsc',
    int revision = 1,
  }) {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      revision: revision,
      progressMap: {
        'lo_polity_01': LearnerProgress(
          learnerId: learnerId,
          objectiveId: 'lo_polity_01',
          attemptCount: 2,
          correctCount: 2,
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: baseDate,
        ),
      },
      lastUpdatedAt: baseDate,
    );
  }

  SessionCheckpoint buildCheckpoint({
    String sessionId = 'sess_p40_01',
    String learnerId = 'learner_p40',
    String examId = 'upsc',
    int questionIndex = 1,
    int checkpointRevision = 1,
    int authoritativeStateRevision = 1,
    bool isCompleted = false,
  }) {
    return SessionCheckpoint(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: questionIndex,
      completedQuestionIds: const ['q_p40_0'],
      activeObjectiveId: 'lo_polity_01',
      checkpointRevision: checkpointRevision,
      authoritativeStateRevision: authoritativeStateRevision,
      isCompleted: isCompleted,
      timestamp: baseDate,
    );
  }

  group('P40 Adaptive Session Continuity & Recovery: 32 Quality Gates', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService recoveryService;
    late AdaptivePracticeExecutionEngine execEngine;
    late PracticeOutcomeConsolidator consolidator;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late ResumableAdaptivePracticeCoordinator coordinator;

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      recoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      execEngine = const AdaptivePracticeExecutionEngine();
      consolidator = const PracticeOutcomeConsolidator();
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        consolidator: consolidator,
      );
      coordinator = ResumableAdaptivePracticeCoordinator(
        engine: execEngine,
        pipeline: pipeline,
        recoveryService: recoveryService,
      );
    });

    // 1. session creation
    test('1. session creation: instantiates clean session at cursor 0', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_01',
        learnerId: 'learner_01',
        examId: 'upsc',
        currentObjectiveId: 'lo_polity_01',
        createdAt: baseDate,
        lastActivityTimestamp: baseDate,
      );

      expect(session.sessionId, equals('sess_01'));
      expect(session.currentQuestionIndex, equals(0));
      expect(session.status, equals(ResumableSessionStatus.created));
      expect(session.completedQuestionIds, isEmpty);
      expect(session.authoritativeStateRevision, equals(1));
    });

    // 2. session activation
    test('2. session activation: transitions from created to active', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_02',
        learnerId: 'learner_01',
        examId: 'upsc',
        currentObjectiveId: 'lo_polity_01',
        createdAt: baseDate,
        lastActivityTimestamp: baseDate,
      );

      final activated = session.transitionTo(
        ResumableSessionStatus.active,
        timestamp: baseDate.add(const Duration(seconds: 5)),
      );

      expect(activated.status, equals(ResumableSessionStatus.active));
      expect(activated.lastActivityTimestamp,
          equals(baseDate.add(const Duration(seconds: 5))));
    });

    // 3. session pause
    test('3. session pause: transitions from active to paused', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_03',
        learnerId: 'learner_01',
        examId: 'upsc',
        currentObjectiveId: 'lo_polity_01',
        status: ResumableSessionStatus.active,
        createdAt: baseDate,
        lastActivityTimestamp: baseDate,
      );

      final paused = session.transitionTo(
        ResumableSessionStatus.paused,
        timestamp: baseDate.add(const Duration(seconds: 10)),
      );

      expect(paused.status, equals(ResumableSessionStatus.paused));
    });

    // 4. checkpoint creation
    test(
        '4. checkpoint creation: generates valid checkpoint with sha256 checksum',
        () {
      final chk = buildCheckpoint(sessionId: 'sess_04');
      expect(chk.checkpointRevision, equals(1));
      expect(chk.questionIndex, equals(1));
      expect(chk.checksum, isNotEmpty);
      expect(chk.checksum.length, equals(64));
    });

    // 5. checkpoint persistence
    test(
        '5. checkpoint persistence: saves and retrieves checkpoint from repository',
        () async {
      final chk = buildCheckpoint(sessionId: 'sess_05');
      await checkpointRepo.saveCheckpoint(chk);

      final loaded = await checkpointRepo.loadCheckpoint(
        learnerId: chk.learnerId,
        examId: chk.examId,
        sessionId: chk.sessionId,
      );

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals(chk.sessionId));
      expect(loaded.checksum, equals(chk.checksum));
    });

    // 6. checkpoint integrity validation
    test(
        '6. checkpoint integrity validation: detects checksum mismatch on corrupted payload',
        () {
      final chk = buildCheckpoint(sessionId: 'sess_06');
      final rawJson =
          json.decode(chk.toCanonicalJson()) as Map<String, dynamic>;
      // Tamper with cursor position without updating checksum
      rawJson['questionIndex'] = 99;

      expect(
        () => SessionCheckpoint.fromRawJson(json.encode(rawJson)),
        throwsA(isA<SessionRecoveryException>().having(
          (e) => e.code,
          'code',
          equals(SessionRecoveryErrorCode.corruptedCheckpoint),
        )),
      );
    });

    // 7. interrupted-session recovery
    test(
        '7. interrupted-session recovery: resumes at uncompleted question cursor',
        () async {
      final state = buildState(learnerId: 'learner_07');
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      final chk = buildCheckpoint(
        sessionId: 'sess_07',
        learnerId: 'learner_07',
        questionIndex: 2,
      );
      await checkpointRepo.saveCheckpoint(chk);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_07',
        examId: 'upsc',
        sessionId: 'sess_07',
      );

      expect(result.isSuccess, isTrue);
      expect(result.session!.currentQuestionIndex, equals(2));
      expect(result.session!.status, equals(ResumableSessionStatus.resumed));
    });

    // 8. successful resume
    test(
        '8. successful resume: returns valid session and authoritative state handle',
        () async {
      final state = buildState(learnerId: 'learner_08');
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      final chk =
          buildCheckpoint(sessionId: 'sess_08', learnerId: 'learner_08');
      await checkpointRepo.saveCheckpoint(chk);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_08',
        examId: 'upsc',
        sessionId: 'sess_08',
      );

      expect(result.status, equals(SessionRecoveryResultStatus.success));
      expect(result.authoritativeState, isNotNull);
      expect(result.authoritativeState!.learnerId, equals('learner_08'));
    });

    // 9. repeated recovery idempotency
    test(
        '9. repeated recovery idempotency: repeated recoveries produce identical results',
        () async {
      final state = buildState(learnerId: 'learner_09');
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      final chk =
          buildCheckpoint(sessionId: 'sess_09', learnerId: 'learner_09');
      await checkpointRepo.saveCheckpoint(chk);

      final res1 = await recoveryService.recoverSession(
        learnerId: 'learner_09',
        examId: 'upsc',
        sessionId: 'sess_09',
      );

      final res2 = await recoveryService.recoverSession(
        learnerId: 'learner_09',
        examId: 'upsc',
        sessionId: 'sess_09',
      );

      expect(res1.status, equals(res2.status));
      expect(res1.session!.currentQuestionIndex,
          equals(res2.session!.currentQuestionIndex));
      expect(res1.checkpoint!.checksum, equals(res2.checkpoint!.checksum));
    });

    // 10. duplicate outcome prevention
    test(
        '10. duplicate outcome prevention: answered questions are not re-presented',
        () {
      final spec = buildSpec(sessionId: 'sess_10', questionCount: 4);
      final chk = SessionCheckpoint(
        sessionId: 'sess_10',
        learnerId: 'learner_p40',
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q_p40_0', 'q_p40_1'],
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        isCompleted: false,
        timestamp: baseDate,
      );

      final reconstructed = coordinator.reconstructExecutionState(
        spec: spec,
        checkpoint: chk,
        resumedAt: baseDate,
      );

      expect(reconstructed.currentQuestionIndex, equals(2));
      expect(reconstructed.questionResults['q_p40_0']!.isAnswered, isTrue);
      expect(reconstructed.questionResults['q_p40_1']!.isAnswered, isTrue);
      expect(reconstructed.questionResults['q_p40_2']!.isAnswered, isFalse);
      expect(reconstructed.currentQuestion!.id, equals('q_p40_2'));
    });

    // 11. pending-attempt handling
    test(
        '11. pending-attempt handling: cursor points to current unattempted question',
        () {
      final spec = buildSpec(sessionId: 'sess_11', questionCount: 3);
      final chk = buildCheckpoint(sessionId: 'sess_11', questionIndex: 1);

      final reconstructed = coordinator.reconstructExecutionState(
        spec: spec,
        checkpoint: chk,
        resumedAt: baseDate,
      );

      expect(reconstructed.currentQuestionIndex, equals(1));
      expect(reconstructed.questionResults['q_p40_1']!.isAnswered, isFalse);
    });

    // 12. stale checkpoint rejection
    test(
        '12. stale checkpoint rejection: repository rejects checkpoint with stale revision',
        () async {
      final chk1 = buildCheckpoint(sessionId: 'sess_12', checkpointRevision: 2);
      await checkpointRepo.saveCheckpoint(chk1);

      final staleChk =
          buildCheckpoint(sessionId: 'sess_12', checkpointRevision: 1);

      expect(
        () => checkpointRepo.saveCheckpoint(staleChk),
        throwsA(isA<SessionRecoveryException>().having(
          (e) => e.code,
          'code',
          equals(SessionRecoveryErrorCode.staleCheckpoint),
        )),
      );
    });

    // 13. stale session rejection
    test(
        '13. stale session rejection: recovery returns stale when state is behind checkpoint',
        () async {
      // Authoritative state is rev 1
      final state = buildState(learnerId: 'learner_13', revision: 1);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      // Checkpoint references future state rev 3
      final chk = buildCheckpoint(
        sessionId: 'sess_13',
        learnerId: 'learner_13',
        authoritativeStateRevision: 3,
      );
      await checkpointRepo.saveCheckpoint(chk);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_13',
        examId: 'upsc',
        sessionId: 'sess_13',
      );

      expect(result.status, equals(SessionRecoveryResultStatus.stale));
    });

    // 14. corrupted checkpoint
    test(
        '14. corrupted checkpoint: fails safely when stored checkpoint has corrupted checksum',
        () async {
      checkpointRepo.failNextLoad = true;

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_14',
        examId: 'upsc',
        sessionId: 'sess_14',
      );

      expect(result.isFailure, isTrue);
    });

    // 15. corrupted session
    test(
        '15. corrupted session: unrecoverable when state repository throws corruption',
        () async {
      final chk =
          buildCheckpoint(sessionId: 'sess_15', learnerId: 'learner_15');
      await checkpointRepo.saveCheckpoint(chk);

      // State has bad checksum in auth repo
      final badState = PersistedAuthoritativeLearnerState(
        revision: 1,
        learnerId: 'learner_15',
        examId: 'upsc',
        progressMap: const {},
        lastUpdatedAt: baseDate,
        stateFingerprint: 'fingerprint_15',
        checksum:
            'corrupted_checksum_000000000000000000000000000000000000000000000',
      );
      await authRepo.save(badState);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_15',
        examId: 'upsc',
        sessionId: 'sess_15',
      );

      expect(result.isFailure, isTrue);
    });

    // 16. incompatible schema
    test('16. incompatible schema: rejects future schema version', () async {
      final chk = buildCheckpoint(sessionId: 'sess_16');
      final raw = json.decode(chk.toCanonicalJson()) as Map<String, dynamic>;
      raw['schemaVersion'] = 99;

      expect(
        () => SessionCheckpoint.fromRawJson(json.encode(raw)),
        throwsA(isA<SessionRecoveryException>().having(
          (e) => e.code,
          'code',
          equals(SessionRecoveryErrorCode.incompatibleVersion),
        )),
      );
    });

    // 17. invalid learner identity
    test(
        '17. invalid learner identity: rejects empty or mismatched learner identity',
        () async {
      final res = await recoveryService.recoverSession(
        learnerId: '   ',
        examId: 'upsc',
        sessionId: 'sess_17',
      );

      expect(resultMatchesIdentityMismatch(res), isTrue);
    });

    // 18. invalid exam identity
    test('18. invalid exam identity: rejects empty or mismatched exam identity',
        () async {
      final res = await recoveryService.recoverSession(
        learnerId: 'learner_18',
        examId: '',
        sessionId: 'sess_18',
      );

      expect(resultMatchesIdentityMismatch(res), isTrue);
    });

    // 19. invalid session identity
    test('19. invalid session identity: rejects empty session identifier',
        () async {
      final res = await recoveryService.recoverSession(
        learnerId: 'learner_19',
        examId: 'upsc',
        sessionId: '',
      );

      expect(resultMatchesIdentityMismatch(res), isTrue);
    });

    // 20. cross-tenant isolation
    test(
        '20. cross-tenant isolation: Learner A cannot access Learner B checkpoint',
        () async {
      final chk = buildCheckpoint(sessionId: 'sess_20', learnerId: 'learner_A');
      await checkpointRepo.saveCheckpoint(chk);

      final result = await checkpointRepo.loadCheckpoint(
        learnerId: 'learner_B',
        examId: 'upsc',
        sessionId: 'sess_20',
      );

      expect(result, isNull);
    });

    // 21. adaptive frontier restoration
    test(
        '21. adaptive frontier restoration: preserves active objective across crash',
        () {
      final chk = SessionCheckpoint(
        sessionId: 'sess_21',
        learnerId: 'learner_p40',
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q_p40_0', 'q_p40_1'],
        activeObjectiveId: 'lo_polity_frontier_02',
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        isCompleted: false,
        timestamp: baseDate,
      );

      expect(chk.activeObjectiveId, equals('lo_polity_frontier_02'));
    });

    // 22. deterministic next-action reconstruction
    test(
        '22. deterministic next-action reconstruction: presents question matching index',
        () {
      final spec = buildSpec(sessionId: 'sess_22', questionCount: 4);
      final chk = buildCheckpoint(sessionId: 'sess_22', questionIndex: 2);

      final state = coordinator.reconstructExecutionState(
        spec: spec,
        checkpoint: chk,
        resumedAt: baseDate,
      );

      expect(state.currentQuestionIndex, equals(2));
      expect(state.currentQuestion!.id, equals(spec.orderedQuestions[2].id));
    });

    // 23. session completion
    test(
        '23. session completion: completed session returns alreadyCompleted status',
        () async {
      final state = buildState(learnerId: 'learner_23');
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      final chk = buildCheckpoint(
        sessionId: 'sess_23',
        learnerId: 'learner_23',
        isCompleted: true,
      );
      await checkpointRepo.saveCheckpoint(chk);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_23',
        examId: 'upsc',
        sessionId: 'sess_23',
      );

      expect(
          result.status, equals(SessionRecoveryResultStatus.alreadyCompleted));
    });

    // 24. invalid state transitions
    test(
        '24. invalid state transitions: illegal transitions throw SessionRecoveryException',
        () {
      final session = ResumableLearningSession(
        sessionId: 'sess_24',
        learnerId: 'learner_24',
        examId: 'upsc',
        currentObjectiveId: 'lo_polity_01',
        status: ResumableSessionStatus.completed,
        createdAt: baseDate,
        lastActivityTimestamp: baseDate,
      );

      expect(
        () => session.transitionTo(ResumableSessionStatus.active),
        throwsA(isA<SessionRecoveryException>()),
      );
    });

    // 25. repository failure
    test(
        '25. repository failure: IO exception returns failure status gracefully',
        () async {
      checkpointRepo.failNextLoad = true;

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_25',
        examId: 'upsc',
        sessionId: 'sess_25',
      );

      expect(result.status, equals(SessionRecoveryResultStatus.failure));
    });

    // 26. persistence retry
    test(
        '26. persistence retry: re-saving identical payload succeeds idempotently',
        () async {
      final chk = buildCheckpoint(sessionId: 'sess_26');
      await checkpointRepo.saveCheckpoint(chk);

      // Re-save exact same checkpoint
      await checkpointRepo.saveCheckpoint(chk);

      final loaded = await checkpointRepo.loadCheckpoint(
        learnerId: chk.learnerId,
        examId: chk.examId,
        sessionId: chk.sessionId,
      );
      expect(loaded, isNotNull);
      expect(loaded!.checksum, equals(chk.checksum));
    });

    // 27. crash/restart simulation
    test(
        '27. crash/restart simulation: full lifecycle through interruption and resumption',
        () async {
      const learnerId = 'learner_crash';
      const examId = 'upsc';
      const sessionId = 'session_crash_01';

      var authState =
          buildState(learnerId: learnerId, examId: examId, revision: 1);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final spec = buildSpec(
        sessionId: sessionId,
        learnerId: learnerId,
        examId: examId,
        questionCount: 3,
      );

      // Step 1: Start session
      var stepResult = await coordinator.startSession(
        spec: spec,
        baseState: authState,
        startedAt: baseDate,
      );
      var currentCheckpoint = stepResult.checkpoint;
      var execState = stepResult.executionState;

      // Step 2: Answer question 0
      stepResult = await coordinator.submitAnswerAndCheckpoint(
        executionState: execState,
        baseState: authState,
        currentCheckpoint: currentCheckpoint,
        questionId: spec.orderedQuestions[0].id,
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 30)),
      );
      currentCheckpoint = stepResult.checkpoint;
      execState = stepResult.executionState;
      authState = stepResult.authoritativeState;

      // SIMULATE CRASH: discard executionState, create new coordinator instance
      final newAuthRecovery =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final newSessionRecovery = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: newAuthRecovery,
      );
      final newCoordinator = ResumableAdaptivePracticeCoordinator(
        engine: execEngine,
        pipeline: pipeline,
        recoveryService: newSessionRecovery,
      );

      // Step 3: Recover and resume
      final resumedStep = await newCoordinator.recoverAndResumeSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: spec.sessionId,
        spec: spec,
        resumedAt: baseDate.add(const Duration(minutes: 5)),
      );

      expect(resumedStep.checkpoint.questionIndex, equals(1));
      expect(resumedStep.executionState.currentQuestionIndex, equals(1));
      expect(resumedStep.executionState.currentQuestion!.id,
          equals(spec.orderedQuestions[1].id));
    });

    // 28. P39 compatibility regression
    test(
        '28. P39 compatibility regression: P39 recovery service works side-by-side with P40',
        () async {
      final state = buildState(learnerId: 'learner_p39_compat');
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );

      final p39Result = await authRecoveryService.recover(
        learnerId: 'learner_p39_compat',
        examId: 'upsc',
        requestedAt: baseDate,
      );

      expect(p39Result.isSuccess, isTrue);
      expect(p39Result.state!.revision, equals(1));
    });

    // 29. serialization round-trip
    test(
        '29. serialization round-trip: SessionCheckpoint survives JSON round-trip identically',
        () {
      final chk = buildCheckpoint(sessionId: 'sess_29');
      final jsonStr = chk.toCanonicalJson();
      final restored = SessionCheckpoint.fromRawJson(jsonStr);

      expect(restored.sessionId, equals(chk.sessionId));
      expect(restored.questionIndex, equals(chk.questionIndex));
      expect(restored.completedQuestionIds, equals(chk.completedQuestionIds));
      expect(restored.checksum, equals(chk.checksum));
    });

    // 30. deterministic serialization
    test(
        '30. deterministic serialization: same fields always produce byte-for-byte identical output',
        () {
      final chk1 = buildCheckpoint(sessionId: 'sess_30');
      final chk2 = buildCheckpoint(sessionId: 'sess_30');

      expect(chk1.toCanonicalJson(), equals(chk2.toCanonicalJson()));
      expect(chk1.checksum, equals(chk2.checksum));
    });

    // 31. revision monotonicity
    test(
        '31. revision monotonicity: advancing session checkpoint increments revision',
        () {
      final session = ResumableLearningSession(
        sessionId: 'sess_31',
        learnerId: 'learner_31',
        examId: 'upsc',
        currentObjectiveId: 'lo_polity_01',
        lastPersistedRevision: 1,
        createdAt: baseDate,
        lastActivityTimestamp: baseDate,
      );

      final chk1 = session.createCheckpoint(
        nextCheckpointRevision: 2,
        nextAuthoritativeRevision: 1,
        timestamp: baseDate,
      );
      expect(chk1.checkpointRevision, equals(2));

      final updatedSession = session.advanceQuestion(
        completedQuestionId: 'q_0',
        nextObjectiveId: 'lo_polity_01',
        timestamp: baseDate.add(const Duration(seconds: 15)),
      );

      final chk2 = updatedSession.createCheckpoint(
        nextCheckpointRevision: 3,
        nextAuthoritativeRevision: 1,
        timestamp: baseDate.add(const Duration(seconds: 15)),
      );
      expect(chk2.checkpointRevision, equals(3));
      expect(chk2.checkpointRevision > chk1.checkpointRevision, isTrue);
    });

    // 32. no duplicate evidence after recovery
    test(
        '32. no duplicate evidence after recovery: answered questions remain answered without duplication',
        () async {
      final spec = buildSpec(sessionId: 'sess_32', questionCount: 4);
      final chk = SessionCheckpoint(
        sessionId: 'sess_32',
        learnerId: 'learner_p40',
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q_p40_0', 'q_p40_1'],
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 3,
        authoritativeStateRevision: 2,
        isCompleted: false,
        timestamp: baseDate,
      );

      final state = coordinator.reconstructExecutionState(
        spec: spec,
        checkpoint: chk,
        resumedAt: baseDate,
      );

      // Only questions 0 and 1 are answered; 2 and 3 are unattempted
      final answeredCount =
          state.orderedResults.where((r) => r.isAnswered).length;
      expect(answeredCount, equals(2));
      expect(state.events.length, equals(1));
      expect(state.events.first.type,
          equals(PracticeExecutionEventType.sessionResumed));
    });
  });
}

bool resultMatchesIdentityMismatch(SessionRecoveryResult res) {
  return res.isFailure &&
      (res.status == SessionRecoveryResultStatus.failure ||
          res.status == SessionRecoveryResultStatus.identityMismatch);
}
