/// Institutional Cohort & Assignment Management Service (TITAN-KO-048.0 P48).
///
/// Enterprise service orchestrating cohort creation, membership management,
/// assignment distribution, real learning completion tracking, deadline compliance,
/// and institutional analytics.
library;

import 'dart:async';

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/cohort.dart';
import '../domain/entities/cohort_assignment.dart';
import '../domain/entities/cohort_progress.dart';
import '../domain/entities/learner_analytics_report.dart';
import '../domain/entities/learner_objective_status.dart';

import '../repository/cohort_repository.dart';
import '../repository/learner_repository.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'curriculum_service.dart';
import 'learner_analytics_service.dart';

class CohortAssignmentService {
  final CohortRepository _cohortRepository;
  final LearnerRepository? _learnerRepository;
  final CurriculumService? _curriculumService;
  final AuthoritativeLearningStateRecoveryService? _authRecoveryService;
  final LearnerAnalyticsService? _analyticsService;
  final DateTime Function() _clock;

  final StreamController<CohortAssignmentEvent> _eventController =
      StreamController<CohortAssignmentEvent>.broadcast();

  CohortAssignmentService({
    required CohortRepository cohortRepository,
    LearnerRepository? learnerRepository,
    CurriculumService? curriculumService,
    AuthoritativeLearningStateRecoveryService? authRecoveryService,
    LearnerAnalyticsService? analyticsService,
    DateTime Function()? clock,
  })  : _cohortRepository = cohortRepository,
        _learnerRepository = learnerRepository,
        _curriculumService = curriculumService,
        _authRecoveryService = authRecoveryService,
        _analyticsService = analyticsService,
        _clock = clock ?? (() => DateTime.now().toUtc());

  LearnerRepository? get learnerRepository => _learnerRepository;
  CohortRepository get cohortRepository => _cohortRepository;

  /// Broadcast stream of assignment lifecycle and compliance events.
  Stream<CohortAssignmentEvent> get assignmentEvents => _eventController.stream;

  DateTime _now() => _clock().toUtc();

  // ---------------------------------------------------------------------------
  // 1. Cohort Lifecycle Management
  // ---------------------------------------------------------------------------

