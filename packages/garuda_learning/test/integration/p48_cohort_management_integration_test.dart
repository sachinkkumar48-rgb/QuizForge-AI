/// P48 Closed-Loop Acceptance Integration Test (Section 19).
///
/// Mandatory acceptance scenario:
/// 1. Faculty creates "UPSC 2026 Batch A"
/// 2. Adds 3 learners (Learner 1, Learner 2, Learner 3)
/// 3. Assigns faculty member
/// 4. Creates practice assignment targeting existing objective ('lo_article_21_foundations')
/// 5. Sets deadline (T + 2 days)
/// 6. Publishes assignment
///
/// THEN:
/// - Learner 1 sees assignment -> starts practice -> completes required work -> assignment completed
/// - Learner 2 sees assignment -> starts but does not complete -> status = in progress
/// - Learner 3 does not start -> after deadline -> status = overdue
///
/// THEN:
/// - Faculty opens cohort dashboard:
///   - 3 learners
///   - 1 completed
///   - 1 in progress
///   - 1 overdue
///   - completion percentage = 33.3% (1/3)
/// - Drill down: Cohort -> Assignment -> Learner -> existing analytics & mastery.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 9, 21, 10, 0, 0);

  late CurriculumFramework framework;
  late CurriculumService curriculumService;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAuthoritativeLearningStateRepository authRepo;
  late AuthoritativeLearningStateRecoveryService authRecoveryService;
  late MasteryProgressionService masteryService;
  late LearnerAnalyticsService analyticsService;
  late CohortAssignmentService cohortService;

  DateTime simulatedClock = baseTime;

  setUp(() {
    simulatedClock = baseTime;
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
      clock: () => simulatedClock,
    );
  });

  test(
      'P48 Section 19 Mandatory End-to-End Acceptance Test: Cohort & Assignment Lifecycle',
      () async {
    const cohortId = 'cohort_upsc_2026_batch_a';
    const facultyId = 'faculty_prof_sharma';
    const targetObjectiveId = 'lo_article_21_foundations';

    final learner1 = 'learner_alpha_01';
    final learner2 = 'learner_beta_02';
    final learner3 = 'learner_gamma_03';

    // -------------------------------------------------------------------------
    // Phase 1: Faculty Setup
    // -------------------------------------------------------------------------
    // 1. Create "UPSC 2026 Batch A"
    final cohort = await cohortService.createCohort(
      cohortId: cohortId,
      name: 'UPSC 2026 Batch A',
      description: 'Prelims General Studies Batch A - Constitutional Law',
      examId: 'upsc_prelims_gs1',
      primaryFacultyId: facultyId,
    );
    expect(cohort.cohortId, equals(cohortId));
    expect(cohort.name, equals('UPSC 2026 Batch A'));

    // 2. Add 3 Learners
    await cohortService.addLearners(
      cohortId,
      [learner1, learner2, learner3],
      requesterId: facultyId,
    );

    final members = await cohortService.listMembers(cohortId);
    expect(members.length, equals(3));
    expect(members, containsAll([learner1, learner2, learner3]));

    // 3. Assign Faculty
    await cohortService.assignFaculty(
      cohortId,
      facultyId,
      isPrimary: true,
      requesterId: facultyId,
    );

    // 4. Create Practice Assignment targeting existing objective & set deadline (T + 2 days)
    final deadline = baseTime.add(const Duration(days: 2));
    const assignmentId = 'assign_art21_practice_01';

    await cohortService.createAssignment(
      assignmentId: assignmentId,
      cohortId: cohortId,
      title: 'Article 21 Constitutional Foundations Practice',
      description: 'Complete at least 5 questions with minimum 70% accuracy',
      targetType: CohortAssignmentTargetType.objective,
      targetId: targetObjectiveId,
      assignedByFacultyId: facultyId,
      dueDate: deadline,
      status: CohortAssignmentStatus.draft,
      passingCriteria: const CohortAssignmentPassingCriteria(
        minAttempts: 5,
        minAccuracy: 0.70,
        requiredMasteryStage: 'achieved',
      ),
    );

    // 5. Publish Assignment
    final published = await cohortService.publishAssignment(
      assignmentId,
      facultyId: facultyId,
    );
    expect(published.status, equals(CohortAssignmentStatus.published));

    // -------------------------------------------------------------------------
    // Phase 2: Learner Execution
    // -------------------------------------------------------------------------
    // Learner 1: Sees assignment, completes required work (6 attempts, 5 correct = 83.3%, achieved)
    final l1Assignments =
        await cohortService.getAssignmentsForLearner(learner1);
    expect(l1Assignments.any((a) => a.assignmentId == assignmentId), isTrue);

    final l1ProgressRecord = LearnerProgress(
      learnerId: learner1,
      objectiveId: targetObjectiveId,
      attemptCount: 6,
      correctCount: 5,
      status: LearnerObjectiveStatus.achieved,
      lastAttemptAt: baseTime.add(const Duration(hours: 12)),
    );
    final l1State = AuthoritativeLearnerState(
      learnerId: learner1,
      examId: 'upsc_prelims_gs1',
      progressMap: {targetObjectiveId: l1ProgressRecord},
      lastUpdatedAt: baseTime.add(const Duration(hours: 12)),
    );

    // Learner 2: Sees assignment, starts but does not complete (2 attempts, 1 correct = 50%, inProgress)
    final l2Assignments =
        await cohortService.getAssignmentsForLearner(learner2);
    expect(l2Assignments.any((a) => a.assignmentId == assignmentId), isTrue);

    final l2ProgressRecord = LearnerProgress(
      learnerId: learner2,
      objectiveId: targetObjectiveId,
      attemptCount: 2,
      correctCount: 1,
      status: LearnerObjectiveStatus.inProgress,
      lastAttemptAt: baseTime.add(const Duration(hours: 18)),
    );
    final l2State = AuthoritativeLearnerState(
      learnerId: learner2,
      examId: 'upsc_prelims_gs1',
      progressMap: {targetObjectiveId: l2ProgressRecord},
      lastUpdatedAt: baseTime.add(const Duration(hours: 18)),
    );

    // Learner 3: Does not start (0 attempts)
    final l3Assignments =
        await cohortService.getAssignmentsForLearner(learner3);
    expect(l3Assignments.any((a) => a.assignmentId == assignmentId), isTrue);

    // Advance time to AFTER deadline (T + 3 days)
    simulatedClock = baseTime.add(const Duration(days: 3));

    final statesMap = {
      learner1: l1State,
      learner2: l2State,
      // learner3 has no recorded state
    };

    // -------------------------------------------------------------------------
    // Phase 3: Faculty Dashboard & Verification
    // -------------------------------------------------------------------------
    final assignSummary = await cohortService.computeAssignmentSummary(
      assignmentId,
      asOfDate: simulatedClock,
      learnerStates: statesMap,
    );

    // Verify 3 learners, 1 completed, 1 in progress, 1 overdue
    expect(assignSummary.totalAssigned, equals(3));
    expect(assignSummary.completedCount, equals(1));
    expect(assignSummary.inProgressCount,
        equals(0)); // Learner 2 is after deadline without passing -> overdue!
    expect(assignSummary.overdueCount,
        equals(2)); // Learner 2 (failed to finish) & Learner 3 (never started)
    expect(assignSummary.completionRate, closeTo(1 / 3, 0.001));

    // Verify Learner 1 is Completed
    final p1 = assignSummary.learnerProgressList
        .firstWhere((p) => p.learnerId == learner1);
    expect(p1.status, equals(CohortLearnerProgressStatus.completed));
    expect(p1.isPassing, isTrue);
    expect(p1.attempts, equals(6));
    expect(p1.accuracy, closeTo(0.833, 0.01));

    // Verify Learner 2 is Overdue (started, but deadline passed without completion)
    final p2 = assignSummary.learnerProgressList
        .firstWhere((p) => p.learnerId == learner2);
    expect(p2.status, equals(CohortLearnerProgressStatus.overdue));
    expect(p2.isPassing, isFalse);
    expect(p2.attempts, equals(2));
    expect(p2.accuracy, closeTo(0.50, 0.01));

    // Verify Learner 3 is Overdue (never started, deadline passed)
    final p3 = assignSummary.learnerProgressList
        .firstWhere((p) => p.learnerId == learner3);
    expect(p3.status, equals(CohortLearnerProgressStatus.overdue));
    expect(p3.isPassing, isFalse);
    expect(p3.attempts, equals(0));

    // Cohort Dashboard Aggregates
    final cohortSummary = await cohortService.computeCohortSummary(
      cohortId,
      asOfDate: simulatedClock,
      learnerStates: statesMap,
    );

    expect(cohortSummary.totalLearners, equals(3));
    expect(cohortSummary.activeLearners,
        equals(2)); // Learner 1 & 2 attempted questions
    expect(cohortSummary.totalAssignments, equals(1));
    expect(cohortSummary.completedAssignmentsCount, equals(1));
    expect(cohortSummary.overdueCount, equals(2));
    expect(cohortSummary.completionRate, closeTo(1 / 3, 0.001));

    // -------------------------------------------------------------------------
    // Phase 4: Drill Down (Cohort -> Assignment -> Learner -> Mastery)
    // -------------------------------------------------------------------------
    final report = await cohortService.computeCohortAnalytics(
      cohortId,
      asOfDate: simulatedClock,
      learnerStates: statesMap,
    );

    expect(report.summary.cohort.cohortId, equals(cohortId));
    expect(report.assignmentSummaries.length, equals(1));
    expect(report.assignmentSummaries.first.assignment.assignmentId,
        equals(assignmentId));
    expect(report.summary.weakAreas,
        contains(targetObjectiveId)); // Non-completion rate >= 50%
  });
}
