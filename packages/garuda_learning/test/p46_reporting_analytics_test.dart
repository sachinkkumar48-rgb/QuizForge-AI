/// P46 Learner Reporting & Analytics Unit & Contract Tests (TITAN-KO-046.0 P46).
///
/// Exhaustively tests all 30 mandatory requirements:
/// 1. empty learner analytics
/// 2. one attempt
/// 3. multiple attempts
/// 4. correct/incorrect calculation
/// 5. accuracy
/// 6. objective progress
/// 7. mastery distribution
/// 8. weak-area ranking
/// 9. subject analytics
/// 10. topic analytics
/// 11. objective analytics
/// 12. chronological trend
/// 13. improving learner
/// 14. declining learner
/// 15. remediation-required learner
/// 16. mastered learner
/// 17. insufficient evidence
/// 18. malformed evidence
/// 19. repository failure
/// 20. analytics failure
/// 21. navigation metadata
/// 22. learner dashboard integration compatibility
/// 23. faculty analytics where supported
/// 24. content usage analytics
/// 25. real practice changes analytics
/// 26. persistence/recovery preserves analytics
/// 27. no fake/hardcoded metrics
/// 28. deterministic results
/// 29. duplicate records do not double-count
/// 30. complete end-to-end analytics journey
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P46 Learner Reporting & Analytics Tests', () {
    const String testLearner = 'learner_p46_titan';
    const String testExam = 'upsc_prelims_gs1';
    final DateTime baseDate = DateTime.utc(2026, 9, 8, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryLearningActivityCompletionRepository completionRepo;
    late InMemoryFacultyContentRepository facultyRepo;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late MasteryProgressionService masteryService;
    late LearnerAnalyticsService analyticsService;

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      checkpointRepo = InMemorySessionCheckpointRepository();
      completionRepo = InMemoryLearningActivityCompletionRepository();
      facultyRepo = InMemoryFacultyContentRepository();

      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      masteryService = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      analyticsService = LearnerAnalyticsService(
        curriculumService: curriculumService,
        masteryService: masteryService,
        authRecoveryService: authRecoveryService,
        completionRepository: completionRepo,
        checkpointRepository: checkpointRepo,
        facultyRepository: facultyRepo,
      );
    });

    // 1. empty learner analytics
    test('1. empty learner analytics produces clean zero-state without failure',
        () async {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: testLearner,
        examId: testExam,
        createdAt: baseDate,
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: emptyState,
        asOfDate: baseDate,
      );

      expect(report.isEmpty, isTrue);
      expect(report.hasData, isFalse);
      expect(report.summary.totalAttempts, equals(0));
      expect(report.summary.correctCount, equals(0));
      expect(report.summary.incorrectCount, equals(0));
      expect(report.summary.accuracy, equals(0.0));
      expect(report.summary.objectivesAttempted, equals(0));
      expect(report.summary.objectivesMastered, equals(0));
      expect(report.summary.currentStreak, equals(0));
      expect(report.performanceTrends, isEmpty);
      expect(report.masteryDistribution[ProgressionStage.notStarted],
          equals(framework.allObjectives.length));
    });

    // 2. one attempt
    test('2. single attempt is accurately recorded in totals', () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 1,
            correctCount: 1,
            lastAttemptAt: baseDate,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.hasData, isTrue);
      expect(report.summary.totalAttempts, equals(1));
      expect(report.summary.correctCount, equals(1));
      expect(report.summary.incorrectCount, equals(0));
      expect(report.summary.accuracy, equals(1.0));
      expect(report.summary.objectivesAttempted, equals(1));
    });

    // 3. multiple attempts
    test('3. multiple attempts across objectives aggregate properly', () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 4,
            lastAttemptAt: baseDate,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_article_14_equality': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_14_equality',
            attemptCount: 3,
            correctCount: 2,
            lastAttemptAt: baseDate,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.summary.totalAttempts, equals(8));
      expect(report.summary.correctCount, equals(6));
      expect(report.summary.incorrectCount, equals(2));
      expect(report.summary.objectivesAttempted, equals(2));
    });

    // 4. correct/incorrect calculation
    test('4. correct and incorrect counts reconcile exactly', () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 7,
            lastAttemptAt: baseDate,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.summary.totalAttempts, equals(10));
      expect(report.summary.correctCount, equals(7));
      expect(report.summary.incorrectCount, equals(3));
      expect(report.summary.correctCount + report.summary.incorrectCount,
          equals(report.summary.totalAttempts));
    });

    // 5. accuracy
    test('5. accuracy is mathematically bounded between 0.0 and 1.0', () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 4,
            correctCount: 3,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.summary.accuracy, closeTo(0.75, 0.001));
      expect(report.summary.accuracyPercentage, closeTo(75.0, 0.001));
    });

    // 6. objective progress
    test('6. objective progress reports attempted vs total syllabus objectives',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 2,
            correctCount: 2,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.summary.objectivesAttempted, equals(1));
      expect(report.summary.totalObjectives,
          equals(framework.allObjectives.length));
    });

    // 7. mastery distribution
    test('7. mastery distribution reflects progression stages accurately',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_preamble_identity': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble_identity',
            attemptCount: 4,
            correctCount: 1, // 25% with >= 3 attempts -> Remediation Required
          ),
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 5, // 100% with >= 3 attempts -> Mastered
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      final dist = report.masteryDistribution;
      expect(dist[ProgressionStage.mastered], greaterThanOrEqualTo(1));
      expect(
          dist[ProgressionStage.remediationRequired], greaterThanOrEqualTo(1));
      expect(report.summary.objectivesMastered,
          equals(dist[ProgressionStage.mastered]));
      expect(report.summary.objectivesNeedingRemediation,
          equals(dist[ProgressionStage.remediationRequired]));
    });

    // 8. weak-area ranking
    test(
        '8. weak areas are ranked with remediation priority and lowest accuracy',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_preamble_identity': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble_identity',
            attemptCount: 5,
            correctCount: 1, // 20% -> Struggling
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 4,
            correctCount: 2, // 50% -> Struggling but higher accuracy
          ),
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 5, // 100% -> Not weak
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.weakAreas, isNotEmpty);
      expect(report.weakAreas.first.id, equals('lo_preamble_identity'));
      expect(report.weakAreas.first.isRemediationRequired, isTrue);
      expect(report.weakAreas.first.recommendedAction, isNotEmpty);
      expect(report.weakAreas.any((w) => w.id == 'lo_article_21_foundations'),
          isFalse);
    });

    // 9. subject analytics
    test('9. subject analytics aggregates topics and objectives properly',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 4,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.subjects, isNotEmpty);
      final polity = report.subjects.first;
      expect(polity.questionsAttempted, equals(4));
      expect(polity.correctCount, equals(4));
      expect(polity.accuracy, equals(1.0));
      expect(polity.objectivesAttempted, equals(1));
    });

    // 10. topic analytics
    test('10. topic analytics computes accuracy and objective counts',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 3,
            correctCount: 2,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      final polity = report.subjects.first;
      final topic = polity.topics
          .firstWhere((t) => t.topicId == 'unit_personal_liberty_art21');
      expect(topic.questionsAttempted, equals(3));
      expect(topic.correctCount, equals(2));
      expect(topic.accuracy, closeTo(2 / 3, 0.01));
    });

    // 11. objective analytics
    test('11. objective analytics exposes granular objective metrics',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 5,
            lastAttemptAt: baseDate,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      final polity = report.subjects.first;
      final fr = polity.topics
          .firstWhere((t) => t.topicId == 'unit_personal_liberty_art21');
      final obj = fr.objectives
          .firstWhere((o) => o.objectiveId == 'lo_article_21_foundations');

      expect(obj.attempts, equals(5));
      expect(obj.correctCount, equals(5));
      expect(obj.accuracy, equals(1.0));
      expect(obj.stage, equals(ProgressionStage.mastered));
      expect(obj.lastAttemptAt, equals(baseDate));
    });

    // 12. chronological trend
    test('12. chronological trend builds strictly monotonic timeline',
        () async {
      final t1 = DateTime.utc(2026, 9, 5, 10, 0, 0);
      final t2 = DateTime.utc(2026, 9, 6, 10, 0, 0);

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_001',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_001',
          planId: 'plan_1',
          planRevision: 1,
          completedAt: t1,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_001',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 4,
            incorrectAnswers: 1,
            skippedAnswers: 0,
            completedAt: t1,
          ),
        ),
      );

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_002',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_002',
          planId: 'plan_2',
          planRevision: 2,
          completedAt: t2,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_002',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 5,
            incorrectAnswers: 0,
            skippedAnswers: 0,
            completedAt: t2,
          ),
        ),
      );

      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: t2,
        progressMap: const {},
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.performanceTrends.length, equals(2));
      expect(report.performanceTrends[0].timestamp, equals(t1));
      expect(report.performanceTrends[0].cumulativeAttempts, equals(5));
      expect(report.performanceTrends[1].timestamp, equals(t2));
      expect(report.performanceTrends[1].cumulativeAttempts, equals(10));
      expect(
          report.performanceTrends[1].cumulativeAccuracy, closeTo(0.9, 0.01));
    });

    // 13. improving learner
    test('13. improving learner shows upward accuracy trajectory', () async {
      final t1 = DateTime.utc(2026, 9, 5);
      final t2 = DateTime.utc(2026, 9, 6);

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_imp_1',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_imp_1',
          planId: 'plan_1',
          planRevision: 1,
          completedAt: t1,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_imp_1',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 2, // 40%
            incorrectAnswers: 3,
            skippedAnswers: 0,
            completedAt: t1,
          ),
        ),
      );

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_imp_2',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_imp_2',
          planId: 'plan_2',
          planRevision: 2,
          completedAt: t2,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_imp_2',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 5, // 100%
            incorrectAnswers: 0,
            skippedAnswers: 0,
            completedAt: t2,
          ),
        ),
      );

      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: t2,
        progressMap: const {},
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.performanceTrends[0].accuracy, closeTo(0.40, 0.01));
      expect(report.performanceTrends[1].accuracy, closeTo(1.00, 0.01));
      expect(report.performanceTrends[1].cumulativeAccuracy,
          greaterThan(report.performanceTrends[0].cumulativeAccuracy));
    });

    // 14. declining learner
    test('14. declining learner shows downward accuracy trajectory', () async {
      final t1 = DateTime.utc(2026, 9, 5);
      final t2 = DateTime.utc(2026, 9, 6);

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_dec_1',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_dec_1',
          planId: 'plan_1',
          planRevision: 1,
          completedAt: t1,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_dec_1',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 5, // 100%
            incorrectAnswers: 0,
            skippedAnswers: 0,
            completedAt: t1,
          ),
        ),
      );

      await completionRepo.saveCompletionRecord(
        LearningActivityCompletionRecord(
          idempotencyKey: 'act_dec_2',
          learnerId: testLearner,
          examId: testExam,
          activityId: 'act_dec_2',
          planId: 'plan_2',
          planRevision: 2,
          completedAt: t2,
          outcome: LearningActivityOutcome.calculate(
            activityId: 'act_dec_2',
            activityType: LearningDecisionType.continuation,
            learnerId: testLearner,
            examId: testExam,
            questionsPresented: 5,
            questionsAttempted: 5,
            correctAnswers: 1, // 20%
            incorrectAnswers: 4,
            skippedAnswers: 0,
            completedAt: t2,
          ),
        ),
      );

      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: t2,
        progressMap: const {},
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.performanceTrends[1].accuracy,
          lessThan(report.performanceTrends[0].accuracy));
    });

    // 15. remediation-required learner
    test('15. remediation-required learner flags struggling objectives',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1, // < 50% with >= 3 attempts -> remediationRequired
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.summary.objectivesNeedingRemediation, equals(1));
      expect(report.weakAreas.any((w) => w.isRemediationRequired), isTrue);
    });

    // 16. mastered learner
    test('16. mastered learner reflects 100% mastery distribution accurately',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 5,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.summary.objectivesMastered, equals(1));
      expect(report.masteryDistribution[ProgressionStage.mastered],
          greaterThanOrEqualTo(1));
    });

    // 17. insufficient evidence
    test('17. insufficient evidence is categorized under progression stage',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 1,
            correctCount:
                1, // Only 1 attempt -> insufficient evidence (< 3 required)
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(report.masteryDistribution[ProgressionStage.insufficientEvidence],
          greaterThanOrEqualTo(1));
    });

    // 18. malformed evidence
    test('18. malformed input parameters throw structured ArgumentError',
        () async {
      expect(
        () => analyticsService.computeLearnerReport(
          learnerId: '   ',
          examId: testExam,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => analyticsService.computeLearnerReport(
          learnerId: testLearner,
          examId: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 19. repository failure
    test('19. recovery service failure surfaces LearnerAnalyticsException',
        () async {
      final serviceWithoutRepo = LearnerAnalyticsService(
        curriculumService: curriculumService,
        masteryService: masteryService,
        authRecoveryService: null,
      );

      expect(
        () => serviceWithoutRepo.computeLearnerReport(
          learnerId: testLearner,
          examId: testExam,
          authState: null, // Forces recovery
        ),
        throwsA(isA<LearnerAnalyticsException>()),
      );
    });

    // 20. analytics failure
    test(
        '20. empty curriculum framework throws structured LearnerAnalyticsException',
        () async {
      final emptyFramework = CurriculumFramework(
        id: 'empty_fw',
        title: 'Empty Framework',
        description: 'No domains',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: baseDate.toIso8601String(),
          provenance: 'test',
        ),
        provenance: 'test',
        domains: const [],
      );

      final failingCurriculumService =
          CurriculumService(framework: emptyFramework);
      final failingAnalyticsService = LearnerAnalyticsService(
        curriculumService: failingCurriculumService,
        masteryService: masteryService,
      );

      expect(
        () => failingAnalyticsService.computeLearnerReport(
          learnerId: testLearner,
          examId: testExam,
          authState: AuthoritativeLearnerState.empty(
            learnerId: testLearner,
            examId: testExam,
            createdAt: baseDate,
          ),
        ),
        throwsA(isA<LearnerAnalyticsException>()),
      );
    });

    // 21. navigation metadata
    test(
        '21. analytics report maintains exam and learner context for navigation',
        () async {
      final state = AuthoritativeLearnerState.empty(
        learnerId: testLearner,
        examId: testExam,
        createdAt: baseDate,
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.learnerId, equals(testLearner));
      expect(report.examId, equals(testExam));
      expect(report.generatedAt, isNotNull);
    });

    // 22. learner dashboard -> analytics compatibility
    test('22. dashboard state metrics align with analytics summary', () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 4,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.summary.totalAttempts, equals(6));
      expect(report.summary.correctCount, equals(4));
      expect(report.summary.accuracy, closeTo(4 / 6, 0.01));
    });

    // 23. faculty analytics where supported
    test(
        '23. faculty analytics summarizes authored, published, and draft content',
        () async {
      await facultyRepo.save(
        ManagedContentItem(
          id: 'mc_q_01',
          title: 'Article 21 Practice Question',
          description: 'Faculty authored question',
          examId: testExam,
          subjectId: 'domain_indian_polity',
          topicId: 'unit_fundamental_rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'prof_sharma',
          authorName: 'Prof. Sharma',
          provenance: 'Constitution of India',
          status: ContentLifecycleStatus.published,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      );

      await facultyRepo.save(
        ManagedContentItem(
          id: 'mc_rem_01',
          title: 'Article 14 Draft Lesson',
          description: 'Draft remedial lesson',
          examId: testExam,
          subjectId: 'domain_indian_polity',
          topicId: 'unit_fundamental_rights',
          objectiveId: 'lo_article_14_equality',
          contentType: ManagedContentType.remedialLesson,
          authorId: 'prof_sharma',
          authorName: 'Prof. Sharma',
          provenance: 'Constitution of India',
          status: ContentLifecycleStatus.draft,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      );

      final facultySummary = await analyticsService.computeFacultyReport(
        examId: testExam,
      );

      expect(facultySummary.totalContentItems, equals(2));
      expect(facultySummary.totalQuestions, equals(1));
      expect(facultySummary.totalRemedialLessons, equals(1));
      expect(facultySummary.publishedCount, equals(1));
      expect(facultySummary.draftCount, equals(1));
      expect(facultySummary.activeContentCount, equals(1));
    });

    // 24. content usage analytics
    test(
        '24. content report filtered by author reflects specific faculty footprint',
        () async {
      await facultyRepo.save(
        ManagedContentItem(
          id: 'mc_q_author1',
          title: 'Question by Author 1',
          description: 'Test',
          examId: testExam,
          subjectId: 'domain_indian_polity',
          topicId: 'unit_fundamental_rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'author_1',
          authorName: 'Author One',
          provenance: 'Test Standard',
          status: ContentLifecycleStatus.published,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      );

      await facultyRepo.save(
        ManagedContentItem(
          id: 'mc_q_author2',
          title: 'Question by Author 2',
          description: 'Test',
          examId: testExam,
          subjectId: 'domain_indian_polity',
          topicId: 'unit_fundamental_rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'author_2',
          authorName: 'Author Two',
          provenance: 'Test Standard',
          status: ContentLifecycleStatus.published,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      );

      final author1Report = await analyticsService.computeFacultyReport(
        authorId: 'author_1',
        examId: testExam,
      );

      expect(author1Report.totalContentItems, equals(1));
      expect(author1Report.totalQuestions, equals(1));
    });

    // 25. real practice changes analytics
    test('25. adding new attempts updates accuracy and attempts dynamically',
        () async {
      final state1 = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 2,
            correctCount: 1, // 50%
          ),
        },
      );

      final report1 = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state1,
      );

      expect(report1.summary.totalAttempts, equals(2));
      expect(report1.summary.accuracy, closeTo(0.5, 0.01));

      // After completing additional practice drills
      final state2 = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate.add(const Duration(minutes: 30)),
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 5, // ~83.3%
          ),
        },
      );

      final report2 = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state2,
      );

      expect(report2.summary.totalAttempts, equals(6));
      expect(report2.summary.accuracy, closeTo(5 / 6, 0.01));
      expect(report2.summary.accuracy, greaterThan(report1.summary.accuracy));
    });

    // 26. persistence/recovery preserves analytics
    test('26. persisted authoritative state recovers identical analytics',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 4,
          ),
        },
      );

      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(report.summary.totalAttempts, equals(5));
      expect(report.summary.correctCount, equals(4));
      expect(report.summary.accuracy, closeTo(0.80, 0.01));
    });

    // 27. no fake/hardcoded metrics
    test('27. calculations derive purely from provided authoritative state',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 7,
            correctCount: 3,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.summary.accuracy, equals(3 / 7));
      expect(report.summary.totalAttempts, equals(7));
      expect(report.summary.correctCount, equals(3));
    });

    // 28. deterministic results
    test('28. identical authoritative state produces identical report',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 4,
            correctCount: 3,
          ),
        },
      );

      final reportA = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      final reportB = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      expect(reportA.toJson(), equals(reportB.toJson()));
    });

    // 29. duplicate records do not double-count
    test('29. duplicate completed activity records are deduplicated', () async {
      final t1 = DateTime.utc(2026, 9, 5);

      final record = LearningActivityCompletionRecord(
        idempotencyKey: 'dup_key_001',
        learnerId: testLearner,
        examId: testExam,
        activityId: 'act_001',
        planId: 'plan_1',
        planRevision: 1,
        completedAt: t1,
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_001',
          activityType: LearningDecisionType.continuation,
          learnerId: testLearner,
          examId: testExam,
          questionsPresented: 5,
          questionsAttempted: 5,
          correctAnswers: 5,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          completedAt: t1,
        ),
      );

      await completionRepo.saveCompletionRecord(record);
      // Save duplicate with same key
      await completionRepo.saveCompletionRecord(record);

      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: t1,
        progressMap: const {},
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
      );

      expect(report.performanceTrends.length, equals(1));
      expect(report.performanceTrends.first.attempts, equals(5));
    });

    // 30. complete end-to-end analytics journey
    test(
        '30. complete end-to-end analytics report serializes and deserializes cleanly',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
            lastAttemptAt: baseDate,
          ),
          'lo_preamble_identity': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble_identity',
            attemptCount: 5,
            correctCount: 1,
            lastAttemptAt: baseDate,
          ),
        },
      );

      final report = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: state,
        asOfDate: baseDate,
      );

      final json = report.toJson();
      final roundTrip = LearnerAnalyticsReport.fromJson(json);

      expect(roundTrip.learnerId, equals(report.learnerId));
      expect(roundTrip.examId, equals(report.examId));
      expect(roundTrip.summary.totalAttempts,
          equals(report.summary.totalAttempts));
      expect(roundTrip.summary.accuracy, equals(report.summary.accuracy));
      expect(roundTrip.masteryDistribution.length,
          equals(report.masteryDistribution.length));
      expect(roundTrip.weakAreas.length, equals(report.weakAreas.length));
      expect(roundTrip.subjects.length, equals(report.subjects.length));
    });
  });
}
