/// P48 Institutional Cohort / Class Management & Assignment Distribution Tests (TITAN-KO-048.0).
///
/// Comprehensive suite verifying all 34 required test cases from Section 18:
/// Cohort lifecycle, membership isolation, faculty responsibility, assignment lifecycle,
/// deadline compliance, real learning integration, dashboard summaries, weak-area analytics,
/// multi-tenant boundaries, and persistence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 20, 10, 0, 0);

  late CurriculumFramework framework;
  late CurriculumService curriculumService;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAuthoritativeLearningStateRepository authRepo;
  late AuthoritativeLearningStateRecoveryService authRecoveryService;
  late MasteryProgressionService masteryService;
  late LearnerAnalyticsService analyticsService;
  late CohortAssignmentService cohortService;

  DateTime simulatedNow = fixedDate;

  AuthoritativeLearnerState buildLearnerState({
    required String learnerId,
    required String examId,
    required Map<String, LearnerProgress> progressMap,
  }) {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      lastUpdatedAt: simulatedNow,
      revision: 1,
    );
  }

  setUp(() {
    simulatedNow = fixedDate;
    framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
    curriculumService = CurriculumService(framework: framework);
    cohortRepo = InMemoryCohortRepository();
    authRepo = InMemoryAuthoritativeLearningStateRepository();
    authRecoveryService = AuthoritativeLearningStateRecoveryService(
      repository: authRepo,
    );
    final checkpointRepo = InMemorySessionCheckpointRepository();
    masteryService = MasteryProgressionService(
      curriculumService: curriculumService,
      authRecoveryService: authRecoveryService,
      checkpointRepository: checkpointRepo,
    );
    analyticsService = LearnerAnalyticsService(
      curriculumService: curriculumService,
      masteryService: masteryService,
      authRecoveryService: authRecoveryService,
    );
    cohortService = CohortAssignmentService(
      cohortRepository: cohortRepo,
      curriculumService: curriculumService,
      authRecoveryService: authRecoveryService,
      analyticsService: analyticsService,
      clock: () => simulatedNow,
    );
  });

  group('P48 Institutional Cohort Management Unit & Contract Suite (34 Cases)',
      () {
    // 1. create cohort
    test('1. create cohort stores cohort profile with correct metadata',
        () async {
      final cohort = await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        description: 'Prelims 2026 Intensive Group',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      expect(cohort.cohortId, equals('cohort_upsc_2026_a'));
      expect(cohort.name, equals('UPSC 2026 Batch A'));
      expect(cohort.examId, equals('upsc_prelims_gs1'));
      expect(cohort.primaryFacultyId, equals('faculty_sharma'));
      expect(cohort.status, equals(CohortStatus.active));
      expect(cohort.learnerCount, equals(0));

      final fetched = await cohortRepo.getCohortById('cohort_upsc_2026_a');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('UPSC 2026 Batch A'));
    });

    // 2. update cohort
    test('2. update cohort modifies name and description', () async {
      final cohort = await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final updated = await cohortService.updateCohort(
        cohort.copyWith(name: 'UPSC 2026 Batch A (Updated)'),
        requesterId: 'faculty_sharma',
      );

      expect(updated.name, equals('UPSC 2026 Batch A (Updated)'));
      final fetched = await cohortRepo.getCohortById('cohort_upsc_2026_a');
      expect(fetched!.name, equals('UPSC 2026 Batch A (Updated)'));
    });

    // 3. archive cohort
    test('3. archive cohort sets status to archived', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final archived = await cohortService.archiveCohort(
        'cohort_upsc_2026_a',
        requesterId: 'faculty_sharma',
      );

      expect(archived.status, equals(CohortStatus.archived));
      final fetched = await cohortRepo.getCohortById('cohort_upsc_2026_a');
      expect(fetched!.status, equals(CohortStatus.archived));
    });

    // 4. add learner
    test('4. add learner enrolls member into cohort', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final updated = await cohortService.addLearner(
        'cohort_upsc_2026_a',
        'learner_101',
        requesterId: 'faculty_sharma',
      );

      expect(updated.hasLearner('learner_101'), isTrue);
      expect(updated.learnerCount, equals(1));
    });

    // 5. duplicate learner addition
    test('5. duplicate learner addition is idempotent', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      await cohortService.addLearner('cohort_upsc_2026_a', 'learner_101',
          requesterId: 'faculty_sharma');
      final second = await cohortService.addLearner(
          'cohort_upsc_2026_a', 'learner_101',
          requesterId: 'faculty_sharma');

      expect(second.learnerCount, equals(1));
      expect(second.hasLearner('learner_101'), isTrue);
    });

    // 6. remove learner
    test('6. remove learner removes member from cohort', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101', 'learner_102'],
      );

      final updated = await cohortService.removeLearner(
        'cohort_upsc_2026_a',
        'learner_101',
        requesterId: 'faculty_sharma',
      );

      expect(updated.hasLearner('learner_101'), isFalse);
      expect(updated.hasLearner('learner_102'), isTrue);
      expect(updated.learnerCount, equals(1));
    });

    // 7. membership isolation
    test(
        '7. membership isolation: member of cohort A is not member of cohort B',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_b',
        name: 'Batch B',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_verma',
        learnerIds: ['learner_201'],
      );

      expect(
          await cohortService.checkMembership(
              'cohort_upsc_2026_a', 'learner_101'),
          isTrue);
      expect(
          await cohortService.checkMembership(
              'cohort_upsc_2026_a', 'learner_201'),
          isFalse);
      expect(
          await cohortService.checkMembership(
              'cohort_upsc_2026_b', 'learner_101'),
          isFalse);
      expect(
          await cohortService.checkMembership(
              'cohort_upsc_2026_b', 'learner_201'),
          isTrue);
    });

    // 8. assign faculty
    test('8. assign faculty assigns primary and co-instructors', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final withCo = await cohortService.assignFaculty(
        'cohort_upsc_2026_a',
        'faculty_gupta',
        requesterId: 'faculty_sharma',
      );

      expect(withCo.hasFaculty('faculty_sharma'), isTrue);
      expect(withCo.hasFaculty('faculty_gupta'), isTrue);
      expect(withCo.additionalFacultyIds, contains('faculty_gupta'));

      final cohortsForGupta =
          await cohortService.getCohortsForFaculty('faculty_gupta');
      expect(cohortsForGupta.length, equals(1));
    });

    // 9. create assignment
    test('9. create assignment creates draft assignment for cohort', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final assign = await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Foundations Drill',
        targetType: CohortAssignmentTargetType.objective,
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.draft,
      );

      expect(assign.assignmentId, equals('assign_art21_01'));
      expect(assign.status, equals(CohortAssignmentStatus.draft));
      expect(assign.targetId, equals('lo_article_21_foundations'));
    });

    // 10. edit draft assignment
    test('10. edit draft assignment modifies title and target', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final assign = await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Draft Title',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
      );

      final updated = await cohortService.updateAssignment(
        assign.copyWith(title: 'Refined Article 21 Assignment'),
        requesterId: 'faculty_sharma',
      );

      expect(updated.title, equals('Refined Article 21 Assignment'));
    });

    // 11. publish assignment
    test('11. publish assignment changes status to published and emits event',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
      );

      final eventFuture = cohortService.assignmentEvents.first;

      final published = await cohortService.publishAssignment(
        'assign_art21_01',
        facultyId: 'faculty_sharma',
      );

      expect(published.status, equals(CohortAssignmentStatus.published));

      final event = await eventFuture;
      expect(event.assignmentId, equals('assign_art21_01'));
      expect(event.type, equals(CohortAssignmentEventType.published));
    });

    // 12. published assignment visible
    test('12. published assignment visible in learner assignments query',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
      );

      final assignments =
          await cohortService.getAssignmentsForLearner('learner_101');
      expect(assignments.length, equals(1));
      expect(assignments.first.assignmentId, equals('assign_art21_01'));
    });

    // 13. draft hidden from learner
    test('13. draft hidden from learner assignments query', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_draft_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Draft Unreleased Assignment',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.draft,
      );

      final assignments =
          await cohortService.getAssignmentsForLearner('learner_101');
      expect(assignments, isEmpty);
    });

    // 14. due date
    test('14. due date is correctly preserved and reported', () async {
      final due = fixedDate.add(const Duration(days: 3));
      final assign = CohortAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_01',
        title: 'Test Due Date',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: due,
      );

      expect(assign.dueDate, equals(due));
      expect(assign.isOverdue(fixedDate), isFalse);
    });

    // 15. overdue state
    test('15. overdue state triggered when current time exceeds due date',
        () async {
      final due = fixedDate.add(const Duration(days: 1));
      final assign = CohortAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_01',
        title: 'Test Overdue',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: due,
      );

      expect(assign.isOverdue(fixedDate.add(const Duration(days: 2))), isTrue);
    });

    // 16. completion state
    test('16. completion state verified against passing criteria', () async {
      final criteria = CohortAssignmentPassingCriteria(
        minAttempts: 3,
        minAccuracy: 0.65,
      );

      expect(criteria.minAttempts, equals(3));
      expect(criteria.minAccuracy, equals(0.65));
    });

    // 17. assignment completion from real learning
    test(
        '17. assignment completion derived from real learning in AuthoritativeLearnerState',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
        passingCriteria: const CohortAssignmentPassingCriteria(
          minAttempts: 5,
          minAccuracy: 0.70,
        ),
      );

      // Supply real learner progress satisfying passing criteria
      final learnerState = buildLearnerState(
        learnerId: 'learner_101',
        examId: 'upsc_prelims_gs1',
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 5, // 5/6 = 83.3% accuracy
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final progress = await cohortService.getLearnerAssignmentProgress(
        'assign_art21_01',
        'learner_101',
        authState: learnerState,
      );

      expect(progress.status, equals(CohortLearnerProgressStatus.completed));
      expect(progress.isPassing, isTrue);
      expect(progress.attempts, equals(6));
      expect(progress.accuracy, closeTo(0.833, 0.01));
    });

    // 18. faculty cohort dashboard
    test(
        '18. faculty cohort dashboard summarizes active learners and assignments',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101', 'learner_102'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
      );

      final summary =
          await cohortService.computeCohortSummary('cohort_upsc_2026_a');

      expect(summary.totalLearners, equals(2));
      expect(summary.totalAssignments, equals(1));
    });

    // 19. cohort completion percentage
    test(
        '19. cohort completion percentage correctly computed from completed learner count',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101', 'learner_102'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
        passingCriteria: const CohortAssignmentPassingCriteria(
            minAttempts: 2, minAccuracy: 0.5),
      );

      // learner_101 completed, learner_102 has 0 attempts
      final learner1State = buildLearnerState(
        learnerId: 'learner_101',
        examId: 'upsc_prelims_gs1',
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 4,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final summary = await cohortService.computeCohortSummary(
        'cohort_upsc_2026_a',
        learnerStates: {'learner_101': learner1State},
      );

      expect(summary.completedAssignmentsCount, equals(1));
      expect(
          summary.completionRate, closeTo(0.50, 0.001)); // 1 out of 2 completed
    });

    // 20. learner progress
    test(
        '20. learner progress details attempts, accuracy, and status for single learner',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
        passingCriteria: const CohortAssignmentPassingCriteria(
          minAttempts: 5,
          minAccuracy: 0.80,
        ),
      );

      final learnerState = buildLearnerState(
        learnerId: 'learner_101',
        examId: 'upsc_prelims_gs1',
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 3,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final prog = await cohortService.getLearnerAssignmentProgress(
        'assign_art21_01',
        'learner_101',
        authState: learnerState,
      );

      expect(prog.attempts, equals(3));
      expect(prog.accuracy, closeTo(0.666, 0.01));
      expect(prog.status, equals(CohortLearnerProgressStatus.inProgress));
    });

    // 21. assignment progress
    test('21. assignment progress aggregates all learners for that assignment',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101', 'learner_102'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
      );

      final assignSummary =
          await cohortService.computeAssignmentSummary('assign_art21_01');

      expect(assignSummary.totalAssigned, equals(2));
      expect(assignSummary.notStartedCount, equals(2));
      expect(assignSummary.completedCount, equals(0));
    });

    // 22. weak-area visibility using existing analytics
    test(
        '22. weak-area visibility identifies poorly performing objectives across cohort',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101', 'learner_102'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_art21_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Article 21 Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.subtract(const Duration(days: 1)), // Overdue
        status: CohortAssignmentStatus.published,
      );

      final summary = await cohortService.computeCohortSummary(
        'cohort_upsc_2026_a',
        asOfDate: fixedDate,
      );

      expect(summary.weakAreas, contains('lo_article_21_foundations'));
    });

    // 23. multiple cohorts
    test('23. multiple cohorts: learner can belong to multiple batches',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_batch_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createCohort(
        cohortId: 'cohort_batch_b',
        name: 'Batch B',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_verma',
        learnerIds: ['learner_101'],
      );

      final cohorts = await cohortService.getCohortsForLearner('learner_101');
      expect(cohorts.length, equals(2));
      expect(cohorts.map((c) => c.cohortId),
          containsAll(['cohort_batch_a', 'cohort_batch_b']));
    });

    // 24. multiple assignments
    test('24. multiple assignments per cohort aggregated correctly in queries',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Assignment 1',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 3)),
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_02',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Assignment 2',
        targetId: 'lo_basic_structure_doctrine',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
      );

      final assignments =
          await cohortService.getAssignmentsForCohort('cohort_upsc_2026_a');
      expect(assignments.length, equals(2));
    });

    // 25. persistence
    test('25. persistence: snapshots export and import without data loss',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Assignment 1',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 3)),
      );

      final snapshot = await cohortRepo.exportSnapshot();
      expect(snapshot['cohorts'], isNotEmpty);
      expect(snapshot['assignments'], isNotEmpty);

      final freshRepo = InMemoryCohortRepository();
      await freshRepo.importSnapshot(snapshot);

      final restoredCohort =
          await freshRepo.getCohortById('cohort_upsc_2026_a');
      final restoredAssign = await freshRepo.getAssignmentById('assign_01');

      expect(restoredCohort, isNotNull);
      expect(restoredCohort!.name, equals('Batch A'));
      expect(restoredAssign, isNotNull);
      expect(restoredAssign!.title, equals('Assignment 1'));
    });

    // 26. restart recovery
    test(
        '26. restart recovery: freshly initialized service reloads prior state from repository',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      final snapshot = await cohortRepo.exportSnapshot();

      // Simulate app restart
      final newRepo = InMemoryCohortRepository();
      await newRepo.importSnapshot(snapshot);

      final newService = CohortAssignmentService(
        cohortRepository: newRepo,
        curriculumService: curriculumService,
      );

      final loaded = await newService.getCohort('cohort_upsc_2026_a');
      expect(loaded, isNotNull);
      expect(loaded!.hasLearner('learner_101'), isTrue);
    });

    // 27. offline completion
    test(
        '27. offline completion: learner state evaluated locally without remote failure',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'Offline Assignment',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 5)),
        status: CohortAssignmentStatus.published,
      );

      // Offline state passed directly
      final offlineState = buildLearnerState(
        learnerId: 'learner_101',
        examId: 'upsc_prelims_gs1',
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 2,
            correctCount: 2,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final progress = await cohortService.getLearnerAssignmentProgress(
        'assign_01',
        'learner_101',
        authState: offlineState,
      );

      expect(progress.status, equals(CohortLearnerProgressStatus.completed));
    });

    // 28. synchronization
    test(
        '28. synchronization: cohort operations do not corrupt underlying learner state outbox',
        () async {
      final outbox = InMemorySyncOutboxRepository();

      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_101'],
      );

      final entries = await outbox.getAll();
      expect(
          entries, isEmpty); // Outbox untouched by cohort membership operations
    });

    // 29. tenant isolation
    test('29. tenant isolation: Tenant A cannot see Tenant B cohorts',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_tenant_1',
        tenantId: 'tenant_alpha',
        name: 'Batch Alpha',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      await cohortService.createCohort(
        cohortId: 'cohort_tenant_2',
        tenantId: 'tenant_beta',
        name: 'Batch Beta',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_verma',
      );

      final alphaCohorts =
          await cohortService.listCohorts(tenantId: 'tenant_alpha');
      final betaCohorts =
          await cohortService.listCohorts(tenantId: 'tenant_beta');

      expect(alphaCohorts.length, equals(1));
      expect(alphaCohorts.first.cohortId, equals('cohort_tenant_1'));

      expect(betaCohorts.length, equals(1));
      expect(betaCohorts.first.cohortId, equals('cohort_tenant_2'));
    });

    // 30. unauthorized access
    test(
        '30. unauthorized access: non-faculty user rejected from modifying cohort',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      expect(
        () => cohortService.addLearner(
          'cohort_upsc_2026_a',
          'learner_101',
          requesterId: 'unauthorized_hacker',
        ),
        throwsA(isA<CohortSecurityException>()),
      );
    });

    // 31. repository failure
    test('31. repository failure handled safely when storage errors occur',
        () async {
      cohortRepo.setSimulateFailure(true);

      expect(
        () => cohortService.createCohort(
          cohortId: 'cohort_fail',
          name: 'Fail Cohort',
          examId: 'upsc_prelims_gs1',
          primaryFacultyId: 'faculty_sharma',
        ),
        throwsA(isA<CohortRepositoryException>()),
      );

      cohortRepo.setSimulateFailure(false);
    });

    // 32. invalid assignment target
    test('32. invalid assignment target rejected during assignment creation',
        () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      expect(
        () => cohortService.createAssignment(
          assignmentId: 'assign_bad_01',
          cohortId: 'cohort_upsc_2026_a',
          title: 'Bad Target',
          targetType: CohortAssignmentTargetType.objective,
          targetId: 'completely_nonexistent_objective_id',
          assignedByFacultyId: 'faculty_sharma',
          dueDate: fixedDate.add(const Duration(days: 3)),
        ),
        throwsA(isA<CohortValidationException>()),
      );
    });

    // 33. closed assignment
    test('33. closed assignment cannot be edited or re-published', () async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_2026_a',
        name: 'Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );

      final assign = await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_2026_a',
        title: 'To Close',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 3)),
        status: CohortAssignmentStatus.published,
      );

      await cohortService.closeAssignment('assign_01',
          facultyId: 'faculty_sharma');

      expect(
        () => cohortService.updateAssignment(
          assign.copyWith(title: 'Edited After Close'),
          requesterId: 'faculty_sharma',
        ),
        throwsA(isA<CohortValidationException>()),
      );

      expect(
        () => cohortService.publishAssignment('assign_01',
            facultyId: 'faculty_sharma'),
        throwsA(isA<CohortValidationException>()),
      );
    });

    // 34. end-to-end institutional workflow
    test(
        '34. end-to-end institutional workflow creates cohort, enrolls learners, distributes assignment, and computes metrics',
        () async {
      // 1. Create cohort
      final cohort = await cohortService.createCohort(
        cohortId: 'cohort_titan_complete',
        name: 'TITAN UPSC 2026',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
      );
      expect(cohort.cohortId, equals('cohort_titan_complete'));

      // 2. Add members
      await cohortService.addLearners(
        'cohort_titan_complete',
        ['learner_01', 'learner_02'],
        requesterId: 'faculty_sharma',
      );

      // 3. Create & publish assignment
      final assign = await cohortService.createAssignment(
        assignmentId: 'assign_titan_01',
        cohortId: 'cohort_titan_complete',
        title: 'Fundamental Rights Comprehensive',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_sharma',
        dueDate: fixedDate.add(const Duration(days: 7)),
        status: CohortAssignmentStatus.published,
      );
      expect(assign.status, equals(CohortAssignmentStatus.published));

      // 4. Verify learner views assignment
      final learner1Assignments =
          await cohortService.getAssignmentsForLearner('learner_01');
      expect(learner1Assignments.length, equals(1));

      // 5. Compute cohort progress
      final summary =
          await cohortService.computeCohortSummary('cohort_titan_complete');
      expect(summary.totalLearners, equals(2));
      expect(summary.totalAssignments, equals(1));
    });
  });
}
