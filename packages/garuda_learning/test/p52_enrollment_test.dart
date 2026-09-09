/// P52 Learner Enrollment, Course Registration, Access Eligibility & Lifecycle Contract Test Suite (TITAN-KO-052.0).
///
/// Comprehensive suite verifying all required test cases from Section 17:
/// 1. Course creation
/// 2. Course duplicate prevention
/// 3. Course archive
/// 4. Learner registration (pending)
/// 5. Learner registration (auto-activate)
/// 6. Learner registration empty field validation
/// 7. Learner registration course not found
/// 8. Learner registration tenant boundary check
/// 9. Duplicate active enrollment rejected
/// 10. Duplicate pending enrollment rejected
/// 11. Prerequisite check blocks enrollment
/// 12. Prerequisite satisfied allows enrollment
/// 13. Cohort membership validation
/// 14. Activate enrollment (pending -> active)
/// 15. Activate enrollment illegal transition
/// 16. Suspend enrollment (active -> suspended)
/// 17. Suspend enrollment rejects empty reason
/// 18. Suspend enrollment illegal transition
/// 19. Reactivate enrollment (suspended -> active)
/// 20. Reactivate enrollment illegal transition
/// 21. Withdraw learner from active
/// 22. Withdraw learner from suspended
/// 23. Withdraw learner rejects empty reason
/// 24. Withdraw learner illegal transition
/// 25. Cancel registration (pending -> cancelled)
/// 26. Cancel registration illegal transition
/// 27. Mark completion (active -> completed)
/// 28. Mark completion illegal transition
/// 29. Course access control gating evaluation (full, readOnly, blocked)
/// 30. Bulk cohort enrollment resilience & error reporting
/// 31. Restart persistence (exportSnapshot / importSnapshot)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 15, 9, 0, 0);

  late InMemoryEnrollmentRepository repo;
  late InMemoryCohortRepository cohortRepo;
  late EnrollmentService service;

  setUp(() {
    repo = InMemoryEnrollmentRepository();
    cohortRepo = InMemoryCohortRepository();
    service = EnrollmentService(
      enrollmentRepository: repo,
      cohortRepository: cohortRepo,
      clock: () => baseTime,
    );
  });

  group('P52: Course Offerings & Management', () {
    test('1. Course creation persists valid course', () async {
      final course = await service.createCourse(
        courseId: 'course_const_101',
        title: 'Constitutional Law Foundations',
        description: 'Foundational concepts of constitutional democracy.',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_sharma',
        estimatedHours: 40,
      );

      expect(course.courseId, equals('course_const_101'));
      expect(course.title, equals('Constitutional Law Foundations'));
      expect(course.isActive, isTrue);

      final fetched = await service.getCourse('course_const_101');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Constitutional Law Foundations'));
    });

    test('2. Course duplicate prevention throws on repeated courseId',
        () async {
      await service.createCourse(
        courseId: 'course_polity_dup',
        title: 'Polity 101',
        examId: 'upsc_prelims_gs1',
        facultyId: 'faculty_1',
      );

      expect(
        () => service.createCourse(
          courseId: 'course_polity_dup',
          title: 'Polity 101 Duplicate',
          examId: 'upsc_prelims_gs1',
          facultyId: 'faculty_2',
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );
    });

    test('3. Course archive transitions status to archived', () async {
      await service.createCourse(
        courseId: 'course_to_archive',
        title: 'Old Curriculum',
        examId: 'upsc_prelims_gs1',
        facultyId: 'faculty_1',
      );

      final archived = await service.archiveCourse(
        courseId: 'course_to_archive',
        actorId: 'admin_1',
      );

      expect(archived.status, equals(CourseStatus.archived));
      expect(archived.isArchived, isTrue);
    });
  });

  group('P52: Registration & Duplicate Prevention', () {
    setUp(() async {
      await service.createCourse(
        courseId: 'course_demo_101',
        title: 'Demo 101',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_demo',
      );
    });

    test('4. Learner registration creates pending enrollment by default',
        () async {
      final enr = await service.registerLearner(
        learnerId: 'learner_001',
        courseId: 'course_demo_101',
        actorId: 'learner_001',
        actorRole: 'learner',
        autoActivate: false,
      );

      expect(enr.status, equals(EnrollmentStatus.pending));
      expect(enr.isPending, isTrue);
      expect(enr.learnerId, equals('learner_001'));
      expect(enr.courseId, equals('course_demo_101'));

      final audit = await service.getAuditTrail(enrollmentId: enr.enrollmentId);
      expect(audit.length, equals(1));
      expect(audit.first.action, equals(EnrollmentAuditAction.created));
    });

    test(
        '5. Learner registration creates active enrollment when autoActivate is true',
        () async {
      final enr = await service.registerLearner(
        learnerId: 'learner_002',
        courseId: 'course_demo_101',
        actorId: 'faculty_demo',
        actorRole: 'faculty',
        autoActivate: true,
      );

      expect(enr.status, equals(EnrollmentStatus.active));
      expect(enr.isActive, isTrue);

      final audit = await service.getAuditTrail(enrollmentId: enr.enrollmentId);
      expect(audit.first.action, equals(EnrollmentAuditAction.activated));
    });

    test('6. Learner registration rejects empty learnerId or courseId',
        () async {
      expect(
        () => service.registerLearner(
          learnerId: '   ',
          courseId: 'course_demo_101',
          actorId: 'faculty_demo',
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );

      expect(
        () => service.registerLearner(
          learnerId: 'learner_001',
          courseId: '   ',
          actorId: 'faculty_demo',
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );
    });

    test('7. Learner registration throws if course does not exist', () async {
      expect(
        () => service.registerLearner(
          learnerId: 'learner_001',
          courseId: 'non_existent_course',
          actorId: 'faculty_demo',
        ),
        throwsA(isA<EnrollmentNotFoundException>()),
      );
    });

    test('8. Learner registration enforces tenant boundary', () async {
      await service.createCourse(
        courseId: 'course_tenant_b',
        title: 'Tenant B Course',
        examId: 'exam_b',
        tenantId: 'tenant_beta',
        facultyId: 'faculty_b',
      );

      // Attempting to register under default_tenant should fail
      expect(
        () => service.registerLearner(
          learnerId: 'learner_001',
          courseId: 'course_tenant_b',
          tenantId: 'default_tenant',
          actorId: 'faculty_demo',
        ),
        throwsA(isA<EnrollmentNotFoundException>()),
      );
    });

    test('9. Duplicate active enrollment is deterministically rejected',
        () async {
      await service.registerLearner(
        learnerId: 'learner_dup_active',
        courseId: 'course_demo_101',
        actorId: 'faculty_demo',
        autoActivate: true,
      );

      expect(
        () => service.registerLearner(
          learnerId: 'learner_dup_active',
          courseId: 'course_demo_101',
          actorId: 'faculty_demo',
          autoActivate: true,
        ),
        throwsA(isA<DuplicateEnrollmentException>()),
      );
    });

    test('10. Duplicate pending registration is rejected', () async {
      await service.registerLearner(
        learnerId: 'learner_dup_pending',
        courseId: 'course_demo_101',
        actorId: 'learner_dup_pending',
        autoActivate: false,
      );

      expect(
        () => service.registerLearner(
          learnerId: 'learner_dup_pending',
          courseId: 'course_demo_101',
          actorId: 'learner_dup_pending',
          autoActivate: false,
        ),
        throwsA(isA<DuplicateEnrollmentException>()),
      );
    });
  });

  group('P52: Prerequisites & Cohort Constraints', () {
    setUp(() async {
      await service.createCourse(
        courseId: 'prereq_intro_law',
        title: 'Introduction to Law',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
      );

      await service.createCourse(
        courseId: 'advanced_constitutional_litigation',
        title: 'Advanced Constitutional Litigation',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
        prerequisiteCourseIds: ['prereq_intro_law'],
      );
    });

    test('11. Prerequisite check blocks registration when uncompleted',
        () async {
      expect(
        () => service.registerLearner(
          learnerId: 'learner_unprepared',
          courseId: 'advanced_constitutional_litigation',
          actorId: 'faculty_1',
          autoActivate: true,
        ),
        throwsA(
          isA<PrerequisiteNotMetException>().having(
            (e) => e.missingPrerequisiteIds,
            'missingPrerequisiteIds',
            contains('prereq_intro_law'),
          ),
        ),
      );
    });

    test('12. Prerequisite satisfied allows registration', () async {
      // 1. Enroll and complete prerequisite
      final prereqEnr = await service.registerLearner(
        learnerId: 'learner_prepared',
        courseId: 'prereq_intro_law',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      await service.markCompletion(
        enrollmentId: prereqEnr.enrollmentId,
        actorId: 'faculty_1',
      );

      // 2. Now enroll in advanced course
      final advancedEnr = await service.registerLearner(
        learnerId: 'learner_prepared',
        courseId: 'advanced_constitutional_litigation',
        actorId: 'faculty_1',
        autoActivate: true,
      );

      expect(advancedEnr.status, equals(EnrollmentStatus.active));
      expect(
          advancedEnr.courseId, equals('advanced_constitutional_litigation'));
    });

    test('13. Cohort membership validation rejects non-members', () async {
      final cohort = Cohort(
        cohortId: 'cohort_alpha',
        name: 'Alpha Cohort',
        examId: 'clat_pg_2026',
        primaryFacultyId: 'faculty_1',
        learnerIds: ['learner_member_1', 'learner_member_2'],
      );
      await cohortRepo.saveCohort(cohort);

      expect(
        () => service.registerLearner(
          learnerId: 'outsider_learner',
          courseId: 'prereq_intro_law',
          cohortId: 'cohort_alpha',
          actorId: 'faculty_1',
          autoActivate: true,
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );
    });
  });

  group('P52: Lifecycle State Machine Transitions', () {
    late Enrollment pendingEnr;
    late Enrollment activeEnr;
    late Enrollment suspendedEnr;

    setUp(() async {
      await service.createCourse(
        courseId: 'lifecycle_course',
        title: 'Lifecycle Course',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
      );

      pendingEnr = await service.registerLearner(
        learnerId: 'learner_pending',
        courseId: 'lifecycle_course',
        actorId: 'faculty_1',
        autoActivate: false,
      );

      activeEnr = await service.registerLearner(
        learnerId: 'learner_active',
        courseId: 'lifecycle_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );

      final temp = await service.registerLearner(
        learnerId: 'learner_suspended',
        courseId: 'lifecycle_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      suspendedEnr = await service.suspendEnrollment(
        enrollmentId: temp.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Temporary disciplinary hold',
      );
    });

    test('14. Activate enrollment (PENDING -> ACTIVE) succeeds with audit log',
        () async {
      final activated = await service.activateEnrollment(
        enrollmentId: pendingEnr.enrollmentId,
        actorId: 'faculty_1',
      );

      expect(activated.status, equals(EnrollmentStatus.active));
      expect(activated.effectiveDate, isNotNull);

      final audit =
          await service.getAuditTrail(enrollmentId: activated.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.activated),
          isTrue);
    });

    test('15. Activate enrollment throws on illegal transition from ACTIVE',
        () async {
      expect(
        () => service.activateEnrollment(
          enrollmentId: activeEnr.enrollmentId,
          actorId: 'faculty_1',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });

    test(
        '16. Suspend enrollment (ACTIVE -> SUSPENDED) records reason and audit',
        () async {
      final suspended = await service.suspendEnrollment(
        enrollmentId: activeEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Payment pending review',
      );

      expect(suspended.status, equals(EnrollmentStatus.suspended));
      expect(suspended.statusReason, equals('Payment pending review'));
      expect(suspended.suspendedAt, isNotNull);

      final audit =
          await service.getAuditTrail(enrollmentId: suspended.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.suspended),
          isTrue);
    });

    test('17. Suspend enrollment rejects empty reason', () async {
      expect(
        () => service.suspendEnrollment(
          enrollmentId: activeEnr.enrollmentId,
          actorId: 'faculty_1',
          reason: '   ',
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );
    });

    test('18. Suspend enrollment throws on illegal transition from PENDING',
        () async {
      expect(
        () => service.suspendEnrollment(
          enrollmentId: pendingEnr.enrollmentId,
          actorId: 'faculty_1',
          reason: 'Premature suspension',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });

    test(
        '19. Reactivate enrollment (SUSPENDED -> ACTIVE) clears suspension details',
        () async {
      final reactivated = await service.reactivateEnrollment(
        enrollmentId: suspendedEnr.enrollmentId,
        actorId: 'faculty_1',
      );

      expect(reactivated.status, equals(EnrollmentStatus.active));
      expect(reactivated.suspendedAt, isNull);
      expect(reactivated.statusReason, isNull);

      final audit =
          await service.getAuditTrail(enrollmentId: reactivated.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.reactivated),
          isTrue);
    });

    test('20. Reactivate enrollment throws on illegal transition from PENDING',
        () async {
      expect(
        () => service.reactivateEnrollment(
          enrollmentId: pendingEnr.enrollmentId,
          actorId: 'faculty_1',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });

    test('21. Withdraw learner from ACTIVE transitions to WITHDRAWN', () async {
      final withdrawn = await service.withdrawLearner(
        enrollmentId: activeEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Relocation to another institution',
      );

      expect(withdrawn.status, equals(EnrollmentStatus.withdrawn));
      expect(
          withdrawn.statusReason, equals('Relocation to another institution'));
      expect(withdrawn.withdrawnAt, isNotNull);

      final audit =
          await service.getAuditTrail(enrollmentId: withdrawn.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.withdrawn),
          isTrue);
    });

    test('22. Withdraw learner from SUSPENDED transitions to WITHDRAWN',
        () async {
      final withdrawn = await service.withdrawLearner(
        enrollmentId: suspendedEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Voluntary withdrawal during suspension',
      );

      expect(withdrawn.status, equals(EnrollmentStatus.withdrawn));
    });

    test('23. Withdraw learner rejects empty reason', () async {
      expect(
        () => service.withdrawLearner(
          enrollmentId: activeEnr.enrollmentId,
          actorId: 'faculty_1',
          reason: '   ',
        ),
        throwsA(isA<EnrollmentValidationException>()),
      );
    });

    test('24. Withdraw learner throws on illegal transition from PENDING',
        () async {
      expect(
        () => service.withdrawLearner(
          enrollmentId: pendingEnr.enrollmentId,
          actorId: 'faculty_1',
          reason: 'Premature withdrawal',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });

    test('25. Cancel registration (PENDING -> CANCELLED) voids application',
        () async {
      final cancelled = await service.cancelEnrollment(
        enrollmentId: pendingEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Application withdrawn before verification',
      );

      expect(cancelled.status, equals(EnrollmentStatus.cancelled));
      expect(cancelled.cancelledAt, isNotNull);

      final audit =
          await service.getAuditTrail(enrollmentId: cancelled.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.cancelled),
          isTrue);
    });

    test('26. Cancel registration throws on illegal transition from ACTIVE',
        () async {
      expect(
        () => service.cancelEnrollment(
          enrollmentId: activeEnr.enrollmentId,
          actorId: 'faculty_1',
          reason: 'Cannot cancel active enrollment directly',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });

    test('27. Mark completion (ACTIVE -> COMPLETED) records completion',
        () async {
      final completed = await service.markCompletion(
        enrollmentId: activeEnr.enrollmentId,
        actorId: 'faculty_1',
      );

      expect(completed.status, equals(EnrollmentStatus.completed));
      expect(completed.completedAt, isNotNull);

      final audit =
          await service.getAuditTrail(enrollmentId: completed.enrollmentId);
      expect(audit.any((a) => a.action == EnrollmentAuditAction.completed),
          isTrue);
    });

    test('28. Mark completion throws on illegal transition from SUSPENDED',
        () async {
      expect(
        () => service.markCompletion(
          enrollmentId: suspendedEnr.enrollmentId,
          actorId: 'faculty_1',
        ),
        throwsA(isA<EnrollmentTransitionException>()),
      );
    });
  });

  group('P52: Course Access Control Gating', () {
    setUp(() async {
      await service.createCourse(
        courseId: 'access_course_101',
        title: 'Access Control Course',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
      );
    });

    test('29. checkCourseAccess resolves correct permission tier per status',
        () async {
      // 1. Not enrolled -> BLOCKED
      final notEnrolledDecision = await service.checkCourseAccess(
        learnerId: 'unregistered_learner',
        courseId: 'access_course_101',
      );
      expect(notEnrolledDecision.isAllowed, isFalse);
      expect(notEnrolledDecision.accessType, equals(CourseAccessType.blocked));

      // 2. Active -> FULL
      final activeEnr = await service.registerLearner(
        learnerId: 'learner_active_access',
        courseId: 'access_course_101',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      final activeDecision = await service.checkCourseAccess(
        learnerId: 'learner_active_access',
        courseId: 'access_course_101',
      );
      expect(activeDecision.isAllowed, isTrue);
      expect(activeDecision.accessType, equals(CourseAccessType.full));

      // 3. Completed -> READ-ONLY
      await service.markCompletion(
        enrollmentId: activeEnr.enrollmentId,
        actorId: 'faculty_1',
      );
      final completedDecision = await service.checkCourseAccess(
        learnerId: 'learner_active_access',
        courseId: 'access_course_101',
      );
      expect(completedDecision.isAllowed, isTrue);
      expect(completedDecision.accessType, equals(CourseAccessType.readOnly));

      // 4. Suspended -> BLOCKED
      final suspendedEnr = await service.registerLearner(
        learnerId: 'learner_suspended_access',
        courseId: 'access_course_101',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      await service.suspendEnrollment(
        enrollmentId: suspendedEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Hold',
      );
      final suspendedDecision = await service.checkCourseAccess(
        learnerId: 'learner_suspended_access',
        courseId: 'access_course_101',
      );
      expect(suspendedDecision.isAllowed, isFalse);
      expect(suspendedDecision.accessType, equals(CourseAccessType.blocked));
      expect(suspendedDecision.reason, contains('Hold'));

      // 5. Withdrawn -> BLOCKED
      await service.withdrawLearner(
        enrollmentId: suspendedEnr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Exit',
      );
      final withdrawnDecision = await service.checkCourseAccess(
        learnerId: 'learner_suspended_access',
        courseId: 'access_course_101',
      );
      expect(withdrawnDecision.isAllowed, isFalse);
      expect(withdrawnDecision.accessType, equals(CourseAccessType.blocked));

      // 6. Pending -> BLOCKED
      await service.registerLearner(
        learnerId: 'learner_pending_access',
        courseId: 'access_course_101',
        actorId: 'learner_pending_access',
        autoActivate: false,
      );
      final pendingDecision = await service.checkCourseAccess(
        learnerId: 'learner_pending_access',
        courseId: 'access_course_101',
      );
      expect(pendingDecision.isAllowed, isFalse);
      expect(pendingDecision.accessType, equals(CourseAccessType.blocked));
    });
  });

  group('P52: Bulk Cohort Enrollment & Resilience', () {
    test('30. bulkEnrollCohort handles partial failures gracefully', () async {
      await service.createCourse(
        courseId: 'prereq_course',
        title: 'Prerequisite Course',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
      );

      await service.createCourse(
        courseId: 'target_course',
        title: 'Target Course',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
        prerequisiteCourseIds: ['prereq_course'],
      );

      // Learner 1 has completed prereq
      final p1 = await service.registerLearner(
        learnerId: 'learner_1_ok',
        courseId: 'prereq_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      await service.markCompletion(
        enrollmentId: p1.enrollmentId,
        actorId: 'faculty_1',
      );

      // Learner 2 is already enrolled in target_course
      final p2 = await service.registerLearner(
        learnerId: 'learner_2_dup',
        courseId: 'prereq_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );
      await service.markCompletion(
        enrollmentId: p2.enrollmentId,
        actorId: 'faculty_1',
      );
      await service.registerLearner(
        learnerId: 'learner_2_dup',
        courseId: 'target_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );

      // Learner 3 has NOT completed prereq
      // (no action)

      final cohort = Cohort(
        cohortId: 'cohort_test_bulk',
        name: 'Bulk Cohort',
        examId: 'clat_pg_2026',
        primaryFacultyId: 'faculty_1',
        learnerIds: ['learner_1_ok', 'learner_2_dup', 'learner_3_noprereq'],
      );
      await cohortRepo.saveCohort(cohort);

      final bulkResult = await service.bulkEnrollCohort(
        courseId: 'target_course',
        cohortId: 'cohort_test_bulk',
        actorId: 'faculty_1',
        autoActivate: true,
      );

      expect(bulkResult.totalAttempted, equals(3));
      expect(bulkResult.successCount, equals(1));
      expect(bulkResult.failureCount, equals(2));
      expect(bulkResult.isPartialSuccess, isTrue);

      // Verify successful enrollment for learner_1_ok
      expect(
        bulkResult.successfulEnrollments
            .any((e) => e.learnerId == 'learner_1_ok'),
        isTrue,
      );

      // Verify individual failure reasons captured
      expect(bulkResult.failedLearnerIds.containsKey('learner_2_dup'), isTrue);
      expect(bulkResult.failedLearnerIds['learner_2_dup'],
          contains('DuplicateEnrollmentException'));

      expect(bulkResult.failedLearnerIds.containsKey('learner_3_noprereq'),
          isTrue);
      expect(bulkResult.failedLearnerIds['learner_3_noprereq'],
          contains('PrerequisiteNotMetException'));
    });
  });

  group('P52: Snapshot & Restart Persistence', () {
    test('31. exportSnapshot and importSnapshot persist and restore full state',
        () async {
      await service.createCourse(
        courseId: 'persist_course',
        title: 'Persistence 101',
        examId: 'clat_pg_2026',
        facultyId: 'faculty_1',
      );

      final enr = await service.registerLearner(
        learnerId: 'persist_learner',
        courseId: 'persist_course',
        actorId: 'faculty_1',
        autoActivate: true,
      );

      await service.suspendEnrollment(
        enrollmentId: enr.enrollmentId,
        actorId: 'faculty_1',
        reason: 'Temporary review',
      );

      // Export snapshot
      final snapshot = await service.exportSnapshot();
      expect(snapshot['courses'], isNotEmpty);
      expect(snapshot['enrollments'], isNotEmpty);
      expect(snapshot['auditRecords'], isNotEmpty);

      // Fresh repo and service simulating application restart
      final restoredRepo = InMemoryEnrollmentRepository();
      await restoredRepo.importSnapshot(snapshot);
      final restoredService =
          EnrollmentService(enrollmentRepository: restoredRepo);

      final fetchedCourse = await restoredService.getCourse('persist_course');
      expect(fetchedCourse, isNotNull);
      expect(fetchedCourse!.title, equals('Persistence 101'));

      final fetchedEnr = await restoredService.getEnrollment(enr.enrollmentId);
      expect(fetchedEnr, isNotNull);
      expect(fetchedEnr!.status, equals(EnrollmentStatus.suspended));
      expect(fetchedEnr.statusReason, equals('Temporary review'));

      final audit =
          await restoredService.getAuditTrail(enrollmentId: enr.enrollmentId);
      expect(audit.length, greaterThanOrEqualTo(2));
    });
  });
}
