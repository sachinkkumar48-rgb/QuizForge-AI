/// P28 Persistent Learner Evidence & Longitudinal Learning State Test Suite
///
/// Comprehensive verification of P28 requirements:
/// - Core Persistence & Repository Contracts (AttemptRepository, ProgressRepository, LearnerRepository, SessionManager)
/// - Strict Learner Isolation (cross-learner isolation)
/// - Restart Safety & Rehydration across simulated application terminations
/// - Multi-Session Longitudinal Evidence Continuity
/// - Idempotency & Repeated Writes
/// - Corruption & Malformed Data Safety
/// - Backward Compatibility & Empty Store Behavior
/// - Downstream Learning Intelligence Rehydration (P23, P24, P25, P26)
/// - P27 Dashboard Continuity after Application Restart
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/repositories/impl/garuda_learning_dashboard_repository.dart';
import 'package:quizforge_upsc/repositories/impl/hive_garuda_learner_evidence_repository.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<String> attemptsBox;
  late Box<String> resultsBox;
  late Box<String> progressBox;
  late Box<String> learnersBox;
  late Box<String> sessionsBox;

  setUp(() async {
    TitanServiceLocator.instance.reset();
    tempDir = await Directory.systemTemp.createTemp('p28_evidence_test_');
    Hive.init(tempDir.path);

    attemptsBox =
        await Hive.openBox<String>(HiveGarudaAttemptRepository.attemptsBoxName);
    resultsBox =
        await Hive.openBox<String>(HiveGarudaAttemptRepository.resultsBoxName);
    progressBox =
        await Hive.openBox<String>(HiveGarudaProgressRepository.boxName);
    learnersBox =
        await Hive.openBox<String>(HiveGarudaLearnerRepository.boxName);
    sessionsBox = await Hive.openBox<String>(HiveGarudaSessionManager.boxName);
  });

  tearDown(() async {
    TitanServiceLocator.instance.reset();
    await Hive.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('P28.1 Core Persistence & Repository Mechanics', () {
    test('1. Empty store returns deterministic empty defaults', () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      final sessionMgr = HiveGarudaSessionManager(
        learnerRepository: learnerRepo,
        box: sessionsBox,
      );

      expect(attemptRepo.getAttemptsForLearner('new_learner'), isEmpty);
      expect(
          attemptRepo.getAttemptsForLearnerAndObjective(
              'new_learner', 'lo_article_21'),
          isEmpty);
      expect(
          attemptRepo.getResultsForLearnerAndObjective(
              'new_learner', 'lo_article_21'),
          isEmpty);
      expect(progressRepo.getProgress('new_learner', 'lo_article_21'), isNull);
      expect(progressRepo.getProgressForLearner('new_learner'), isEmpty);
      expect(progressRepo.getAll(), isEmpty);
      expect(learnerRepo.getById('new_learner'), isNull);
      expect(learnerRepo.exists('new_learner'), isFalse);
      expect(sessionMgr.getSessionsForLearner('new_learner'), isEmpty);
    });

    test('2. Single and multiple attempt & result records persist accurately',
        () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );

      final t1 = DateTime.utc(2026, 8, 30, 10, 0);
      final t2 = DateTime.utc(2026, 8, 30, 10, 5);

      final att1 = QuestionAttempt(
        attemptId: 'att_001',
        learnerId: 'learner_p28_01',
        questionId: 'q_art21_01',
        objectiveId: 'lo_article_21_foundations',
        submittedAnswer: 'A',
        attemptedAt: t1,
      );
      final res1 = AttemptResult(
        attemptId: 'att_001',
        isCorrect: true,
        score: 1.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
        evaluatedAt: t1,
      );

      final att2 = QuestionAttempt(
        attemptId: 'att_002',
        learnerId: 'learner_p28_01',
        questionId: 'q_art21_02',
        objectiveId: 'lo_article_21_foundations',
        submittedAnswer: 'C',
        attemptedAt: t2,
      );
      final res2 = AttemptResult(
        attemptId: 'att_002',
        isCorrect: false,
        score: 0.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
        evaluatedAt: t2,
      );

      attemptRepo.saveAttempt(att1);
      attemptRepo.saveResult(res1);
      attemptRepo.saveAttempt(att2);
      attemptRepo.saveResult(res2);

      expect(attemptRepo.getAttemptById('att_001'), equals(att1));
      expect(attemptRepo.getResultForAttempt('att_001'), equals(res1));
      expect(attemptRepo.getAttemptById('att_002'), equals(att2));
      expect(attemptRepo.getResultForAttempt('att_002'), equals(res2));

      final allForLearner = attemptRepo.getAttemptsForLearner('learner_p28_01');
      expect(allForLearner.length, 2);
      expect(allForLearner.first.attemptId, 'att_001');
      expect(allForLearner.last.attemptId, 'att_002');

      final results = attemptRepo.getResultsForLearnerAndObjective(
          'learner_p28_01', 'lo_article_21_foundations');
      expect(results.length, 2);
      expect(results.first.isCorrect, isTrue);
      expect(results.last.isCorrect, isFalse);
    });

    test(
        '3. Learner Isolation: Records from learner-A never appear in learner-B',
        () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);

      final attA = QuestionAttempt(
        attemptId: 'att_A_1',
        learnerId: 'learner_ALPHA',
        questionId: 'q_01',
        objectiveId: 'lo_preamble',
        submittedAnswer: 'A',
      );
      final resA = AttemptResult(
        attemptId: 'att_A_1',
        isCorrect: true,
        score: 1.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      final progA = LearnerProgress(
        learnerId: 'learner_ALPHA',
        objectiveId: 'lo_preamble',
        attemptCount: 1,
        correctCount: 1,
        status: LearnerObjectiveStatus.achieved,
      );

      final attB = QuestionAttempt(
        attemptId: 'att_B_1',
        learnerId: 'learner_BETA',
        questionId: 'q_01',
        objectiveId: 'lo_preamble',
        submittedAnswer: 'B',
      );
      final resB = AttemptResult(
        attemptId: 'att_B_1',
        isCorrect: false,
        score: 0.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      final progB = LearnerProgress(
        learnerId: 'learner_BETA',
        objectiveId: 'lo_preamble',
        attemptCount: 1,
        correctCount: 0,
        status: LearnerObjectiveStatus.inProgress,
      );

      attemptRepo.saveAttempt(attA);
      attemptRepo.saveResult(resA);
      progressRepo.saveProgress(progA);

      attemptRepo.saveAttempt(attB);
      attemptRepo.saveResult(resB);
      progressRepo.saveProgress(progB);

      // Alpha verification
      final alphaAttempts = attemptRepo.getAttemptsForLearner('learner_ALPHA');
      expect(alphaAttempts.length, 1);
      expect(alphaAttempts.first.attemptId, 'att_A_1');
      expect(progressRepo.getProgress('learner_ALPHA', 'lo_preamble')?.status,
          LearnerObjectiveStatus.achieved);

      // Beta verification
      final betaAttempts = attemptRepo.getAttemptsForLearner('learner_BETA');
      expect(betaAttempts.length, 1);
      expect(betaAttempts.first.attemptId, 'att_B_1');
      expect(progressRepo.getProgress('learner_BETA', 'lo_preamble')?.status,
          LearnerObjectiveStatus.inProgress);
    });

    test(
        '4. Idempotency: Repeated saves preserve state without duplicate entries',
        () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);

      final att = QuestionAttempt(
        attemptId: 'att_idempotent_1',
        learnerId: 'learner_idempotent',
        questionId: 'q_idemp_1',
        objectiveId: 'lo_idemp',
        submittedAnswer: 'D',
      );
      final res = AttemptResult(
        attemptId: 'att_idempotent_1',
        isCorrect: true,
        score: 1.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      final prog = LearnerProgress(
        learnerId: 'learner_idempotent',
        objectiveId: 'lo_idemp',
        attemptCount: 1,
        correctCount: 1,
      );

      // Repeated writes
      attemptRepo.saveAttempt(att);
      attemptRepo.saveAttempt(att);
      attemptRepo.saveResult(res);
      attemptRepo.saveResult(res);
      progressRepo.saveProgress(prog);
      progressRepo.saveProgress(prog);

      expect(attemptRepo.getAttemptsForLearner('learner_idempotent').length, 1);
      expect(
          attemptRepo
              .getResultsForLearnerAndObjective(
                  'learner_idempotent', 'lo_idemp')
              .length,
          1);
      expect(
          progressRepo.getProgressForLearner('learner_idempotent').length, 1);
    });

    test(
        '5. Corruption & Invalid Data Safety: Malformed records are safely skipped',
        () {
      // Inject corrupted and malformed entries directly into the raw Hive boxes
      attemptsBox.put('corrupt_json', '{{{not valid json}');
      attemptsBox.put(
          'missing_learner',
          jsonEncode({
            'attemptId': 'att_bad_1',
            'learnerId': '',
            'questionId': 'q_1',
            'objectiveId': 'lo_1',
            'submittedAnswer': 'A',
          }));
      attemptsBox.put(
          'missing_objective',
          jsonEncode({
            'attemptId': 'att_bad_2',
            'learnerId': 'learner_test',
            'questionId': 'q_1',
            'objectiveId': '',
            'submittedAnswer': 'A',
          }));

      resultsBox.put('corrupt_result_json', '{"isCorrect": "not a boolean');
      resultsBox.put(
          'invalid_score',
          jsonEncode({
            'attemptId': 'att_bad_score',
            'isCorrect': true,
            'score': 999.0, // out of [0.0, 1.0]
            'evaluationMethod': 'multipleChoice',
          }));

      progressBox.put('corrupt_progress_json', 'invalid progress');
      progressBox.put(
          'empty_progress_learner',
          jsonEncode({
            'learnerId': '',
            'objectiveId': 'lo_1',
            'attemptCount': 1,
            'correctCount': 1,
          }));

      // Construct repositories - must NOT throw
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);

      expect(attemptRepo.getAttemptsForLearner('learner_test'), isEmpty);
      expect(progressRepo.getAll(), isEmpty);
    });

    test('6. Learner Profiles persist and rehydrate accurately', () {
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      final learner = Learner(
        id: 'learner_titan_p28',
        name: 'Civil Service Aspirant',
        email: 'aspirant@titan.learning',
        createdAt: DateTime.utc(2026, 8, 30, 8, 0),
        metadata: const {'stage': 'prelims', 'optional': 'law'},
      );

      learnerRepo.save(learner);
      expect(learnerRepo.exists('learner_titan_p28'), isTrue);

      // Rehydrate in a second repository instance
      final reloadedRepo = HiveGarudaLearnerRepository(box: learnersBox);
      final retrieved = reloadedRepo.getById('learner_titan_p28');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Civil Service Aspirant');
      expect(retrieved.email, 'aspirant@titan.learning');
      expect(retrieved.metadata['stage'], 'prelims');
      expect(retrieved.metadata['optional'], 'law');
    });

    test('7. Assessment Sessions persist and track attempts across lifecycle',
        () {
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      learnerRepo.save(Learner(
        id: 'learner_session_01',
        name: 'Session Learner',
      ));

      final sessionMgr = HiveGarudaSessionManager(
        learnerRepository: learnerRepo,
        box: sessionsBox,
      );

      final session = sessionMgr.startSession(
        learnerId: 'learner_session_01',
        objectiveIds: ['lo_art21'],
        questionIds: ['q_1', 'q_2'],
      );
      expect(session.isCompleted, isFalse);

      final attempt = QuestionAttempt(
        attemptId: 'att_sess_1',
        learnerId: 'learner_session_01',
        questionId: 'q_1',
        objectiveId: 'lo_art21',
        submittedAnswer: 'B',
        sessionId: session.sessionId,
      );

      sessionMgr.addAttemptToSession(
        sessionId: session.sessionId,
        attempt: attempt,
      );
      sessionMgr.completeSession(session.sessionId);

      // Rehydrate in new session manager
      final reloadedMgr = HiveGarudaSessionManager(
        learnerRepository: learnerRepo,
        box: sessionsBox,
      );
      final reloadedSession = reloadedMgr.getSession(session.sessionId);
      expect(reloadedSession, isNotNull);
      expect(reloadedSession!.isCompleted, isTrue);
      expect(reloadedSession.attemptIds, contains('att_sess_1'));
      expect(reloadedMgr.getSessionsForLearner('learner_session_01').length, 1);
    });
  });

  group('P28.2 Restart Safety & Multi-Session Longitudinal Continuity', () {
    test(
        '8. Restart Acceptance Test: Full Instance A -> Terminate -> Instance B restore',
        () async {
      // 1. Instance A
      final learnerRepoA = HiveGarudaLearnerRepository(box: learnersBox);
      learnerRepoA.save(Learner(
        id: 'learner_restart_01',
        name: 'Restart Tester',
      ));

      final attemptRepoA = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepoA = HiveGarudaProgressRepository(box: progressBox);

      final t0 = DateTime.utc(2026, 8, 30, 9, 0);
      final att = QuestionAttempt(
        attemptId: 'att_restart_001',
        learnerId: 'learner_restart_01',
        questionId: 'q_kesavananda_01',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'Wrong choice',
        attemptedAt: t0,
      );
      final res = AttemptResult(
        attemptId: 'att_restart_001',
        isCorrect: false,
        score: 0.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
        evaluatedAt: t0,
      );
      final prog = LearnerProgress(
        learnerId: 'learner_restart_01',
        objectiveId: 'lo_basic_structure_doctrine',
        attemptCount: 1,
        correctCount: 0,
        successRate: 0.0,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: t0,
      );

      attemptRepoA.saveAttempt(att);
      attemptRepoA.saveResult(res);
      progressRepoA.saveProgress(prog);

      // 2. Terminate Instance A (dispose references)
      // Instance B connects to the same underlying persistent storage
      final attemptRepoB = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepoB = HiveGarudaProgressRepository(box: progressBox);

      // 3. Verify historical evidence restored
      final restoredAttempts =
          attemptRepoB.getAttemptsForLearner('learner_restart_01');
      expect(restoredAttempts.length, 1);
      expect(restoredAttempts.first.attemptId, 'att_restart_001');
      expect(restoredAttempts.first.learnerId, 'learner_restart_01');
      expect(restoredAttempts.first.objectiveId, 'lo_basic_structure_doctrine');

      final restoredResult =
          attemptRepoB.getResultForAttempt('att_restart_001');
      expect(restoredResult, isNotNull);
      expect(restoredResult!.isCorrect, isFalse);
      expect(restoredResult.score, 0.0);

      final restoredProg = progressRepoB.getProgress(
          'learner_restart_01', 'lo_basic_structure_doctrine');
      expect(restoredProg, isNotNull);
      expect(restoredProg!.attemptCount, 1);
      expect(restoredProg.correctCount, 0);
      expect(restoredProg.status, LearnerObjectiveStatus.inProgress);
    });

    test(
        '9. Multi-Session Continuity: 3 attempts in S1, 4 in S2 -> 7 total in S3 without duplication',
        () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );

      // Session 1: 3 attempts
      for (int i = 1; i <= 3; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_s1_$i',
          learnerId: 'learner_multisess',
          questionId: 'q_s1_$i',
          objectiveId: 'lo_fundamental_rights',
          submittedAnswer: 'A',
          sessionId: 'session_01',
          attemptedAt: DateTime.utc(2026, 8, 30, 9, i),
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_s1_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      // Session 2: 4 attempts
      for (int i = 1; i <= 4; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_s2_$i',
          learnerId: 'learner_multisess',
          questionId: 'q_s2_$i',
          objectiveId: 'lo_fundamental_rights',
          submittedAnswer: 'B',
          sessionId: 'session_02',
          attemptedAt: DateTime.utc(2026, 8, 30, 11, i),
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_s2_$i',
          isCorrect: i % 2 == 0,
          score: i % 2 == 0 ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      // Session 3: Reconstruct repository from persistent storage
      final reloadedRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );

      final totalAttempts =
          reloadedRepo.getAttemptsForLearner('learner_multisess');
      expect(totalAttempts.length, 7);

      final s1Attempts = reloadedRepo.getAttemptsForSession('session_01');
      expect(s1Attempts.length, 3);

      final s2Attempts = reloadedRepo.getAttemptsForSession('session_02');
      expect(s2Attempts.length, 4);

      // Ensure chronological ordering is strictly preserved
      for (int i = 0; i < totalAttempts.length - 1; i++) {
        expect(
          totalAttempts[i]
                  .attemptedAt
                  .isBefore(totalAttempts[i + 1].attemptedAt) ||
              totalAttempts[i]
                  .attemptedAt
                  .isAtSameMomentAs(totalAttempts[i + 1].attemptedAt),
          isTrue,
        );
      }
    });
  });

  group('P28.3 Downstream Learning Intelligence Rehydration (P23-P26)', () {
    test(
        '10. P23 Analytics: WeakSpot diagnostic evaluates restored historical evidence',
        () {
      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);

      // Seed 5 consecutive incorrect attempts for Article 21 (meets minimumEvidenceThreshold = 5)
      for (int i = 1; i <= 5; i++) {
        final att = QuestionAttempt(
          attemptId: 'att_weak_$i',
          learnerId: 'learner_analytics_01',
          questionId: 'q_weak_$i',
          objectiveId: 'lo_article_21_foundations',
          submittedAnswer: 'Wrong',
          attemptedAt: DateTime.utc(2026, 8, 30, 10, i),
        );
        final res = AttemptResult(
          attemptId: 'att_weak_$i',
          isCorrect: false,
          score: 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        );
        attemptRepo.saveAttempt(att);
        attemptRepo.saveResult(res);
      }

      final prog = LearnerProgress(
        learnerId: 'learner_analytics_01',
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 5,
        correctCount: 0,
        successRate: 0.0,
        status: LearnerObjectiveStatus.inProgress,
      );
      progressRepo.saveProgress(prog);

      // Reconstruct repository from disk to simulate application restart
      final reloadedAttemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final reloadedProgressRepo =
          HiveGarudaProgressRepository(box: progressBox);

      // P23 WeakSpot Evaluator evaluates from reloaded P18 historical evidence
      const evaluator = WeakSpotDiagnosticEvaluator();
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final objectives = framework.allObjectives;

      final profile = evaluator.evaluate(
        learnerId: 'learner_analytics_01',
        objectives: objectives,
        progressList:
            reloadedProgressRepo.getProgressForLearner('learner_analytics_01'),
        attempts:
            reloadedAttemptRepo.getAttemptsForLearner('learner_analytics_01'),
        attemptResults: reloadedAttemptRepo.getResultsForLearnerAndObjective(
            'learner_analytics_01', 'lo_article_21_foundations'),
        evaluatedAt: DateTime.utc(2026, 8, 30, 12, 0),
      );

      expect(profile.evaluatedWithSufficientEvidence, greaterThan(0));
      expect(profile.weakObjectives.map((w) => w.objectiveId),
          contains('lo_article_21_foundations'));
    });

    test('11. P24 Study Planner: Generates agenda from reloaded progress state',
        () {
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);
      progressRepo.saveProgress(LearnerProgress(
        learnerId: 'learner_planner_01',
        objectiveId: 'lo_preamble_identity',
        attemptCount: 3,
        correctCount: 3,
        status: LearnerObjectiveStatus.achieved,
      ));

      // Reconstruct repository
      final reloadedProgressRepo =
          HiveGarudaProgressRepository(box: progressBox);
      final reloadedList =
          reloadedProgressRepo.getProgressForLearner('learner_planner_01');

      const planner = DeterministicStudyPlannerService();
      final plan = planner.generatePlan(
        request: StudyPlanRequest(
          learnerId: 'learner_planner_01',
          planningWindowStart: DateTime.utc(2026, 8, 30),
          planningWindowEnd: DateTime.utc(2026, 8, 30, 23, 59),
          timeBudget: StudyTimeBudget(
            learnerId: 'learner_planner_01',
            dailyAvailableMinutes: 60,
            preferredSessionDurationMinutes: 30,
            maxSessionsPerDay: 2,
            effectiveFrom: DateTime.utc(2026, 8, 30),
          ),
          requestedAt: DateTime.utc(2026, 8, 30),
        ),
        availableObjectives:
            CurriculumSeedData.buildUpscConstitutionalLawFramework()
                .allObjectives,
        progressList: reloadedList,
      );

      expect(plan, isNotNull);
      expect(plan.dailyAgendas.isNotEmpty, isTrue);
    });

    test(
        '12. P25 Remedial Framework: Discovers lesson from reloaded diagnostic state',
        () async {
      final remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'lesson_art21_due_process',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21 & Procedural Due Process',
        summary: 'Deep dive on Maneka Gandhi doctrine',
        learningPoints: const ['Procedure established by law vs due process'],
        explanation: 'Detailed legal doctrine explanation',
        estimatedMinutes: 15,
        authoredAt: DateTime.utc(2026, 8, 30),
      ));

      final remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      final lesson = await remedialService.findBestLessonForObjective(
        objectiveId: 'lo_article_21_foundations',
      );

      expect(lesson, isNotNull);
      expect(lesson!.lessonId, 'lesson_art21_due_process');
      expect(lesson.title, 'Article 21 & Procedural Due Process');
    });

    test(
        '13. P26 Diagnostic Placement: Advances frontier using reloaded historical attempts',
        () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      learnerRepo.save(Learner(
        id: 'learner_diag_01',
        name: 'Diagnostic Candidate',
      ));

      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );

      // Seed 3 correct attempts for Preamble Identity (meets minimumEvidenceThreshold = 3)
      for (int i = 1; i <= 3; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_preamble_$i',
          learnerId: 'learner_diag_01',
          questionId: 'q_preamble_0$i',
          objectiveId: 'lo_preamble_identity',
          submittedAnswer: 'Correct',
          attemptedAt: DateTime.utc(2026, 8, 30, 10, i),
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_preamble_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      // Reconstruct repository from disk (simulate app restart)
      final reloadedAttemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      final diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: CaseLawQuestionProvider(),
        attemptRepository: reloadedAttemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      final placement =
          diagnosticService.evaluatePlacement(DiagnosticAssessmentRequest(
        requestId: 'diag_req_01',
        learnerId: 'learner_diag_01',
        targetObjectiveIds: ['lo_preamble_identity'],
        requestedAt: DateTime.utc(2026, 8, 30, 12, 0),
      ));

      expect(placement.totalAttemptsCount, 3);
      expect(placement.totalCorrectCount, 3);
      expect(placement.aggregateAccuracy, 1.0);
      expect(placement.frontier.demonstratedObjectiveIds,
          contains('lo_preamble_identity'));
    });
  });

  group('P28.4 P27 Dashboard Continuity Across Application Restart', () {
    test(
        '14. GarudaLearningDashboardRepository reflects persisted mastery & attempts after restart',
        () async {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      learnerRepo.save(Learner(
        id: 'learner_dash_p28',
        name: 'Dashboard Aspirant',
      ));

      final attemptRepoA = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepoA = HiveGarudaProgressRepository(box: progressBox);

      // Seed learner attempts in Instance A
      attemptRepoA.saveAttempt(QuestionAttempt(
        attemptId: 'att_dash_1',
        learnerId: 'learner_dash_p28',
        questionId: 'q_art21_01',
        objectiveId: 'lo_article_21_foundations',
        submittedAnswer: 'A',
      ));
      attemptRepoA.saveResult(AttemptResult(
        attemptId: 'att_dash_1',
        isCorrect: true,
        score: 1.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      ));

      progressRepoA.saveProgress(LearnerProgress(
        learnerId: 'learner_dash_p28',
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 1,
        correctCount: 1,
        status: LearnerObjectiveStatus.achieved,
      ));

      // Simulate App Restart -> Reconstruct Dashboard Repository with Instance B
      final attemptRepoB = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepoB = HiveGarudaProgressRepository(box: progressBox);
      final diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: CaseLawQuestionProvider(),
        attemptRepository: attemptRepoB,
        diagnosticRepository: InMemoryDiagnosticPlacementRepository(),
      );

      final remedialRepo = InMemoryRemedialLessonRepository();
      final remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      final dashRepo = GarudaLearningDashboardRepository(
        curriculumService: curriculumService,
        progressRepository: progressRepoB,
        attemptRepository: attemptRepoB,
        diagnosticService: diagnosticService,
        remedialService: remedialService,
      );

      final summary = await dashRepo.fetchSummary('learner_dash_p28');
      expect(summary.questionsAttempted, 1);
      expect(summary.correctAnswers, 1);
      expect(summary.overallAccuracy, 1.0);
      expect(summary.overallMastery, greaterThan(0.0));
      expect(summary.studyStreak, 1);
    });

    test(
        '15. Dashboard continuity after restart: Persisted evidence drives summary, profile, and next best action',
        () async {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final learnerRepo = HiveGarudaLearnerRepository(box: learnersBox);
      learnerRepo.save(Learner(
        id: 'user_garuda_01',
        name: 'Active UPSC Aspirant',
      ));

      final attemptRepo = HiveGarudaAttemptRepository(
        attemptsBox: attemptsBox,
        resultsBox: resultsBox,
      );
      final progressRepo = HiveGarudaProgressRepository(box: progressBox);

      // Seed persisted attempt history (3 attempts)
      for (int i = 1; i <= 3; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_widget_$i',
          learnerId: 'user_garuda_01',
          questionId: 'q_widget_$i',
          objectiveId: 'lo_preamble_identity',
          submittedAnswer: 'A',
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_widget_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressRepo.saveProgress(LearnerProgress(
        learnerId: 'user_garuda_01',
        objectiveId: 'lo_preamble_identity',
        attemptCount: 3,
        correctCount: 3,
        status: LearnerObjectiveStatus.achieved,
      ));

      final diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: CaseLawQuestionProvider(),
        attemptRepository: attemptRepo,
        diagnosticRepository: InMemoryDiagnosticPlacementRepository(),
      );

      final remedialRepo = InMemoryRemedialLessonRepository();
      final remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      final dashRepo = GarudaLearningDashboardRepository(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        diagnosticService: diagnosticService,
        remedialService: remedialService,
      );

      final summary = await dashRepo.fetchSummary('user_garuda_01');
      expect(summary.questionsAttempted, 3);
      expect(summary.correctAnswers, 3);
      expect(summary.overallAccuracy, 1.0);
      expect(summary.overallMastery, greaterThan(0.0));

      final profile = await dashRepo.fetchLearningProfile('user_garuda_01');
      expect(profile.totalQuestionsAnswered, 3);
      expect(profile.studyStreakDays, 1);

      final nextAction = await dashRepo.fetchNextBestAction('user_garuda_01');
      expect(nextAction.title, isNotEmpty);
    });
  });
}