  /// Creates a new institutional cohort.
  Future<Cohort> createCohort({
    required String cohortId,
    String tenantId = 'default_tenant',
    required String name,
    String description = '',
    required String examId,
    required String primaryFacultyId,
    Iterable<String>? additionalFacultyIds,
    Iterable<String>? learnerIds,
    CohortStatus status = CohortStatus.active,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanId = cohortId.trim();
    if (cleanId.isEmpty) {
      throw CohortValidationException('cohortId cannot be empty');
    }
    final existing = await _cohortRepository.getCohortById(cleanId);
    if (existing != null) {
      throw CohortValidationException('Cohort "$cleanId" already exists');
    }

    final cohort = Cohort(
      cohortId: cleanId,
      tenantId: tenantId.trim(),
      name: name.trim(),
      description: description.trim(),
      examId: examId.trim(),
      primaryFacultyId: primaryFacultyId.trim(),
      additionalFacultyIds: additionalFacultyIds,
      learnerIds: learnerIds,
      status: status,
      createdAt: _now(),
      updatedAt: _now(),
      metadata: metadata,
    );

    await _cohortRepository.saveCohort(cohort);
    return cohort;
  }

  /// Updates an existing cohort's details.
  Future<Cohort> updateCohort(
    Cohort updated, {
    String? requesterId,
  }) async {
    final current = await _ensureCohortExists(updated.cohortId);
    _assertFacultyAuthorized(current, requesterId);

    final toSave = updated.copyWith(updatedAt: _now());
    await _cohortRepository.saveCohort(toSave);
    return toSave;
  }

  /// Archives a cohort.
  Future<Cohort> archiveCohort(
    String cohortId, {
    String? requesterId,
  }) async {
    final current = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(current, requesterId);

    final archived = current.copyWith(
      status: CohortStatus.archived,
      updatedAt: _now(),
    );
    await _cohortRepository.saveCohort(archived);
    return archived;
  }

  /// Retrieves a cohort by ID.
  Future<Cohort?> getCohort(String cohortId) =>
      _cohortRepository.getCohortById(cohortId.trim());

  /// Lists all cohorts matching criteria with tenant isolation.
  Future<List<Cohort>> listCohorts({
    String? tenantId,
    String? facultyId,
    String? learnerId,
    CohortStatus? status,
  }) {
    return _cohortRepository.listCohorts(
      tenantId: tenantId,
      facultyId: facultyId,
      learnerId: learnerId,
      status: status,
    );
  }

  /// Gets cohorts for a specific faculty member.
  Future<List<Cohort>> getCohortsForFaculty(
    String facultyId, {
    String? tenantId,
  }) {
    return _cohortRepository.listCohorts(
      facultyId: facultyId.trim(),
      tenantId: tenantId,
    );
  }

  /// Gets cohorts an enrolled learner belongs to.
  Future<List<Cohort>> getCohortsForLearner(
    String learnerId, {
    String? tenantId,
  }) {
    return _cohortRepository.listCohorts(
      learnerId: learnerId.trim(),
      tenantId: tenantId,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Membership Management
  // ---------------------------------------------------------------------------

  /// Enrolls a learner into a cohort (idempotent).
  Future<Cohort> addLearner(
    String cohortId,
    String learnerId, {
    String? requesterId,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(cohort, requesterId);

    final cleanLearner = learnerId.trim();
    if (cleanLearner.isEmpty) {
      throw CohortValidationException('learnerId cannot be empty');
    }

    final updated = cohort.addLearner(cleanLearner, updatedAt: _now());
    await _cohortRepository.saveCohort(updated);
    return updated;
  }

  /// Adds multiple learners idempotently.
  Future<Cohort> addLearners(
    String cohortId,
    Iterable<String> learnerIds, {
    String? requesterId,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(cohort, requesterId);

    Cohort current = cohort;
    for (final lid in learnerIds) {
      if (lid.trim().isNotEmpty) {
        current = current.addLearner(lid.trim(), updatedAt: _now());
      }
    }
    await _cohortRepository.saveCohort(current);
    return current;
  }

  /// Removes a learner from a cohort (preserves historical learning data).
  Future<Cohort> removeLearner(
    String cohortId,
    String learnerId, {
    String? requesterId,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(cohort, requesterId);

    final cleanLearner = learnerId.trim();
    final updated = cohort.removeLearner(cleanLearner, updatedAt: _now());
    await _cohortRepository.saveCohort(updated);
    return updated;
  }

  /// Lists member learner IDs for a cohort.
  Future<List<String>> listMembers(String cohortId) async {
    final cohort = await _ensureCohortExists(cohortId);
    final members = cohort.learnerIds.toList()..sort();
    return List.unmodifiable(members);
  }

  /// Checks if a learner is an enrolled member.
  Future<bool> checkMembership(String cohortId, String learnerId) async {
    final cohort = await _cohortRepository.getCohortById(cohortId.trim());
    if (cohort == null) return false;
    return cohort.hasLearner(learnerId.trim());
  }

  /// Assigns a faculty member to a cohort.
  Future<Cohort> assignFaculty(
    String cohortId,
    String facultyId, {
    bool isPrimary = false,
    String? requesterId,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(cohort, requesterId);

    final updated = cohort.addFaculty(
      facultyId.trim(),
      isPrimary: isPrimary,
      updatedAt: _now(),
    );
    await _cohortRepository.saveCohort(updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // 3. Assignment Management
  // ---------------------------------------------------------------------------

  /// Creates a new assignment for a cohort.
  Future<CohortAssignment> createAssignment({
    required String assignmentId,
    required String cohortId,
    String tenantId = 'default_tenant',
    required String title,
    String description = '',
    CohortAssignmentTargetType targetType =
        CohortAssignmentTargetType.objective,
    required String targetId,
    required String assignedByFacultyId,
    required DateTime dueDate,
    CohortAssignmentStatus status = CohortAssignmentStatus.draft,
    CohortAssignmentPassingCriteria passingCriteria =
        const CohortAssignmentPassingCriteria(),
    String? requesterId,
    Map<String, dynamic>? metadata,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    _assertFacultyAuthorized(cohort, requesterId ?? assignedByFacultyId);

    final cleanAssignId = assignmentId.trim();
    if (cleanAssignId.isEmpty) {
      throw CohortValidationException('assignmentId cannot be empty');
    }

    final existing = await _cohortRepository.getAssignmentById(cleanAssignId);
    if (existing != null) {
      throw CohortValidationException(
          'Assignment "$cleanAssignId" already exists');
    }

    _validateTarget(targetType, targetId);

    final assignment = CohortAssignment(
      assignmentId: cleanAssignId,
      cohortId: cohort.cohortId,
      tenantId: tenantId.trim(),
      title: title.trim(),
      description: description.trim(),
      targetType: targetType,
      targetId: targetId.trim(),
      assignedByFacultyId: assignedByFacultyId.trim(),
      dueDate: dueDate,
      status: status,
      passingCriteria: passingCriteria,
      createdAt: _now(),
      updatedAt: _now(),
      metadata: metadata,
    );

    await _cohortRepository.saveAssignment(assignment);

    if (status == CohortAssignmentStatus.published) {
      _emitEvent(CohortAssignmentEvent(
        assignmentId: assignment.assignmentId,
        cohortId: assignment.cohortId,
        type: CohortAssignmentEventType.published,
        timestamp: _now(),
      ));
    }

    return assignment;
  }

  /// Updates an existing draft assignment.
  Future<CohortAssignment> updateAssignment(
    CohortAssignment updated, {
    String? requesterId,
  }) async {
    final current = await _ensureAssignmentExists(updated.assignmentId);
    final cohort = await _ensureCohortExists(current.cohortId);
    _assertFacultyAuthorized(
        cohort, requesterId ?? current.assignedByFacultyId);

    if (current.status == CohortAssignmentStatus.closed) {
      throw CohortValidationException(
          'Cannot edit assignment "${current.assignmentId}" because it is closed');
    }

    _validateTarget(updated.targetType, updated.targetId);

    final toSave = updated.copyWith(updatedAt: _now());
    await _cohortRepository.saveAssignment(toSave);
    return toSave;
  }

  /// Publishes an assignment to cohort learners.
  Future<CohortAssignment> publishAssignment(
    String assignmentId, {
    required String facultyId,
  }) async {
    final assignment = await _ensureAssignmentExists(assignmentId);
    final cohort = await _ensureCohortExists(assignment.cohortId);
    _assertFacultyAuthorized(cohort, facultyId);

    if (assignment.status == CohortAssignmentStatus.closed) {
      throw CohortValidationException(
          'Cannot publish assignment "${assignment.assignmentId}" because it is closed');
    }

    final published = assignment.copyWith(
      status: CohortAssignmentStatus.published,
      updatedAt: _now(),
    );
    await _cohortRepository.saveAssignment(published);

    _emitEvent(CohortAssignmentEvent(
      assignmentId: published.assignmentId,
      cohortId: published.cohortId,
      type: CohortAssignmentEventType.published,
      timestamp: _now(),
    ));

    return published;
  }

  /// Closes an assignment, disabling further standard submissions.
  Future<CohortAssignment> closeAssignment(
    String assignmentId, {
    required String facultyId,
  }) async {
    final assignment = await _ensureAssignmentExists(assignmentId);
    final cohort = await _ensureCohortExists(assignment.cohortId);
    _assertFacultyAuthorized(cohort, facultyId);

    final closed = assignment.copyWith(
      status: CohortAssignmentStatus.closed,
      updatedAt: _now(),
    );
    await _cohortRepository.saveAssignment(closed);
    return closed;
  }

  /// Lists assignments for a specific cohort.
  Future<List<CohortAssignment>> getAssignmentsForCohort(
    String cohortId, {
    CohortAssignmentStatus? status,
  }) {
    return _cohortRepository.listAssignments(
      cohortId: cohortId.trim(),
      status: status,
    );
  }

  /// Lists visible assignments for a learner across all enrolled cohorts.
  Future<List<CohortAssignment>> getAssignmentsForLearner(
    String learnerId, {
    String? cohortId,
    DateTime? asOfDate,
    bool includeClosed = false,
  }) async {
    final cleanLearner = learnerId.trim();
    final assignments = await _cohortRepository.listAssignments(
      cohortId: cohortId,
      learnerId: cleanLearner,
    );

    return assignments.where((a) {
      if (a.status == CohortAssignmentStatus.draft) return false;
      if (a.status == CohortAssignmentStatus.closed && !includeClosed) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 4. Progress Derivation & Analytics
  // ---------------------------------------------------------------------------

  /// Evaluates real learning completion for a specific learner and assignment.
  Future<CohortLearnerProgress> getLearnerAssignmentProgress(
    String assignmentId,
    String learnerId, {
    DateTime? asOfDate,
    AuthoritativeLearnerState? authState,
  }) async {
    final assignment = await _ensureAssignmentExists(assignmentId);
    final cohort = await _ensureCohortExists(assignment.cohortId);

    final cleanLearner = learnerId.trim();
    if (!cohort.hasLearner(cleanLearner)) {
      throw CohortValidationException(
          'Learner "$cleanLearner" is not an enrolled member of cohort "${cohort.cohortId}"');
    }

    final effectiveDate = (asOfDate ?? _now()).toUtc();

    // 1. Resolve Authoritative Learner State
    AuthoritativeLearnerState? effectiveState = authState;
    if (effectiveState == null && _authRecoveryService != null) {
      try {
        final rec = await _authRecoveryService!.recover(
          learnerId: cleanLearner,
          examId: cohort.examId,
          requestedAt: effectiveDate,
        );
        effectiveState = rec.state;
      } catch (_) {
        // Recovery failed or state doesn't exist yet
      }
    }

    final criteria = assignment.passingCriteria;
    int attempts = 0;
    double accuracy = 0.0;
    bool isPassing = false;
    DateTime? completedAt;
    DateTime? lastActivityAt;
    String? masteryStage;

    if (effectiveState != null) {
      switch (assignment.targetType) {
        case CohortAssignmentTargetType.objective:
          final obj = effectiveState.progressMap[assignment.targetId];
          if (obj != null) {
            attempts = obj.attemptCount;
            accuracy = obj.successRate;
            masteryStage = obj.status.name;
            lastActivityAt = obj.lastAttemptAt;

            final hasAttempts = attempts >= criteria.minAttempts;
            final hasAccuracy = accuracy >= criteria.minAccuracy;
            final hasStage = criteria.requiredMasteryStage == null ||
                obj.status.name.toLowerCase() ==
                    criteria.requiredMasteryStage!.toLowerCase() ||
                obj.status == LearnerObjectiveStatus.achieved;

            isPassing = hasAttempts && hasAccuracy && hasStage;
            if (isPassing) {
              completedAt = obj.lastAttemptAt ?? effectiveDate;
            }
          }
          break;

        case CohortAssignmentTargetType.topic:
          // Check matching objectives under topic
          int totalTopicAttempts = 0;
          int totalTopicCorrect = 0;
          for (final entry in effectiveState.progressMap.entries) {
            if (entry.key
                .toLowerCase()
                .contains(assignment.targetId.toLowerCase())) {
              totalTopicAttempts += entry.value.attemptCount;
              totalTopicCorrect += entry.value.correctCount;
              if (lastActivityAt == null ||
                  (entry.value.lastAttemptAt != null &&
                      entry.value.lastAttemptAt!.isAfter(lastActivityAt))) {
                lastActivityAt = entry.value.lastAttemptAt;
              }
            }
          }
          if (totalTopicAttempts > 0) {
            attempts = totalTopicAttempts;
            accuracy = totalTopicCorrect / totalTopicAttempts;
            isPassing = attempts >= criteria.minAttempts &&
                accuracy >= criteria.minAccuracy;
            if (isPassing) {
              completedAt = lastActivityAt ?? effectiveDate;
            }
          }
          break;

        default:
          // General target evaluation
          final obj = effectiveState.progressMap[assignment.targetId];
          if (obj != null) {
            attempts = obj.attemptCount;
            accuracy = obj.successRate;
            isPassing = attempts >= criteria.minAttempts &&
                accuracy >= criteria.minAccuracy;
            if (isPassing) {
              completedAt = obj.lastAttemptAt ?? effectiveDate;
            }
          }
          break;
      }
    }

    CohortLearnerProgressStatus status;
    if (isPassing) {
      status = CohortLearnerProgressStatus.completed;
    } else if (attempts > 0) {
      if (assignment.isOverdue(effectiveDate)) {
        status = CohortLearnerProgressStatus.overdue;
      } else {
        status = CohortLearnerProgressStatus.inProgress;
      }
    } else {
      if (assignment.isOverdue(effectiveDate)) {
        status = CohortLearnerProgressStatus.overdue;
      } else {
        status = CohortLearnerProgressStatus.notStarted;
      }
    }

    return CohortLearnerProgress(
      assignmentId: assignment.assignmentId,
      cohortId: cohort.cohortId,
      learnerId: cleanLearner,
      status: status,
      attempts: attempts,
      accuracy: accuracy,
      isPassing: isPassing,
      completedAt: completedAt,
      lastActivityAt: lastActivityAt,
      targetId: assignment.targetId,
      targetType: assignment.targetType,
      masteryStage: masteryStage,
    );
  }

  /// Computes a cohort-wide summary for a single assignment.
  Future<CohortAssignmentSummary> computeAssignmentSummary(
    String assignmentId, {
    DateTime? asOfDate,
    Map<String, AuthoritativeLearnerState>? learnerStates,
  }) async {
    final assignment = await _ensureAssignmentExists(assignmentId);
    final cohort = await _ensureCohortExists(assignment.cohortId);

    final progressList = <CohortLearnerProgress>[];
    int completedCount = 0;
    int inProgressCount = 0;
    int overdueCount = 0;
    int notStartedCount = 0;

    for (final learnerId in cohort.learnerIds) {
      final prog = await getLearnerAssignmentProgress(
        assignment.assignmentId,
        learnerId,
        asOfDate: asOfDate,
        authState: learnerStates?[learnerId],
      );
      progressList.add(prog);

      switch (prog.status) {
        case CohortLearnerProgressStatus.completed:
          completedCount++;
          break;
        case CohortLearnerProgressStatus.inProgress:
          inProgressCount++;
          break;
        case CohortLearnerProgressStatus.overdue:
          overdueCount++;
          break;
        case CohortLearnerProgressStatus.notStarted:
          notStartedCount++;
          break;
      }
    }

    progressList.sort((a, b) => a.learnerId.compareTo(b.learnerId));

    return CohortAssignmentSummary(
      assignment: assignment,
      totalAssigned: cohort.learnerCount,
      completedCount: completedCount,
      inProgressCount: inProgressCount,
      overdueCount: overdueCount,
      notStartedCount: notStartedCount,
      learnerProgressList: progressList,
    );
  }

  /// Computes a comprehensive summary of an institutional cohort.
  Future<CohortSummary> computeCohortSummary(
    String cohortId, {
    DateTime? asOfDate,
    Map<String, AuthoritativeLearnerState>? learnerStates,
  }) async {
    final cohort = await _ensureCohortExists(cohortId);
    final assignments = await _cohortRepository.listAssignments(
      cohortId: cohort.cohortId,
    );

    final publishedAssignments = assignments
        .where((a) =>
            a.status == CohortAssignmentStatus.published ||
            a.status == CohortAssignmentStatus.closed)
        .toList();

    final assignmentSummaries = <CohortAssignmentSummary>[];
    int totalCompleted = 0;
    int totalOverdue = 0;
    final activeLearnerIds = <String>{};
    double totalAccuracySum = 0.0;
    int accuracyDataPoints = 0;

    for (final assignment in publishedAssignments) {
      final summary = await computeAssignmentSummary(
        assignment.assignmentId,
        asOfDate: asOfDate,
        learnerStates: learnerStates,
      );
      assignmentSummaries.add(summary);
      totalCompleted += summary.completedCount;
      totalOverdue += summary.overdueCount;

      for (final p in summary.learnerProgressList) {
        if (p.attempts > 0) {
          activeLearnerIds.add(p.learnerId);
          totalAccuracySum += p.accuracy;
          accuracyDataPoints++;
        }
      }
    }

    final totalOpportunities =
        cohort.learnerCount * publishedAssignments.length;
    final completionRate =
        totalOpportunities == 0 ? 0.0 : (totalCompleted / totalOpportunities);

    final avgAccuracy =
        accuracyDataPoints == 0 ? 0.0 : (totalAccuracySum / accuracyDataPoints);

    // Identify weak areas across cohort
    final weakAreas = <String>[];
    for (final summary in assignmentSummaries) {
      if (summary.totalAssigned > 0) {
        final failRate = (summary.overdueCount +
                summary.inProgressCount +
                summary.notStartedCount) /
            summary.totalAssigned;
        if (failRate >= 0.50 &&
            !weakAreas.contains(summary.assignment.targetId)) {
          weakAreas.add(summary.assignment.targetId);
        }
      }
    }

    return CohortSummary(
      cohort: cohort,
      totalLearners: cohort.learnerCount,
      activeLearners: activeLearnerIds.length,
      totalAssignments: publishedAssignments.length,
      completedAssignmentsCount: totalCompleted,
      overdueCount: totalOverdue,
      completionRate: completionRate,
      averageAccuracy: avgAccuracy,
      weakAreas: weakAreas,
      assignmentSummaries: assignmentSummaries,
    );
  }

  /// Computes deep cohort analytics with weak spot diagnostics.
  Future<CohortAnalyticsReport> computeCohortAnalytics(
    String cohortId, {
    DateTime? asOfDate,
    Map<String, AuthoritativeLearnerState>? learnerStates,
  }) async {
    final summary = await computeCohortSummary(
      cohortId,
      asOfDate: asOfDate,
      learnerStates: learnerStates,
    );

    final weakSpotDetails = <WeakAreaMetric>[];
    if (_analyticsService != null) {
      for (final learnerId in summary.cohort.learnerIds) {
        try {
          final rep = await _analyticsService!.computeLearnerReport(
            learnerId: learnerId,
            examId: summary.cohort.examId,
            authState: learnerStates?[learnerId],
            asOfDate: asOfDate,
          );
          for (final w in rep.weakAreas) {
            final existing = weakSpotDetails.indexWhere((e) => e.id == w.id);
            if (existing == -1) {
              weakSpotDetails.add(w);
            }
          }
        } catch (_) {
          // Analytics lookup skipped if learner data absent
        }
      }
    }

    return CohortAnalyticsReport(
      summary: summary,
      assignmentSummaries: summary.assignmentSummaries,
      weakObjectiveDetails: weakSpotDetails,
      generatedAt: _now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers & Validation
  // ---------------------------------------------------------------------------

  Future<Cohort> _ensureCohortExists(String cohortId) async {
    final cohort = await _cohortRepository.getCohortById(cohortId.trim());
    if (cohort == null) {
      throw CohortNotFoundException('Cohort "$cohortId" does not exist');
    }
    return cohort;
  }

  Future<CohortAssignment> _ensureAssignmentExists(String assignmentId) async {
    final assignment =
        await _cohortRepository.getAssignmentById(assignmentId.trim());
    if (assignment == null) {
      throw CohortNotFoundException(
          'Assignment "$assignmentId" does not exist');
    }
    return assignment;
  }

  void _assertFacultyAuthorized(Cohort cohort, String? requesterId) {
    if (requesterId == null) return; // Unrestricted if not provided
    final clean = requesterId.trim();
    if (clean == 'tenant_admin' || clean == 'admin') return;
    if (!cohort.hasFaculty(clean)) {
      throw CohortSecurityException(
          'Faculty "$clean" is not authorized to manage cohort "${cohort.cohortId}"');
    }
  }

  void _validateTarget(CohortAssignmentTargetType type, String targetId) {
    final clean = targetId.trim();
    if (clean.isEmpty) {
      throw CohortValidationException('Assignment targetId cannot be empty');
    }

    if (_curriculumService != null) {
      if (type == CohortAssignmentTargetType.objective) {
        final framework = _curriculumService!.framework;
        if (!framework.objectiveMap.containsKey(clean)) {
          throw CohortValidationException(
              'Target objective "$clean" not found in curriculum framework "${framework.id}"');
        }
      }
    }
  }

  void _emitEvent(CohortAssignmentEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    _eventController.close();
  }
}
