/// Assessment Management Orchestrator Service (TITAN-KO-049.0 P49).
///
/// Enterprise service managing the entire assessment lifecycle:
/// question selection, configuration, cohort assignment, secure attempts,
/// deterministic answer capture, evaluation, and cohort performance visibility.
library;

import '../domain/entities/assessment.dart';
import '../domain/entities/assessment_attempt.dart';
import '../domain/entities/assessment_result.dart';
import '../provider/question_provider.dart';
import '../repository/assessment_repository.dart';
import '../repository/cohort_repository.dart';
import 'curriculum_service.dart';

class AssessmentManagementService {
  final AssessmentRepository _repository;
  final QuestionProvider _questionProvider;
  final CohortRepository? _cohortRepository;
  final CurriculumService? _curriculumService;
  final DateTime Function() _clock;

  AssessmentManagementService({
    required AssessmentRepository repository,
    required QuestionProvider questionProvider,
    CohortRepository? cohortRepository,
    CurriculumService? curriculumService,
    DateTime Function()? clock,
  })  : _repository = repository,
        _questionProvider = questionProvider,
        _cohortRepository = cohortRepository,
        _curriculumService = curriculumService,
        _clock = clock ?? (() => DateTime.now().toUtc());

  DateTime _now() => _clock().toUtc();

  AssessmentRepository get repository => _repository;
  QuestionProvider get questionProvider => _questionProvider;
  CohortRepository? get cohortRepository => _cohortRepository;
  CurriculumService? get curriculumService => _curriculumService;

  // ---------------------------------------------------------------------------
  // 1. Faculty Operations
  // ---------------------------------------------------------------------------

