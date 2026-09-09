/// Learner Course Enrollment Orchestration Service (TITAN-KO-052.0 P52).
///
/// Enterprise service managing institutional course registration, eligibility
/// evaluation (prerequisites & cohort constraints), strict enrollment lifecycle
/// state transitions, course access control decisions (FULL, READ_ONLY, BLOCKED),
/// bulk cohort enrollment, and immutable audit logging.
library;

import '../domain/entities/bulk_enrollment_result.dart';
import '../domain/entities/course.dart';
import '../domain/entities/course_access_decision.dart';
import '../domain/entities/enrollment.dart';
import '../domain/entities/enrollment_audit_record.dart';
import '../repository/cohort_repository.dart';
import '../repository/credential_repository.dart';
import '../repository/enrollment_repository.dart';

class EnrollmentService {
  final EnrollmentRepository enrollmentRepository;
  final CohortRepository? cohortRepository;
  final CredentialRepository? credentialRepository;
  final DateTime Function() _clock;

  EnrollmentService({
    required this.enrollmentRepository,
    this.cohortRepository,
    this.credentialRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  // ---------------------------------------------------------------------------
  // 1. Course Management
  // ---------------------------------------------------------------------------

  /// Creates and persists a new course/program offering.
  Future<Course> createCourse({
    required String courseId,
    required String title,
    String description = '',
    required String examId,
    String tenantId = 'default_tenant',
    required String facultyId,
    Iterable<String>? prerequisiteCourseIds,
    Iterable<String>? cohortIds,
    CourseStatus status = CourseStatus.active,
    int estimatedHours = 40,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanCourseId = courseId.trim();
    final cleanTenantId = tenantId.trim();

    final existing = await enrollmentRepository.getCourse(
      cleanCourseId,
      tenantId: cleanTenantId,
    );
    if (existing != null) {
      throw EnrollmentValidationException(
        'Course with ID "$cleanCourseId" already exists in tenant "$cleanTenantId".',
      );
    }

    final now = _clock();
    final course = Course(
      courseId: cleanCourseId,
      title: title.trim(),
      description: description.trim(),
      examId: examId.trim(),
      tenantId: cleanTenantId,
      facultyId: facultyId.trim(),
      prerequisiteCourseIds: prerequisiteCourseIds,
      cohortIds: cohortIds,
      status: status,
      estimatedHours: estimatedHours,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );

    await enrollmentRepository.saveCourse(course);
    return course;
  }

  /// Retrieves a course by ID.
  Future<Course?> getCourse(String courseId, {String? tenantId}) async {
    return enrollmentRepository.getCourse(courseId.trim(), tenantId: tenantId);
  }

  /// Lists all courses matching tenant and optional status filter.
  Future<List<Course>> listCourses({
    String? tenantId,
    CourseStatus? status,
  }) async {
    return enrollmentRepository.listCourses(tenantId: tenantId, status: status);
  }

  /// Archives a course offering.
  Future<Course> archiveCourse({
    required String courseId,
    required String actorId,
    String? tenantId,
  }) async {
    final course = await enrollmentRepository.getCourse(courseId.trim(),
        tenantId: tenantId);
    if (course == null) {
      throw EnrollmentNotFoundException('Course not found: $courseId');
    }
    final updated = course.copyWith(
      status: CourseStatus.archived,
      updatedAt: _clock(),
    );
    await enrollmentRepository.saveCourse(updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // 2. Eligibility & Prerequisite Evaluation
  // ---------------------------------------------------------------------------

  /// Determines prerequisite courses not yet completed by the learner.
  Future<List<String>> getMissingPrerequisites({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    final course = await enrollmentRepository.getCourse(courseId.trim(),
        tenantId: tenantId);
    if (course == null) {
      throw EnrollmentNotFoundException('Course not found: $courseId');
    }

    if (course.prerequisiteCourseIds.isEmpty) {
      return const [];
    }

    final learnerEnrollments =
        await enrollmentRepository.listEnrollmentsForLearner(
      learnerId: learnerId.trim(),
      tenantId: tenantId,
    );

    final completedCourseIds = learnerEnrollments
        .where((e) => e.status == EnrollmentStatus.completed)
        .map((e) => e.courseId)
        .toSet();

    final missing = <String>[];
    for (final prereqId in course.prerequisiteCourseIds) {
      if (!completedCourseIds.contains(prereqId)) {
        missing.add(prereqId);
      }
    }
    return missing;
  }

  /// Checks if a learner meets all eligibility rules to enroll in a course.
  Future<bool> checkEligibility({
    required String learnerId,
    required String courseId,
    String? cohortId,
    String? tenantId,
  }) async {
    final missingPrereqs = await getMissingPrerequisites(
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
    if (missingPrereqs.isNotEmpty) {
      throw PrerequisiteNotMetException(
        'Learner $learnerId has not completed prerequisite courses: ${missingPrereqs.join(", ")}',
        missingPrerequisiteIds: missingPrereqs,
      );
    }

    // If cohort specified and cohortRepository available, check membership
    if (cohortId != null &&
        cohortId.trim().isNotEmpty &&
        cohortRepository != null) {
      final cohort = await cohortRepository!.getCohortById(cohortId.trim());
      if (cohort == null) {
        throw EnrollmentNotFoundException('Cohort not found: $cohortId');
      }
      if (!cohort.learnerIds.contains(learnerId.trim())) {
        throw EnrollmentValidationException(
          'Learner $learnerId is not a member of cohort $cohortId',
        );
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // 3. Learner Course Registration & Activation
  // ---------------------------------------------------------------------------

  /// Enrolls a learner into a course.
  ///
  /// Enforces:
  /// 1. Course existence & tenant match
  /// 2. Duplicate active enrollment prevention
  /// 3. Prerequisite validation
  /// 4. Cohort membership validation
  /// 5. Lifecycle auditing
  Future<Enrollment> registerLearner({
    required String learnerId,
    required String courseId,
    String? cohortId,
    String tenantId = 'default_tenant',
    required String actorId,
    String actorRole = 'faculty',
    bool autoActivate = false,
    DateTime? effectiveDate,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCourseId = courseId.trim();
    final cleanTenantId = tenantId.trim();
    final cleanActorId = actorId.trim();

    if (cleanLearnerId.isEmpty) {
      throw EnrollmentValidationException('learnerId cannot be empty');
    }
    if (cleanCourseId.isEmpty) {
      throw EnrollmentValidationException('courseId cannot be empty');
    }

    // 1. Verify course exists
    final course = await enrollmentRepository.getCourse(
      cleanCourseId,
      tenantId: cleanTenantId,
    );
    if (course == null) {
      throw EnrollmentNotFoundException(
        'Course "$cleanCourseId" not found in tenant "$cleanTenantId".',
      );
    }

    // 2. Prevent duplicate active enrollment
    final activeEnr =
        await enrollmentRepository.getActiveEnrollmentForLearnerCourse(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      tenantId: cleanTenantId,
    );
    if (activeEnr != null) {
      throw DuplicateEnrollmentException(
        'Learner $cleanLearnerId is already actively enrolled in course $cleanCourseId (Enrollment: ${activeEnr.enrollmentId}).',
      );
    }

    // Check for pending duplicate
    final existingEnrollments = await enrollmentRepository.listEnrollments(
      tenantId: cleanTenantId,
      courseId: cleanCourseId,
      learnerId: cleanLearnerId,
      status: EnrollmentStatus.pending,
    );
    if (existingEnrollments.isNotEmpty) {
      throw DuplicateEnrollmentException(
        'Learner $cleanLearnerId already has a pending registration for course $cleanCourseId.',
      );
    }

    // 3. Prerequisite & Cohort Eligibility
    await checkEligibility(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      cohortId: cohortId,
      tenantId: cleanTenantId,
    );

    // 4. Generate Enrollment ID & Model
    final enrollmentId = Enrollment.generateId(
      courseId: cleanCourseId,
      learnerId: cleanLearnerId,
      cohortId: cohortId,
    );

    final now = _clock();
    final initialStatus =
        autoActivate ? EnrollmentStatus.active : EnrollmentStatus.pending;

    final enrollment = Enrollment(
      enrollmentId: enrollmentId,
      tenantId: cleanTenantId,
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      courseTitle: course.title,
      cohortId: cohortId?.trim(),
      status: initialStatus,
      enrolledAt: now,
      effectiveDate: autoActivate ? (effectiveDate ?? now) : effectiveDate,
      enrolledBy: cleanActorId,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );

    await enrollmentRepository.saveEnrollment(enrollment);

    // 5. Save Immutable Audit Record
    final audit = EnrollmentAuditRecord(
      auditId: 'audit_${enrollmentId}_${now.millisecondsSinceEpoch}',
      tenantId: cleanTenantId,
      enrollmentId: enrollmentId,
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      cohortId: cohortId?.trim(),
      action: autoActivate
          ? EnrollmentAuditAction.activated
          : EnrollmentAuditAction.created,
      actorId: cleanActorId,
      actorRole: actorRole,
      previousStatus: null,
      newStatus: initialStatus,
      reason: autoActivate
          ? 'Direct faculty enrollment with auto-activation'
          : 'Self or faculty registration',
      timestamp: now,
    );
    await enrollmentRepository.saveAuditRecord(audit);

    return enrollment;
  }

  // ---------------------------------------------------------------------------
  // 4. Lifecycle State Transitions
  // ---------------------------------------------------------------------------

  /// Activates a pending enrollment (PENDING -> ACTIVE).
  Future<Enrollment> activateEnrollment({
    required String enrollmentId,
    required String actorId,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated = enr.activate(actorId: actorId, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId: 'audit_${enrollmentId}_activate_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.activated,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.active,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Temporarily suspends an active enrollment (ACTIVE -> SUSPENDED).
  Future<Enrollment> suspendEnrollment({
    required String enrollmentId,
    required String actorId,
    required String reason,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw EnrollmentValidationException('Suspension reason cannot be empty');
    }

    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated = enr.suspend(actorId: actorId, reason: cleanReason, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId: 'audit_${enrollmentId}_suspend_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.suspended,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.suspended,
        reason: cleanReason,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Reactivates a suspended enrollment (SUSPENDED -> ACTIVE).
  Future<Enrollment> reactivateEnrollment({
    required String enrollmentId,
    required String actorId,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated = enr.reactivate(actorId: actorId, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId:
            'audit_${enrollmentId}_reactivate_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.reactivated,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.active,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Formally withdraws a learner from a course (ACTIVE or SUSPENDED -> WITHDRAWN).
  ///
  /// CRITICAL: Historical academic records (attempts, grades, certificates)
  /// are strictly preserved and unaffected.
  Future<Enrollment> withdrawLearner({
    required String enrollmentId,
    required String actorId,
    required String reason,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw EnrollmentValidationException('Withdrawal reason cannot be empty');
    }

    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated =
        enr.withdraw(actorId: actorId, reason: cleanReason, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId: 'audit_${enrollmentId}_withdraw_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.withdrawn,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.withdrawn,
        reason: cleanReason,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Cancels a pending enrollment (PENDING -> CANCELLED).
  Future<Enrollment> cancelEnrollment({
    required String enrollmentId,
    required String actorId,
    required String reason,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw EnrollmentValidationException(
          'Cancellation reason cannot be empty');
    }

    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated = enr.cancel(actorId: actorId, reason: cleanReason, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId: 'audit_${enrollmentId}_cancel_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.cancelled,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.cancelled,
        reason: cleanReason,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Completes an active enrollment (ACTIVE -> COMPLETED).
  Future<Enrollment> markCompletion({
    required String enrollmentId,
    required String actorId,
    String actorRole = 'faculty',
    String? tenantId,
  }) async {
    final enr = await _getExistingEnrollment(enrollmentId, tenantId: tenantId);
    final previousStatus = enr.status;
    final now = _clock();

    final updated = enr.complete(actorId: actorId, at: now);
    await enrollmentRepository.saveEnrollment(updated);

    await enrollmentRepository.saveAuditRecord(
      EnrollmentAuditRecord(
        auditId: 'audit_${enrollmentId}_complete_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        enrollmentId: updated.enrollmentId,
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        action: EnrollmentAuditAction.completed,
        actorId: actorId.trim(),
        actorRole: actorRole,
        previousStatus: previousStatus,
        newStatus: EnrollmentStatus.completed,
        timestamp: now,
      ),
    );

    return updated;
  }

  // ---------------------------------------------------------------------------
  // 5. Course Access Control Gating
  // ---------------------------------------------------------------------------

  /// Deterministically evaluates whether a learner can access a course, and at what tier.
  ///
  /// - `active` -> CourseAccessType.full
  /// - `completed` -> CourseAccessType.readOnly (historical review)
  /// - `suspended` -> CourseAccessType.blocked
  /// - `withdrawn` -> CourseAccessType.blocked
  /// - `pending` -> CourseAccessType.blocked
  /// - `cancelled` or none -> CourseAccessType.blocked
  Future<CourseAccessDecision> checkCourseAccess({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCourseId = courseId.trim();

    final enrollments = await enrollmentRepository.listEnrollmentsForLearner(
      learnerId: cleanLearnerId,
      tenantId: tenantId,
    );

    final matching =
        enrollments.where((e) => e.courseId == cleanCourseId).toList();
    if (matching.isEmpty) {
      return CourseAccessDecision.blocked(
        learnerId: cleanLearnerId,
        courseId: cleanCourseId,
        reason: 'Learner is not enrolled in course $cleanCourseId.',
      );
    }

    // Sort by status priority: active > completed > suspended > withdrawn > pending > cancelled
    matching.sort((a, b) =>
        _statusPriority(a.status).compareTo(_statusPriority(b.status)));
    final primary = matching.first;

    switch (primary.status) {
      case EnrollmentStatus.active:
        return CourseAccessDecision.full(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
        );
      case EnrollmentStatus.completed:
        return CourseAccessDecision.readOnly(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
        );
      case EnrollmentStatus.suspended:
        return CourseAccessDecision.blocked(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
          status: EnrollmentStatus.suspended,
          reason:
              'Enrollment suspended: ${primary.statusReason ?? "Administrative hold."}',
        );
      case EnrollmentStatus.withdrawn:
        return CourseAccessDecision.blocked(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
          status: EnrollmentStatus.withdrawn,
          reason:
              'Learner withdrawn: ${primary.statusReason ?? "Formal withdrawal."}',
        );
      case EnrollmentStatus.pending:
        return CourseAccessDecision.blocked(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
          status: EnrollmentStatus.pending,
          reason:
              'Enrollment is pending approval or prerequisite verification.',
        );
      case EnrollmentStatus.cancelled:
        return CourseAccessDecision.blocked(
          learnerId: cleanLearnerId,
          courseId: cleanCourseId,
          status: EnrollmentStatus.cancelled,
          reason:
              'Registration was cancelled: ${primary.statusReason ?? "Cancelled."}',
        );
    }
  }

  int _statusPriority(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.active:
        return 1;
      case EnrollmentStatus.completed:
        return 2;
      case EnrollmentStatus.suspended:
        return 3;
      case EnrollmentStatus.withdrawn:
        return 4;
      case EnrollmentStatus.pending:
        return 5;
      case EnrollmentStatus.cancelled:
        return 6;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. Bulk Cohort Enrollment
  // ---------------------------------------------------------------------------

  /// Bulk enrolls a cohort or list of learners into a course.
  ///
  /// Resilient: Individual failures (duplicate, missing prerequisite) do not
  /// abort or fail other learners. Granular outcomes reported via BulkEnrollmentResult.
  Future<BulkEnrollmentResult> bulkEnrollCohort({
    required String courseId,
    required String cohortId,
    required String actorId,
    String actorRole = 'faculty',
    String tenantId = 'default_tenant',
    bool autoActivate = true,
    Iterable<String>? explicitLearnerIds,
  }) async {
    final cleanCourseId = courseId.trim();
    final cleanCohortId = cohortId.trim();
    final cleanTenantId = tenantId.trim();
    final cleanActorId = actorId.trim();

    final course = await enrollmentRepository.getCourse(
      cleanCourseId,
      tenantId: cleanTenantId,
    );
    if (course == null) {
      throw EnrollmentNotFoundException('Course not found: $cleanCourseId');
    }

    Set<String> candidateLearnerIds;
    if (explicitLearnerIds != null && explicitLearnerIds.isNotEmpty) {
      candidateLearnerIds = explicitLearnerIds.map((id) => id.trim()).toSet();
    } else if (cohortRepository != null) {
      final cohort = await cohortRepository!.getCohortById(cleanCohortId);
      if (cohort == null) {
        throw EnrollmentNotFoundException('Cohort not found: $cleanCohortId');
      }
      candidateLearnerIds = cohort.learnerIds.toSet();
    } else {
      throw EnrollmentValidationException(
        'Neither explicitLearnerIds nor CohortRepository provided for bulk enrollment.',
      );
    }

    final successfulEnrollments = <Enrollment>[];
    final failedLearnerIds = <String, String>{};

    for (final learnerId in candidateLearnerIds) {
      try {
        final enr = await registerLearner(
          learnerId: learnerId,
          courseId: cleanCourseId,
          cohortId: cleanCohortId,
          tenantId: cleanTenantId,
          actorId: cleanActorId,
          actorRole: actorRole,
          autoActivate: autoActivate,
        );
        successfulEnrollments.add(enr);
      } catch (e) {
        failedLearnerIds[learnerId] = e.toString();
      }
    }

    return BulkEnrollmentResult(
      courseId: cleanCourseId,
      cohortId: cleanCohortId,
      totalAttempted: candidateLearnerIds.length,
      successfulEnrollments: successfulEnrollments,
      failedLearnerIds: failedLearnerIds,
      timestamp: _clock(),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Query Helpers
  // ---------------------------------------------------------------------------

  Future<Enrollment?> getEnrollment(String enrollmentId, {String? tenantId}) {
    return enrollmentRepository.getEnrollment(enrollmentId.trim(),
        tenantId: tenantId);
  }

  Future<List<Enrollment>> getLearnerEnrollments({
    required String learnerId,
    String? tenantId,
  }) {
    return enrollmentRepository.listEnrollmentsForLearner(
      learnerId: learnerId.trim(),
      tenantId: tenantId,
    );
  }

  Future<List<Enrollment>> getCourseEnrollments({
    required String courseId,
    String? tenantId,
    EnrollmentStatus? status,
  }) {
    return enrollmentRepository.listEnrollments(
      courseId: courseId.trim(),
      tenantId: tenantId,
      status: status,
    );
  }

  Future<List<Enrollment>> getCohortEnrollments({
    required String cohortId,
    String? tenantId,
  }) {
    return enrollmentRepository.listEnrollmentsForCohort(
      cohortId: cohortId.trim(),
      tenantId: tenantId,
    );
  }

  Future<List<EnrollmentAuditRecord>> getAuditTrail({
    required String enrollmentId,
    String? tenantId,
  }) {
    return enrollmentRepository.listAuditRecords(
      enrollmentId: enrollmentId.trim(),
      tenantId: tenantId,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> exportSnapshot() {
    return enrollmentRepository.exportSnapshot();
  }

  Future<void> importSnapshot(Map<String, dynamic> snapshot) {
    return enrollmentRepository.importSnapshot(snapshot);
  }

  Future<void> clear() {
    return enrollmentRepository.clear();
  }

  // ---------------------------------------------------------------------------
  // Private Helper
  // ---------------------------------------------------------------------------

  Future<Enrollment> _getExistingEnrollment(
    String enrollmentId, {
    String? tenantId,
  }) async {
    final enr = await enrollmentRepository.getEnrollment(
      enrollmentId.trim(),
      tenantId: tenantId,
    );
    if (enr == null) {
      throw EnrollmentNotFoundException(
        'Enrollment "$enrollmentId" not found.',
      );
    }
    return enr;
  }
}
