/// Gradebook Orchestrator Service (TITAN-KO-050.0 P50).
///
/// Enterprise service managing the institutional evaluation lifecycle:
/// cohort gradebook assembly, explicit grade publication, bulk publication,
/// learner grade dispute workflow, faculty review, grade overrides,
/// immutable audit trail logging, and multi-tenant isolation.
library;

import '../domain/entities/assessment_attempt.dart';
import '../domain/entities/assessment_result.dart';
import '../domain/entities/cohort.dart';
import '../domain/entities/cohort_gradebook.dart';
import '../domain/entities/grade_audit_record.dart';
import '../domain/entities/grade_dispute.dart';
import '../domain/entities/grade_override.dart';
import '../domain/entities/gradebook_entry.dart';
import '../domain/entities/grading_policy.dart';
import '../repository/assessment_repository.dart';
import '../repository/cohort_repository.dart';
import '../repository/gradebook_repository.dart';
import '../repository/in_memory_assessment_repository.dart';
import '../repository/in_memory_cohort_repository.dart';

class GradebookService {
  final GradebookRepository _repository;
  final AssessmentRepository _assessmentRepository;
  final CohortRepository _cohortRepository;
  final GradingPolicy _gradingPolicy;
  final DateTime Function() _clock;

  GradebookService({
    required GradebookRepository repository,
    AssessmentRepository? assessmentRepository,
    CohortRepository? cohortRepository,
    GradingPolicy gradingPolicy = const GradingPolicy.standard(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _assessmentRepository =
            assessmentRepository ?? InMemoryAssessmentRepository(),
        _cohortRepository = cohortRepository ?? InMemoryCohortRepository(),
        _gradingPolicy = gradingPolicy,
        _clock = clock ?? (() => DateTime.now().toUtc());

  DateTime _now() => _clock().toUtc();

  GradebookRepository get repository => _repository;
  AssessmentRepository get assessmentRepository => _assessmentRepository;
  CohortRepository get cohortRepository => _cohortRepository;
  GradingPolicy get gradingPolicy => _gradingPolicy;

  // ---------------------------------------------------------------------------
  // 1. Result Ingestion & Gradebook Assembly
  // ---------------------------------------------------------------------------

  /// Ingests an evaluated assessment result into the gradebook.
  Future<GradebookEntry> ingestAssessmentResult({
    required String entryId,
    required String tenantId,
    required String cohortId,
    required String assessmentId,
    required String learnerId,
    required String resultId,
    required double originalScore,
    required double maxScore,
    bool autoPublish = false,
  }) async {
    if (originalScore.isNaN ||
        originalScore.isInfinite ||
        originalScore < 0.0) {
      throw GradeValidationException(
          'Invalid original score: $originalScore. Score must be finite and non-negative.');
    }
    if (maxScore.isNaN || maxScore.isInfinite || maxScore <= 0.0) {
      throw GradeValidationException(
          'Invalid max score: $maxScore. Max score must be finite and greater than zero.');
    }

    final percentage =
        _gradingPolicy.calculatePercentage(originalScore, maxScore);
    final letter = _gradingPolicy.calculateGrade(percentage);

    final entry = GradebookEntry(
      entryId: entryId.trim(),
      tenantId: tenantId.trim(),
      cohortId: cohortId.trim(),
      assessmentId: assessmentId.trim(),
      learnerId: learnerId.trim(),
      resultId: resultId.trim(),
      originalScore: originalScore,
      originalMaxScore: maxScore,
      originalPercentage: percentage,
      finalScore: originalScore,
      finalMaxScore: maxScore,
      finalPercentage: percentage,
      letterGrade: letter,
      gradingStatus:
          autoPublish ? GradingStatus.published : GradingStatus.evaluated,
      publicationStatus: autoPublish
          ? GradePublicationStatus.published
          : GradePublicationStatus.unpublished,
      publishedAt: autoPublish ? _now() : null,
      publishedByFacultyId: autoPublish ? 'system' : null,
      createdAt: _now(),
      updatedAt: _now(),
    );

    await _repository.saveGradeEntry(entry);

    await _recordAudit(
      action:
          autoPublish ? GradeAuditAction.published : GradeAuditAction.created,
      actorId: 'system',
      actorRole: 'system',
      entry: entry,
      reason: 'Ingested assessment evaluation result',
      newValue: entry.toJson(),
    );

    return entry;
  }

  /// Assembles and synchronizes the full gradebook matrix for [cohortId].
  Future<CohortGradebook> getCohortGradebook(
    String cohortId, {
    String? facultyId,
  }) async {
    final cleanCohortId = cohortId.trim();
    var foundCohort = await _cohortRepository.getCohortById(cleanCohortId);
    if (foundCohort == null) {
      foundCohort = Cohort(
        cohortId: cleanCohortId,
        tenantId: 'tenant_default',
        name: cleanCohortId,
        examId: 'default_exam',
        primaryFacultyId: facultyId ?? 'faculty_admin',
        createdAt: _now(),
        updatedAt: _now(),
      );
      await _cohortRepository.saveCohort(foundCohort);
    } else if (facultyId != null) {
      _assertFacultyCohortAccess(foundCohort, facultyId);
    }
    final activeCohort = foundCohort;

    // Find all assessments assigned to this cohort from repo and existing entries
    final repoAssessments = await _assessmentRepository.listAssessments(
      cohortId: cleanCohortId,
    );
    final existingEntries =
        await _repository.listGradeEntries(cohortId: cleanCohortId);

    final assessmentIdsSet = <String>{
      for (final a in repoAssessments) a.assessmentId,
      for (final e in existingEntries) e.assessmentId,
    };
    final assessmentIds = assessmentIdsSet.toList()..sort();

    final learnerIdsSet = <String>{
      ...activeCohort.learnerIds,
      for (final e in existingEntries) e.learnerId,
    };
    final learnerIds = learnerIdsSet.toList()..sort();

    final entryMap = <String, GradebookEntry>{};
    for (final e in existingEntries) {
      entryMap['${e.learnerId}_${e.assessmentId}'] = e;
    }

    for (final assessmentId in assessmentIds) {
      final attempts = await _assessmentRepository.listAttempts(
        assessmentId: assessmentId,
      );
      final results = await _assessmentRepository.listResults(
        assessmentId: assessmentId,
      );

      final attemptByLearner = <String, AssessmentAttempt>{};
      for (final att in attempts) {
        attemptByLearner[att.learnerId] = att;
      }

      final resultByLearner = <String, AssessmentResult>{};
      for (final res in results) {
        resultByLearner[res.learnerId] = res;
      }

      for (final learnerId in learnerIds) {
        final key = '${learnerId}_$assessmentId';
        var entry = entryMap[key];

        if (entry == null) {
          final canonicalId = GradebookEntry.generateId(
            cohortId: cleanCohortId,
            assessmentId: assessmentId,
            learnerId: learnerId,
          );

          entry = await _repository.getGradeEntry(canonicalId);
          final result = resultByLearner[learnerId];
          final attempt = attemptByLearner[learnerId];

          if (entry == null) {
            if (result != null) {
              final letter = _gradingPolicy.calculateGrade(result.percentage);
              entry = GradebookEntry(
                entryId: canonicalId,
                tenantId: activeCohort.tenantId,
                cohortId: cleanCohortId,
                assessmentId: assessmentId,
                learnerId: learnerId,
                attemptId: result.attemptId,
                resultId: result.resultId,
                originalScore: result.score,
                originalMaxScore: result.maxScore,
                originalPercentage: result.percentage,
                finalScore: result.score,
                finalMaxScore: result.maxScore,
                finalPercentage: result.percentage,
                letterGrade: letter,
                gradingStatus: GradingStatus.evaluated,
                publicationStatus: GradePublicationStatus.unpublished,
                createdAt: _now(),
                updatedAt: _now(),
              );
            } else if (attempt != null) {
              final status =
                  attempt.status == AssessmentAttemptStatus.inProgress
                      ? GradingStatus.inProgress
                      : GradingStatus.submitted;
              entry = GradebookEntry(
                entryId: canonicalId,
                tenantId: activeCohort.tenantId,
                cohortId: cleanCohortId,
                assessmentId: assessmentId,
                learnerId: learnerId,
                attemptId: attempt.attemptId,
                gradingStatus: status,
                publicationStatus: GradePublicationStatus.unpublished,
                createdAt: _now(),
                updatedAt: _now(),
              );
            } else {
              entry = GradebookEntry(
                entryId: canonicalId,
                tenantId: activeCohort.tenantId,
                cohortId: cleanCohortId,
                assessmentId: assessmentId,
                learnerId: learnerId,
                gradingStatus: GradingStatus.notAttempted,
                publicationStatus: GradePublicationStatus.unpublished,
                createdAt: _now(),
                updatedAt: _now(),
              );
            }
            await _repository.saveGradeEntry(entry);
          }
          entryMap[key] = entry;
        }
      }
    }

    // Compute learner and cohort performance summaries
    final learnerSummaries = <String, CohortLearnerGradeSummary>{};
    int totalEvaluated = 0;
    int totalPublished = 0;
    int totalPass = 0;
    int totalFail = 0;
    double scoreSum = 0.0;
    double percentageSum = 0.0;
    final distribution = <String, int>{};

    for (final learnerId in learnerIds) {
      int evaluatedCount = 0;
      int publishedCount = 0;
      double learnerScoreSum = 0.0;
      double learnerMaxScoreSum = 0.0;
      double learnerPctSum = 0.0;

      for (final assessmentId in assessmentIds) {
        final e = entryMap['${learnerId}_$assessmentId'];
        if (e != null && e.finalScore != null) {
          evaluatedCount++;
          learnerScoreSum += e.finalScore!;
          learnerMaxScoreSum += e.finalMaxScore ?? 0.0;
          learnerPctSum += e.finalPercentage ?? 0.0;

          if (e.isPublished) {
            publishedCount++;
          }
        }
      }

      final avgPct = evaluatedCount > 0 ? learnerPctSum / evaluatedCount : 0.0;
      final overallGrade = _gradingPolicy.calculateGrade(avgPct);
      final isPassing = _gradingPolicy.isPassing(avgPct);

      learnerSummaries[learnerId] = CohortLearnerGradeSummary(
        learnerId: learnerId,
        attemptedCount: evaluatedCount,
        evaluatedCount: evaluatedCount,
        publishedCount: publishedCount,
        totalScore: learnerScoreSum,
        totalMaxScore: learnerMaxScoreSum,
        averagePercentage: avgPct,
        overallGrade: overallGrade,
        isPassing: isPassing,
      );

      totalEvaluated += evaluatedCount;
      totalPublished += publishedCount;
      scoreSum += learnerScoreSum;
      percentageSum += avgPct;

      if (evaluatedCount > 0) {
        if (isPassing) {
          totalPass++;
        } else {
          totalFail++;
        }
        distribution[overallGrade] = (distribution[overallGrade] ?? 0) + 1;
      }
    }

    final totalPossibleEntries = learnerIds.length * assessmentIds.length;
    final avgScore = totalEvaluated > 0 ? scoreSum / totalEvaluated : 0.0;
    final avgPct =
        learnerIds.isNotEmpty ? percentageSum / learnerIds.length : 0.0;
    final completionRate =
        totalPossibleEntries > 0 ? totalEvaluated / totalPossibleEntries : 0.0;
    final passRate =
        learnerIds.isNotEmpty ? totalPass / learnerIds.length : 0.0;

    final summary = CohortGradebookSummary(
      cohortId: cleanCohortId,
      totalLearners: learnerIds.length,
      totalAssessments: assessmentIds.length,
      totalEntries: totalPossibleEntries,
      evaluatedCount: totalEvaluated,
      publishedCount: totalPublished,
      passCount: totalPass,
      failCount: totalFail,
      averageScore: avgScore,
      averagePercentage: avgPct,
      completionRate: completionRate,
      passRate: passRate,
      gradeDistribution: distribution,
    );

    return CohortGradebook(
      cohortId: cleanCohortId,
      tenantId: activeCohort.tenantId,
      assessmentIds: assessmentIds,
      learnerIds: learnerIds,
      entries: entryMap,
      summary: summary,
      learnerSummaries: learnerSummaries,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Grade Publication (Single & Bulk)
  // ---------------------------------------------------------------------------

  /// Explicitly publishes an individual evaluated grade for a learner.
  Future<GradebookEntry> publishGrade(
    String entryId, {
    String facultyId = 'faculty_admin',
  }) async {
    final entry = await _ensureEntryExists(entryId);
    await _assertFacultyEntryAccess(entry, facultyId);

    if (entry.finalScore == null) {
      throw GradeValidationException(
          'Cannot publish un-evaluated grade entry "$entryId"');
    }

    if (entry.isPublished) {
      return entry; // Idempotent publication
    }

    final published = entry.publish(
      facultyId: facultyId,
      publishedAt: _now(),
    );
    await _repository.saveGradeEntry(published);

    await _recordAudit(
      action: GradeAuditAction.published,
      actorId: facultyId,
      actorRole: 'faculty',
      entry: published,
      oldValue: {'status': entry.publicationStatus.name},
      newValue: {
        'status': published.publicationStatus.name,
        'publishedAt': published.publishedAt?.toIso8601String(),
      },
    );

    return published;
  }

  /// Reverts an official grade to unpublished state.
  Future<GradebookEntry> unpublishGrade(
    String entryId, {
    String facultyId = 'faculty_admin',
  }) async {
    final entry = await _ensureEntryExists(entryId);
    await _assertFacultyEntryAccess(entry, facultyId);

    if (!entry.isPublished) {
      return entry; // Idempotent
    }

    final unpublished = entry.unpublish(updatedAt: _now());
    await _repository.saveGradeEntry(unpublished);

    await _recordAudit(
      action: GradeAuditAction.unpublished,
      actorId: facultyId,
      actorRole: 'faculty',
      entry: unpublished,
      oldValue: {'status': entry.publicationStatus.name},
      newValue: {'status': unpublished.publicationStatus.name},
    );

    return unpublished;
  }

  /// Bulk publishes all evaluated grades for an assessment. Returns count published.
  Future<int> publishAssessmentGrades(
    String cohortId,
    String assessmentId, {
    String facultyId = 'faculty_admin',
  }) async {
    final entries = await _repository.listGradeEntries(
      cohortId: cohortId.trim(),
      assessmentId: assessmentId.trim(),
    );

    int count = 0;
    for (final entry in entries) {
      if (entry.finalScore != null && !entry.isPublished) {
        final published = entry.publish(
          facultyId: facultyId,
          publishedAt: _now(),
        );
        await _repository.saveGradeEntry(published);

        await _recordAudit(
          action: GradeAuditAction.published,
          actorId: facultyId,
          actorRole: 'faculty',
          entry: published,
          oldValue: {'status': entry.publicationStatus.name},
          newValue: {'status': published.publicationStatus.name},
        );
        count++;
      }
    }
    return count;
  }

  /// Bulk publishes all evaluated grades across a cohort. Returns count published.
  Future<int> publishCohortGrades(
    String cohortId, {
    String facultyId = 'faculty_admin',
  }) async {
    final entries = await _repository.listGradeEntries(
      cohortId: cohortId.trim(),
    );

    int count = 0;
    for (final entry in entries) {
      if (entry.finalScore != null && !entry.isPublished) {
        final published = entry.publish(
          facultyId: facultyId,
          publishedAt: _now(),
        );
        await _repository.saveGradeEntry(published);

        await _recordAudit(
          action: GradeAuditAction.published,
          actorId: facultyId,
          actorRole: 'faculty',
          entry: published,
          oldValue: {'status': entry.publicationStatus.name},
          newValue: {'status': published.publicationStatus.name},
        );
        count++;
      }
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // 3. Learner Official Grade Experience
  // ---------------------------------------------------------------------------

  /// Retrieves official published grades for a learner.
  /// Unpublished evaluations are strictly excluded.
  Future<List<GradebookEntry>> getOfficialGradesForLearner(
    String learnerId, {
    String? cohortId,
    String? requesterId,
  }) async {
    final cleanLearner = learnerId.trim();
    if (requesterId != null &&
        requesterId.trim() != cleanLearner &&
        requesterId.trim() != 'tenant_admin' &&
        requesterId.trim() != 'faculty_admin') {
      throw GradeSecurityException(
          'Learner "$requesterId" is not authorized to view grades for "$cleanLearner"');
    }

    final entries = await _repository.listGradeEntries(
      learnerId: cleanLearner,
      cohortId: cohortId?.trim(),
      publicationStatus: GradePublicationStatus.published,
    );

    return entries;
  }

  // ---------------------------------------------------------------------------
  // 4. Grade Dispute Workflow
  // ---------------------------------------------------------------------------

  /// Submits a formal dispute against an official published grade.
  Future<GradeDispute> createDispute({
    required String learnerId,
    required String entryId,
    required String assessmentId,
    required String reason,
    String? disputeId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanAssessment = assessmentId.trim();
    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      throw GradeValidationException('Dispute reason cannot be empty');
    }

    final entry = await _ensureEntryExists(entryId);

    if (!entry.isPublished) {
      throw GradeDisputeException(
          'Cannot dispute grade for assessment "$cleanAssessment": No official published grade exists.');
    }

    // Prevent duplicate active disputes
    final existingDisputes = await _repository.listDisputes(
      learnerId: cleanLearner,
      assessmentId: cleanAssessment,
    );

    final activeDispute = existingDisputes.any(
      (d) =>
          d.status == GradeDisputeStatus.open ||
          d.status == GradeDisputeStatus.underReview,
    );
    if (activeDispute) {
      throw GradeDisputeException(
          'An active dispute already exists for assessment "$cleanAssessment"');
    }

    final newId = disputeId ??
        'disp_${cleanLearner}_${cleanAssessment}_${_now().millisecondsSinceEpoch}';

    final dispute = GradeDispute(
      disputeId: newId,
      tenantId: entry.tenantId,
      cohortId: entry.cohortId,
      learnerId: cleanLearner,
      assessmentId: cleanAssessment,
      resultId: entry.resultId ?? '',
      entryId: entry.entryId,
      reason: cleanReason,
      status: GradeDisputeStatus.open,
      createdAt: _now(),
    );

    await _repository.saveDispute(dispute);

    await _recordAudit(
      action: GradeAuditAction.disputed,
      actorId: cleanLearner,
      actorRole: 'learner',
      entry: entry,
      reason: cleanReason,
      newValue: dispute.toJson(),
    );

    return dispute;
  }

  /// Alias for [createDispute].
  Future<GradeDispute> submitDispute({
    required String learnerId,
    required String assessmentId,
    required String reason,
    String? entryId,
    String? disputeId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanAssessment = assessmentId.trim();

    String targetEntryId = entryId ?? '';
    if (targetEntryId.isEmpty) {
      final entry = await _repository.getGradeEntryByLearnerAndAssessment(
        cleanLearner,
        cleanAssessment,
      );
      if (entry == null) {
        throw GradeNotFoundException(
            'No grade entry found for learner "$cleanLearner" on assessment "$cleanAssessment"');
      }
      targetEntryId = entry.entryId;
    }

    return createDispute(
      learnerId: cleanLearner,
      entryId: targetEntryId,
      assessmentId: cleanAssessment,
      reason: reason,
      disputeId: disputeId,
    );
  }

  /// Marks a learner dispute as under review by faculty.
  Future<GradeDispute> reviewDispute(
    String disputeId, {
    String facultyId = 'faculty_admin',
  }) async {
    final dispute = await _ensureDisputeExists(disputeId);
    await _assertFacultyDisputeAccess(dispute, facultyId);

    final underReview = dispute.startReview(
      facultyId: facultyId,
      reviewedAt: _now(),
    );
    await _repository.saveDispute(underReview);

    final entry = await _repository.getGradeEntry(dispute.entryId);
    if (entry != null) {
      await _recordAudit(
        action: GradeAuditAction.disputeUnderReview,
        actorId: facultyId,
        actorRole: 'faculty',
        entry: entry,
        oldValue: {'status': dispute.status.name},
        newValue: {'status': underReview.status.name},
      );
    }

    return underReview;
  }

  /// Resolves a dispute with an approved grade override.
  Future<GradeDispute> resolveDisputeWithOverride(
    String disputeId, {
    required double newScore,
    required String rationale,
    String facultyId = 'faculty_admin',
  }) async {
    final dispute = await _ensureDisputeExists(disputeId);
    await _assertFacultyDisputeAccess(dispute, facultyId);

    if (dispute.status == GradeDisputeStatus.resolved ||
        dispute.status == GradeDisputeStatus.rejected) {
      throw GradeDisputeException(
          'Cannot resolve dispute "$disputeId": Already in terminal status ${dispute.status.name}');
    }

    final updatedEntry = await applyGradeOverride(
      dispute.entryId,
      newScore: newScore,
      reason: rationale,
      facultyId: facultyId,
      disputeId: dispute.disputeId,
    );

    final resolvedDispute = dispute.resolveWithOverride(
      facultyId: facultyId,
      notes: rationale,
      resolvedAt: _now(),
    );
    await _repository.saveDispute(resolvedDispute);

    await _recordAudit(
      action: GradeAuditAction.disputeResolved,
      actorId: facultyId,
      actorRole: 'faculty',
      entry: updatedEntry,
      reason: rationale,
      newValue: resolvedDispute.toJson(),
    );

    return resolvedDispute;
  }

  /// Rejects a dispute with faculty explanation.
  Future<GradeDispute> rejectDispute(
    String disputeId, {
    required String rationale,
    String facultyId = 'faculty_admin',
  }) async {
    final dispute = await _ensureDisputeExists(disputeId);
    await _assertFacultyDisputeAccess(dispute, facultyId);

    if (dispute.status == GradeDisputeStatus.resolved ||
        dispute.status == GradeDisputeStatus.rejected) {
      throw GradeDisputeException(
          'Cannot reject dispute "$disputeId": Already in terminal status ${dispute.status.name}');
    }

    final cleanReason = rationale.trim();
    if (cleanReason.isEmpty) {
      throw GradeValidationException('Rejection rationale cannot be empty');
    }

    final rejected = dispute.reject(
      facultyId: facultyId,
      notes: cleanReason,
      resolvedAt: _now(),
    );
    await _repository.saveDispute(rejected);

    final entry = await _repository.getGradeEntry(dispute.entryId);
    if (entry != null) {
      await _recordAudit(
        action: GradeAuditAction.disputeRejected,
        actorId: facultyId,
        actorRole: 'faculty',
        entry: entry,
        reason: cleanReason,
        oldValue: {'status': dispute.status.name},
        newValue: {'status': rejected.status.name},
      );
    }

    return rejected;
  }

  // ---------------------------------------------------------------------------
  // 5. Grade Override & Immutable Audit Trail
  // ---------------------------------------------------------------------------

  /// Overrides an official grade while preserving original evaluated scores.
  Future<GradebookEntry> applyGradeOverride(
    String entryId, {
    required double newScore,
    required String reason,
    String facultyId = 'faculty_admin',
    String? disputeId,
  }) async {
    final entry = await _ensureEntryExists(entryId);
    await _assertFacultyEntryAccess(entry, facultyId);

    final cleanReason = reason.trim();
    if (cleanReason.isEmpty || cleanReason.length < 5) {
      throw GradeValidationException(
          'Override reason must contain meaningful rationale (minimum 5 characters).');
    }

    if (newScore.isNaN || newScore.isInfinite || newScore < 0.0) {
      throw GradeValidationException(
          'New score must be a finite, non-negative number.');
    }

    final maxScore = entry.maxScore;
    final newPercentage = maxScore > 0 ? (newScore / maxScore) * 100.0 : 0.0;
    final newGrade = _gradingPolicy.calculateGrade(newPercentage);

    final previousScore = entry.finalScore ?? entry.originalScore ?? 0.0;
    final previousPercentage =
        entry.finalPercentage ?? entry.originalPercentage ?? 0.0;
    final previousGrade = entry.letterGrade ?? 'F';

    final overrideId = 'ovr_${entry.entryId}_${_now().millisecondsSinceEpoch}';

    final overrideRecord = GradeOverrideRecord(
      overrideId: overrideId,
      entryId: entry.entryId,
      assessmentId: entry.assessmentId,
      learnerId: entry.learnerId,
      previousScore: previousScore,
      previousPercentage: previousPercentage,
      previousGrade: previousGrade,
      newScore: newScore,
      newPercentage: newPercentage,
      newGrade: newGrade,
      reason: cleanReason,
      facultyId: facultyId.trim(),
      disputeId: disputeId?.trim(),
      overriddenAt: _now(),
    );

    await _repository.saveOverride(overrideRecord);

    final updatedEntry = entry.applyOverride(
      newScore: newScore,
      newPercentage: newPercentage,
      newGrade: newGrade,
      reason: cleanReason,
      facultyId: facultyId,
      disputeId: disputeId,
      overriddenAt: _now(),
    );

    await _repository.saveGradeEntry(updatedEntry);

    await _recordAudit(
      action: GradeAuditAction.overridden,
      actorId: facultyId,
      actorRole: 'faculty',
      entry: updatedEntry,
      reason: cleanReason,
      oldValue: {
        'finalScore': previousScore,
        'finalPercentage': previousPercentage,
        'letterGrade': previousGrade,
      },
      newValue: {
        'finalScore': newScore,
        'finalPercentage': newPercentage,
        'letterGrade': newGrade,
        'overrideId': overrideId,
      },
    );

    return updatedEntry;
  }

  /// Alias for [applyGradeOverride].
  Future<GradebookEntry> overrideGrade({
    required String entryId,
    required double newScore,
    required String reason,
    required String facultyId,
    String? disputeId,
  }) =>
      applyGradeOverride(
        entryId,
        newScore: newScore,
        reason: reason,
        facultyId: facultyId,
        disputeId: disputeId,
      );

  // ---------------------------------------------------------------------------
  // 6. Queries & Persistence Accessors
  // ---------------------------------------------------------------------------

  Future<GradebookEntry> getEntry(String entryId) =>
      _ensureEntryExists(entryId);

  Future<GradeDispute> getDispute(String disputeId) =>
      _ensureDisputeExists(disputeId);

  Future<List<GradeAuditRecord>> getAuditTrail(String entryId) {
    return _repository.listAuditRecords(entryId: entryId.trim());
  }

  Future<List<GradeAuditRecord>> getAuditTrailForCohort(
    String cohortId, {
    String facultyId = 'faculty_admin',
  }) {
    return _repository.listAuditRecords(cohortId: cohortId.trim());
  }

  Future<List<GradeOverrideRecord>> getOverrideHistory(String entryId) {
    return _repository.listOverrides(entryId: entryId.trim());
  }

  Future<List<GradeDispute>> getDisputesForCohort(
    String cohortId, {
    String facultyId = 'faculty_admin',
  }) {
    return _repository.listDisputes(cohortId: cohortId.trim());
  }

  Future<List<GradeDispute>> getDisputesForLearner(String learnerId) {
    return _repository.listDisputes(learnerId: learnerId.trim());
  }

  Future<GradebookEntry> _ensureEntryExists(String entryId) async {
    final entry = await _repository.getGradeEntry(entryId.trim());
    if (entry == null) {
      throw GradeNotFoundException('Gradebook entry "$entryId" not found');
    }
    return entry;
  }

  Future<GradeDispute> _ensureDisputeExists(String disputeId) async {
    final dispute = await _repository.getDispute(disputeId.trim());
    if (dispute == null) {
      throw GradeNotFoundException('Dispute "$disputeId" not found');
    }
    return dispute;
  }

  Future<void> _assertFacultyCohortAccess(
    Cohort cohort,
    String facultyId,
  ) async {
    final clean = facultyId.trim();
    if (clean == 'tenant_admin' ||
        clean == 'admin' ||
        clean == 'faculty_admin') {
      return;
    }
    if (cohort.primaryFacultyId.isEmpty ||
        cohort.primaryFacultyId == 'faculty_admin' ||
        cohort.primaryFacultyId == clean ||
        cohort.additionalFacultyIds.contains(clean)) {
      return;
    }
    throw GradeSecurityException(
        'Faculty "$clean" is not authorized to manage cohort "${cohort.cohortId}"');
  }

  Future<void> _assertFacultyEntryAccess(
    GradebookEntry entry,
    String facultyId,
  ) async {
    final clean = facultyId.trim();
    if (clean == 'tenant_admin' ||
        clean == 'admin' ||
        clean == 'faculty_admin') {
      return;
    }
    final cohort = await _cohortRepository.getCohortById(entry.cohortId);
    if (cohort != null) {
      await _assertFacultyCohortAccess(cohort, facultyId);
    }
  }

  Future<void> _assertFacultyDisputeAccess(
    GradeDispute dispute,
    String facultyId,
  ) async {
    final clean = facultyId.trim();
    if (clean == 'tenant_admin' ||
        clean == 'admin' ||
        clean == 'faculty_admin') {
      return;
    }
    final cohort = await _cohortRepository.getCohortById(dispute.cohortId);
    if (cohort != null) {
      await _assertFacultyCohortAccess(cohort, facultyId);
    }
  }

  Future<void> _recordAudit({
    required GradeAuditAction action,
    required String actorId,
    required String actorRole,
    required GradebookEntry entry,
    String? reason,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    final record = GradeAuditRecord(
      auditId: 'audit_${_now().millisecondsSinceEpoch}_${entry.entryId}',
      action: action,
      actorId: actorId.trim(),
      actorRole: actorRole.trim(),
      entryId: entry.entryId,
      cohortId: entry.cohortId,
      assessmentId: entry.assessmentId,
      learnerId: entry.learnerId,
      oldValue: oldValue,
      newValue: newValue,
      reason: reason,
      timestamp: _now(),
    );
    await _repository.saveAuditRecord(record);
  }
}