  /// Creates a new assessment in draft status.
  Future<Assessment> createAssessment({
    required String assessmentId,
    String tenantId = 'default_tenant',
    required String title,
    String description = '',
    required String examId,
    String? subjectId,
    String? topicId,
    required String creatorFacultyId,
    required List<String> questionIds,
    AssessmentMarksConfig marksConfig = const AssessmentMarksConfig(),
    AssessmentTimingConfig timingConfig = const AssessmentTimingConfig(),
    int maxAttempts = 1,
    AssessmentStatus status = AssessmentStatus.draft,
    Iterable<String>? cohortIds,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanId = assessmentId.trim();
    if (cleanId.isEmpty) {
      throw AssessmentValidationException('assessmentId cannot be empty');
    }

    final existing = await _repository.getAssessmentById(cleanId);
    if (existing != null) {
      throw AssessmentValidationException(
          'Assessment "$cleanId" already exists');
    }

    _validateQuestionIds(questionIds);

    final assessment = Assessment(
      assessmentId: cleanId,
      tenantId: tenantId.trim(),
      title: title.trim(),
      description: description.trim(),
      examId: examId.trim(),
      subjectId: subjectId,
      topicId: topicId,
      creatorFacultyId: creatorFacultyId.trim(),
      questionIds: questionIds,
      marksConfig: marksConfig,
      timingConfig: timingConfig,
      maxAttempts: maxAttempts,
      status: status,
      cohortIds: cohortIds,
      createdAt: _now(),
      updatedAt: _now(),
      metadata: metadata,
    );

    await _repository.saveAssessment(assessment);
    return assessment;
  }

  /// Updates an existing draft or published assessment.
  Future<Assessment> updateAssessment(
    Assessment updated, {
    required String requesterFacultyId,
  }) async {
    final current = await _ensureAssessmentExists(updated.assessmentId);
    _assertFacultyAuthorized(current, requesterFacultyId);

    if (current.status == AssessmentStatus.closed) {
      throw AssessmentPolicyException(
          'Cannot edit assessment "${current.assessmentId}" because it is closed');
    }

    _validateQuestionIds(updated.questionIds);

    final toSave = updated.copyWith(updatedAt: _now());
    await _repository.saveAssessment(toSave);
    return toSave;
  }

  /// Publishes an assessment, making it visible and available to learners.
  Future<Assessment> publishAssessment(
    String assessmentId, {
    required String facultyId,
  }) async {
    final assessment = await _ensureAssessmentExists(assessmentId);
    _assertFacultyAuthorized(assessment, facultyId);

    if (assessment.status == AssessmentStatus.closed) {
      throw AssessmentPolicyException(
          'Cannot publish closed assessment "$assessmentId"');
    }

    final published = assessment.copyWith(
      status: AssessmentStatus.published,
      updatedAt: _now(),
    );
    await _repository.saveAssessment(published);
    return published;
  }

  /// Closes an assessment, preventing further attempts.
  Future<Assessment> closeAssessment(
    String assessmentId, {
    required String facultyId,
  }) async {
    final assessment = await _ensureAssessmentExists(assessmentId);
    _assertFacultyAuthorized(assessment, facultyId);

    final closed = assessment.copyWith(
      status: AssessmentStatus.closed,
      updatedAt: _now(),
    );
    await _repository.saveAssessment(closed);
    return closed;
  }

  /// Assigns an assessment to an institutional cohort.
  Future<Assessment> assignCohort(
    String assessmentId,
    String cohortId, {
    required String facultyId,
  }) async {
    final assessment = await _ensureAssessmentExists(assessmentId);
    _assertFacultyAuthorized(assessment, facultyId);

    final cleanCohort = cohortId.trim();
    if (_cohortRepository != null) {
      final cohort = await _cohortRepository!.getCohortById(cleanCohort);
      if (cohort == null) {
        throw AssessmentNotFoundException(
            'Cohort "$cleanCohort" does not exist');
      }
    }

    final nextCohorts = {...assessment.cohortIds, cleanCohort};
    final updated = assessment.copyWith(
      cohortIds: nextCohorts,
      updatedAt: _now(),
    );
    await _repository.saveAssessment(updated);
    return updated;
  }

  /// Queries assessments created by a faculty member.
  Future<List<Assessment>> getAssessmentsForFaculty(
    String facultyId, {
    String? tenantId,
  }) {
    return _repository.listAssessments(
      creatorFacultyId: facultyId.trim(),
      tenantId: tenantId,
    );
  }

  /// Computes summary of cohort results for an assessment.
  Future<AssessmentCohortSummary> getAssessmentCohortSummary(
    String assessmentId,
    String cohortId, {
    required String facultyId,
  }) async {
    final assessment = await _ensureAssessmentExists(assessmentId);
    _assertFacultyAuthorized(assessment, facultyId);

    final cleanCohort = cohortId.trim();
    int totalLearners = 0;
    List<String> cohortLearnerIds = [];

    if (_cohortRepository != null) {
      final cohort = await _cohortRepository!.getCohortById(cleanCohort);
      if (cohort != null) {
        cohortLearnerIds = cohort.learnerIds.toList();
        totalLearners = cohort.learnerCount;
      }
    }

    final attempts = await _repository.listAttempts(assessmentId: assessmentId);
    final results = await _repository.listResults(assessmentId: assessmentId);

    final cohortResults =
        results.where((r) => cohortLearnerIds.contains(r.learnerId)).toList();

    int attemptedCount = 0;
    for (final att in attempts) {
      if (cohortLearnerIds.contains(att.learnerId)) {
        attemptedCount++;
      }
    }

    int submittedCount = cohortResults.length;
    double scoreSum = 0.0;
    double percentageSum = 0.0;
    int passCount = 0;
    int failCount = 0;

    for (final res in cohortResults) {
      scoreSum += res.score;
      percentageSum += res.percentage;
      if (res.isPassed) {
        passCount++;
      } else {
        failCount++;
      }
    }

    final avgScore = submittedCount == 0 ? 0.0 : scoreSum / submittedCount;
    final avgPct = submittedCount == 0 ? 0.0 : percentageSum / submittedCount;

    return AssessmentCohortSummary(
      assessment: assessment,
      cohortId: cleanCohort,
      totalLearners: totalLearners,
      attemptedCount: attemptedCount,
      submittedCount: submittedCount,
      averageScore: avgScore,
      averagePercentage: avgPct,
      passCount: passCount,
      failCount: failCount,
      results: cohortResults,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Learner Operations
  // ---------------------------------------------------------------------------

  /// Lists assessments currently visible and available for a learner.
  Future<List<Assessment>> getAvailableAssessments({
    required String learnerId,
    String? tenantId,
    DateTime? asOfDate,
  }) async {
    final now = (asOfDate ?? _now()).toUtc();
    final allAssessments = await _repository.listAssessments(
      tenantId: tenantId,
    );

    final available = <Assessment>[];
    for (final a in allAssessments) {
      if (!a.isVisibleToLearners || !a.isAvailable(now)) continue;

      if (a.cohortIds.isNotEmpty) {
        if (_cohortRepository != null) {
          bool isMember = false;
          for (final cid in a.cohortIds) {
            final c = await _cohortRepository!.getCohortById(cid);
            if (c != null && c.hasLearner(learnerId)) {
              isMember = true;
              break;
            }
          }
          if (!isMember) continue;
        }
      }
      available.add(a);
    }
    return available;
  }

  /// Starts or resumes an assessment attempt for a learner.
  Future<AssessmentAttempt> startAttempt({
    required String assessmentId,
    required String learnerId,
    String? attemptId,
    DateTime? asOfDate,
  }) async {
    final assessment = await _ensureAssessmentExists(assessmentId);
    final cleanLearner = learnerId.trim();
    final now = (asOfDate ?? _now()).toUtc();

    if (assessment.status == AssessmentStatus.closed) {
      throw AssessmentPolicyException(
          'Cannot start attempt: Assessment "$assessmentId" is closed');
    }
    if (!assessment.isAvailable(now)) {
      throw AssessmentPolicyException(
          'Assessment "$assessmentId" is not currently open for attempts');
    }

    final existingAttempts = await _repository.listAttempts(
      assessmentId: assessment.assessmentId,
      learnerId: cleanLearner,
    );

    // Resume an in-progress attempt if one already exists
    for (final att in existingAttempts) {
      if (att.status == AssessmentAttemptStatus.inProgress) {
        if (!att.isExpired(assessment.timingConfig.durationMinutes, now)) {
          return att;
        }
      }
    }

    // Check maximum attempt policy
    final finalizedCount = existingAttempts.where((a) => a.isFinalized).length;
    if (finalizedCount >= assessment.maxAttempts) {
      throw AssessmentPolicyException(
          'Maximum attempts (${assessment.maxAttempts}) reached for learner "$cleanLearner" on assessment "$assessmentId"');
    }

    final newAttemptId = attemptId ??
        'att_${cleanLearner}_${assessment.assessmentId}_${now.millisecondsSinceEpoch}';

    final attempt = AssessmentAttempt(
      attemptId: newAttemptId,
      assessmentId: assessment.assessmentId,
      learnerId: cleanLearner,
      status: AssessmentAttemptStatus.inProgress,
      startedAt: now,
    );

    await _repository.saveAttempt(attempt);
    return attempt;
  }

  /// Records an answer to a question during an ongoing attempt.
  Future<AssessmentAttempt> recordAnswer({
    required String attemptId,
    required String learnerId,
    required String questionId,
    required String answer,
    DateTime? asOfDate,
  }) async {
    final attempt = await _ensureAttemptExists(attemptId);
    _assertLearnerAuthorized(attempt, learnerId);

    final assessment = await _ensureAssessmentExists(attempt.assessmentId);
    final now = (asOfDate ?? _now()).toUtc();

    if (attempt.isExpired(assessment.timingConfig.durationMinutes, now)) {
      throw AssessmentPolicyException(
          'Assessment duration has expired for attempt "$attemptId"');
    }

    final updated = attempt.recordAnswer(questionId, answer);
    await _repository.saveAttempt(updated);
    return updated;
  }

  /// Submits and deterministically evaluates an attempt (idempotent).
  Future<AssessmentResult> submitAttempt({
    required String attemptId,
    required String learnerId,
    DateTime? submittedAt,
  }) async {
    final attempt = await _ensureAttemptExists(attemptId);
    _assertLearnerAuthorized(attempt, learnerId);

    // Idempotency: If already evaluated or submitted, return existing result
    if (attempt.status == AssessmentAttemptStatus.evaluated) {
      final existingResult =
          await _repository.getResultForAttempt(attempt.attemptId);
      if (existingResult != null) return existingResult;
    }

    final assessment = await _ensureAssessmentExists(attempt.assessmentId);
    final submitTime = (submittedAt ?? _now()).toUtc();

    // Freeze attempt
    final frozenAttempt = attempt.submit(submittedAt: submitTime);
    await _repository.saveAttempt(frozenAttempt);

    // Evaluate answers
    final questionResults = <AssessmentQuestionResult>[];
    int attemptedCount = 0;
    int correctCount = 0;
    int incorrectCount = 0;
    double totalAwardedMarks = 0.0;

    for (final qId in assessment.questionIds) {
      final question = _questionProvider.getQuestionById(qId);
      final submitted = frozenAttempt.responses[qId];
      final isAttempted = submitted != null && submitted.trim().isNotEmpty;

      if (question == null) {
        // Fallback for missing question metadata
        questionResults.add(AssessmentQuestionResult(
          questionId: qId,
          submittedAnswer: submitted,
          expectedAnswer: '',
          isCorrect: false,
          isAttempted: isAttempted,
          marksAwarded: 0.0,
        ));
        continue;
      }

      final expected = question.expectedAnswer.trim().toLowerCase();
      final cleanSubmitted = (submitted ?? '').trim().toLowerCase();
      final isCorrect = isAttempted && (cleanSubmitted == expected);

      double marks = 0.0;
      if (isCorrect) {
        correctCount++;
        attemptedCount++;
        marks = assessment.marksConfig.marksPerQuestion;
      } else if (isAttempted) {
        incorrectCount++;
        attemptedCount++;
        marks = -assessment.marksConfig.negativePenaltyPerQuestion;
      }

      totalAwardedMarks += marks;

      questionResults.add(AssessmentQuestionResult(
        questionId: qId,
        submittedAnswer: submitted,
        expectedAnswer: question.expectedAnswer,
        isCorrect: isCorrect,
        isAttempted: isAttempted,
        marksAwarded: marks,
        explanation: question.explanation,
      ));
    }

    final unansweredCount = assessment.questionCount - attemptedCount;
    final maxScore = assessment.totalMarks;
    final netScore = totalAwardedMarks < 0.0 ? 0.0 : totalAwardedMarks;
    final percentage = maxScore > 0 ? (netScore / maxScore) * 100.0 : 0.0;
    final isPassed = percentage >= assessment.marksConfig.passingPercentage;

    final resultId = 'res_${frozenAttempt.attemptId}';
    final result = AssessmentResult(
      resultId: resultId,
      assessmentId: assessment.assessmentId,
      attemptId: frozenAttempt.attemptId,
      learnerId: frozenAttempt.learnerId,
      score: netScore,
      maxScore: maxScore,
      percentage: percentage,
      isPassed: isPassed,
      attemptedCount: attemptedCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unansweredCount: unansweredCount,
      questionResults: questionResults,
      evaluatedAt: submitTime,
    );

    await _repository.saveResult(result);

    // Finalize attempt
    final evaluatedAttempt = frozenAttempt.markEvaluated(resultId);
    await _repository.saveAttempt(evaluatedAttempt);

    return result;
  }

  /// Retrieves an assessment result with privacy protection.
  Future<AssessmentResult> getResult({
    required String resultId,
    required String requesterId,
    bool isFaculty = false,
  }) async {
    final result = await _repository.getResultById(resultId.trim());
    if (result == null) {
      throw AssessmentNotFoundException('Result "$resultId" not found');
    }

    if (!isFaculty && requesterId.trim() != 'tenant_admin') {
      if (result.learnerId != requesterId.trim()) {
        throw AssessmentSecurityException(
            'Learner "$requesterId" is not authorized to view result "$resultId"');
      }
    }
    return result;
  }

  /// Lists results for a specific learner.
  Future<List<AssessmentResult>> getResultsForLearner(String learnerId) {
    return _repository.listResults(learnerId: learnerId.trim());
  }

  // ---------------------------------------------------------------------------
  // Validation & Internal Helpers
  // ---------------------------------------------------------------------------

  Future<Assessment> _ensureAssessmentExists(String assessmentId) async {
    final a = await _repository.getAssessmentById(assessmentId.trim());
    if (a == null) {
      throw AssessmentNotFoundException(
          'Assessment "$assessmentId" does not exist');
    }
    return a;
  }

  Future<AssessmentAttempt> _ensureAttemptExists(String attemptId) async {
    final att = await _repository.getAttemptById(attemptId.trim());
    if (att == null) {
      throw AssessmentNotFoundException('Attempt "$attemptId" does not exist');
    }
    return att;
  }

  void _validateQuestionIds(List<String> questionIds) {
    if (questionIds.isEmpty) {
      throw AssessmentValidationException(
          'Assessment must contain at least one question reference');
    }

    final seen = <String>{};
    for (final qId in questionIds) {
      final clean = qId.trim();
      if (clean.isEmpty) {
        throw AssessmentValidationException('questionId cannot be empty');
      }
      if (!seen.add(clean)) {
        throw AssessmentValidationException(
            'Duplicate question reference detected: "$clean"');
      }

      final question = _questionProvider.getQuestionById(clean);
      if (question == null) {
        throw AssessmentValidationException(
            'Question "$clean" does not exist in question provider');
      }
    }
  }

  void _assertFacultyAuthorized(Assessment assessment, String facultyId) {
    final clean = facultyId.trim();
    if (clean == 'tenant_admin' || clean == 'admin') return;
    if (assessment.creatorFacultyId != clean) {
      throw AssessmentSecurityException(
          'Faculty "$clean" is not authorized to modify assessment "${assessment.assessmentId}"');
    }
  }

  void _assertLearnerAuthorized(AssessmentAttempt attempt, String learnerId) {
    final clean = learnerId.trim();
    if (attempt.learnerId != clean) {
      throw AssessmentSecurityException(
          'Learner "$clean" is not authorized to act on attempt "${attempt.attemptId}" owned by "${attempt.learnerId}"');
    }
  }
}
