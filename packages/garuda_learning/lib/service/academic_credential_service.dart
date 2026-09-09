/// Academic Credential Orchestration Service (TITAN-KO-051.0 P51).
///
/// Enterprise service managing academic record aggregation, official transcript
/// generation with immutable versioning, completion eligibility evaluation,
/// tamper-evident certificate issuance, revocation, and public verification boundaries.
library;

import 'dart:math';

import '../domain/entities/academic_record.dart';
import '../domain/entities/academic_transcript.dart';
import '../domain/entities/completion_certificate.dart';
import '../domain/entities/credential_audit_record.dart';
import '../domain/entities/credential_verification_result.dart';
import '../domain/entities/cohort.dart';
import '../domain/entities/cohort_assignment.dart';
import '../domain/entities/gradebook_entry.dart';
import '../domain/entities/grading_policy.dart';
import '../repository/assessment_repository.dart';
import '../repository/cohort_repository.dart';
import '../repository/credential_repository.dart';
import '../repository/gradebook_repository.dart';

class AcademicCredentialService {
  final CredentialRepository credentialRepository;
  final GradebookRepository gradebookRepository;
  final CohortRepository cohortRepository;
  final AssessmentRepository? assessmentRepository;
  final GradingPolicy gradingPolicy;
  final DateTime Function() _clock;

  AcademicCredentialService({
    required this.credentialRepository,
    required this.gradebookRepository,
    required this.cohortRepository,
    this.assessmentRepository,
    this.gradingPolicy = const GradingPolicy.standard(),
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  // ---------------------------------------------------------------------------
  // 1. Academic Record Aggregation
  // ---------------------------------------------------------------------------

  /// Aggregates authoritative published academic outcomes for a learner.
  ///
  /// CRITICAL: Only authoritative PUBLISHED grades are included.
  /// Evaluated, draft, or unpublished grades are strictly excluded.
  Future<AcademicRecord> generateAcademicRecord({
    required String learnerId,
    required String cohortId,
    required String requestingActorId,
    String requestingActorRole = 'faculty',
    String? academicPeriod,
    String? tenantId,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCohortId = cohortId.trim();
    final cleanActorId = requestingActorId.trim();

    // Security check: Learner isolation
    if (requestingActorRole == 'learner' && cleanActorId != cleanLearnerId) {
      throw CredentialSecurityException(
        'Learner $cleanActorId cannot access private academic record of learner $cleanLearnerId.',
      );
    }

    // Cohort existence check
    final cohort = await cohortRepository.getCohortById(cleanCohortId);
    if (cohort == null) {
      throw CredentialNotFoundException('Cohort $cleanCohortId not found.');
    }

    // Tenant isolation check
    if (tenantId != null && cohort.tenantId != tenantId) {
      throw CredentialSecurityException(
        'Access denied: Tenant mismatch for cohort $cleanCohortId.',
      );
    }

    // Fetch all gradebook entries for this learner in this cohort
    final entries = await gradebookRepository.listGradeEntries(
      cohortId: cleanCohortId,
      learnerId: cleanLearnerId,
    );

    // Filter strictly for published grades
    final publishedEntries = entries
        .where((e) => e.publicationStatus == GradePublicationStatus.published)
        .toList();

    // Resolve assessment titles
    final List<AcademicRecordEntry> recordEntries = [];
    for (final e in publishedEntries) {
      String title = 'Assessment ${e.assessmentId}';
      if (assessmentRepository != null) {
        final a = await assessmentRepository!.getAssessmentById(e.assessmentId);
        if (a != null && a.title.isNotEmpty) {
          title = a.title;
        }
      }

      final score = e.finalScore ?? e.originalScore ?? 0.0;
      final maxScore = e.finalMaxScore ?? e.originalMaxScore ?? 100.0;
      final percentage = e.finalPercentage ?? e.originalPercentage ?? 0.0;
      final letter = e.letterGrade ?? gradingPolicy.calculateGrade(percentage);
      final isPassing = gradingPolicy.isPassing(percentage);

      recordEntries.add(AcademicRecordEntry(
        assessmentId: e.assessmentId,
        assessmentTitle: title,
        originalScore: e.originalScore,
        finalScore: score,
        maxScore: maxScore,
        percentage: percentage,
        letterGrade: letter,
        isPassed: isPassing,
        isPublished: true,
        isOverridden: e.isOverridden,
        publishedAt: e.publishedAt,
        publishedBy: e.publishedByFacultyId,
      ));
    }

    // Calculate aggregated overall score & percentage
    double totalScore = 0.0;
    double totalMaxScore = 0.0;
    int passedCount = 0;

    for (final re in recordEntries) {
      totalScore += re.finalScore;
      totalMaxScore += re.maxScore;
      if (re.isPassed) passedCount++;
    }

    final double overallPct =
        totalMaxScore > 0 ? ((totalScore / totalMaxScore) * 100.0) : 0.0;
    final String overallGrade = gradingPolicy.calculateGrade(overallPct);

    // Check completion
    final requiredAssessments =
        await _resolveRequiredAssessmentsForCohort(cleanCohortId, cohort);
    final totalRequired = requiredAssessments.length;
    final bool isCompleted = totalRequired > 0 &&
        recordEntries.length == totalRequired &&
        passedCount == totalRequired &&
        overallPct >= gradingPolicy.passingPercentage;

    final period =
        academicPeriod ?? cohort.metadata['academicPeriod'] as String?;

    return AcademicRecord(
      recordId: 'rec_${cleanCohortId}_$cleanLearnerId',
      learnerId: cleanLearnerId,
      tenantId: cohort.tenantId,
      institutionName: 'QuizForge Institute of Technology',
      programName: cohort.name,
      cohortId: cleanCohortId,
      academicPeriod: period,
      entries: recordEntries,
      overallPercentage: double.parse(overallPct.toStringAsFixed(2)),
      overallGrade: overallGrade,
      isCompleted: isCompleted,
      totalAssessments: recordEntries.length,
      passedAssessments: passedCount,
      generatedAt: _clock(),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Completion Eligibility Determination
  // ---------------------------------------------------------------------------

  /// Deterministically evaluates whether a learner satisfies completion criteria.
  ///
  /// Requires:
  /// - 100% of required cohort assessments attempted and evaluated
  /// - 100% of evaluated results published
  /// - 0 failing grades on mandatory assessments
  /// - Overall percentage >= passing threshold (default 40.0%)
  ///
  /// Explicitly rejects claims based solely on attendance or login.
  Future<CompletionEligibility> evaluateCompletionEligibility({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCohortId = cohortId.trim();

    final cohort = await cohortRepository.getCohortById(cleanCohortId);
    if (cohort == null) {
      throw CredentialNotFoundException('Cohort $cleanCohortId not found.');
    }

    if (tenantId != null && cohort.tenantId != tenantId) {
      throw CredentialSecurityException('Tenant access mismatch.');
    }

    if (!cohort.learnerIds.contains(cleanLearnerId)) {
      throw CredentialValidationException(
        'Learner $cleanLearnerId is not an enrolled member of cohort $cleanCohortId.',
      );
    }

    final requiredAssessments =
        await _resolveRequiredAssessmentsForCohort(cleanCohortId, cohort);
    final entries = await gradebookRepository.listGradeEntries(
      cohortId: cleanCohortId,
      learnerId: cleanLearnerId,
    );

    final Map<String, GradebookEntry> entryMap = {
      for (final e in entries) e.assessmentId: e,
    };

    final List<String> unmetCriteria = [];
    int completedCount = 0;
    int publishedCount = 0;
    double totalScore = 0.0;
    double totalMax = 0.0;

    if (requiredAssessments.isEmpty) {
      unmetCriteria.add('Cohort has no defined curriculum or assessments.');
    }

    for (final assessId in requiredAssessments) {
      final entry = entryMap[assessId];
      if (entry == null ||
          (entry.gradingStatus != GradingStatus.evaluated &&
              entry.gradingStatus != GradingStatus.published)) {
        unmetCriteria.add('Assessment $assessId has not been evaluated.');
        continue;
      }

      completedCount++;

      if (entry.publicationStatus != GradePublicationStatus.published) {
        unmetCriteria.add(
            'Assessment $assessId grade has not been published by faculty.');
        continue;
      }

      publishedCount++;

      final score = entry.finalScore ?? entry.originalScore ?? 0.0;
      final max = entry.finalMaxScore ?? entry.originalMaxScore ?? 100.0;
      final pct = entry.finalPercentage ?? entry.originalPercentage ?? 0.0;
      final isPassing = gradingPolicy.isPassing(pct);

      totalScore += score;
      totalMax += max;

      if (!isPassing || entry.letterGrade == 'F') {
        unmetCriteria.add(
          'Assessment $assessId received a failing grade (${entry.letterGrade ?? "F"}).',
        );
      }
    }

    final overallPct = totalMax > 0 ? ((totalScore / totalMax) * 100.0) : 0.0;

    if (overallPct < gradingPolicy.passingPercentage) {
      unmetCriteria.add(
        'Overall score ${overallPct.toStringAsFixed(1)}% is below the required passing threshold of ${gradingPolicy.passingPercentage}%.',
      );
    }

    final isEligible = unmetCriteria.isEmpty &&
        requiredAssessments.isNotEmpty &&
        publishedCount == requiredAssessments.length;

    return CompletionEligibility(
      isEligible: isEligible,
      learnerId: cleanLearnerId,
      cohortId: cleanCohortId,
      totalRequiredAssessments: requiredAssessments.length,
      completedAssessments: completedCount,
      publishedAssessments: publishedCount,
      overallPercentage: double.parse(overallPct.toStringAsFixed(2)),
      unmetCriteria: List.unmodifiable(unmetCriteria),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Transcript Generation & Versioning
  // ---------------------------------------------------------------------------

  /// Issues an official academic transcript.
  ///
  /// If a previous official transcript exists, it is marked as `reissued`
  /// pointing to the new revision, and a new immutable transcript `v(n+1)` is created.
  Future<AcademicTranscript> issueOfficialTranscript({
    required String learnerId,
    required String cohortId,
    required String facultyId,
    String? institutionName,
    String? programName,
    String? academicPeriod,
    String? tenantId,
  }) async {
    final cleanFacultyId = facultyId.trim();
    if (cleanFacultyId.isEmpty) {
      throw CredentialSecurityException(
          'Issuing faculty actor ID is required.');
    }
    if (cleanFacultyId == learnerId.trim()) {
      throw CredentialSecurityException(
        'A learner cannot issue their own official transcript.',
      );
    }

    final record = await generateAcademicRecord(
      learnerId: learnerId,
      cohortId: cohortId,
      requestingActorId: cleanFacultyId,
      requestingActorRole: 'faculty',
      tenantId: tenantId,
    );

    if (record.entries.isEmpty) {
      throw CredentialValidationException(
        'Cannot generate official transcript: no published grades exist for learner $learnerId.',
      );
    }

    final now = _clock();
    final existingTranscript =
        await credentialRepository.getOfficialTranscriptForLearner(
      learnerId: learnerId,
      cohortId: cohortId,
      tenantId: tenantId,
    );

    final int newVersion = (existingTranscript?.version ?? 0) + 1;
    final newTranscriptId = AcademicTranscript.generateId(
      cohortId: cohortId,
      learnerId: learnerId,
      version: newVersion,
    );

    // If an earlier official transcript existed, mark it as reissued
    if (existingTranscript != null) {
      final updatedPredecessor = existingTranscript.markReissued(
        supersededByTranscriptId: newTranscriptId,
        reissuedAt: now,
      );
      await credentialRepository.saveTranscript(updatedPredecessor);

      await credentialRepository.saveAuditRecord(CredentialAuditRecord(
        auditId: 'audit_reissue_${now.millisecondsSinceEpoch}_$newVersion',
        action: CredentialAuditAction.transcriptReissued,
        actorId: cleanFacultyId,
        actorRole: 'faculty',
        learnerId: learnerId,
        targetId: existingTranscript.transcriptId,
        reason: 'Superseded by official transcript $newTranscriptId',
        oldValue: {
          'status': existingTranscript.status.name,
          'version': existingTranscript.version
        },
        newValue: {
          'status': updatedPredecessor.status.name,
          'supersededBy': newTranscriptId
        },
        timestamp: now,
      ));
    }

    final transcriptEntries = record.entries
        .map((e) => TranscriptAssessmentEntry(
              assessmentId: e.assessmentId,
              assessmentTitle: e.assessmentTitle,
              score: e.finalScore,
              maxScore: e.maxScore,
              percentage: e.percentage,
              letterGrade: e.letterGrade,
              isPassed: e.isPassed,
              isOverridden: e.isOverridden,
              publishedAt: e.publishedAt,
            ))
        .toList();

    final transcript = AcademicTranscript(
      transcriptId: newTranscriptId,
      version: newVersion,
      tenantId: record.tenantId,
      learnerId: learnerId,
      institutionName: institutionName ?? record.institutionName,
      programName: programName ?? record.programName,
      cohortId: cohortId,
      academicPeriod: academicPeriod ?? record.academicPeriod,
      status: TranscriptStatus.official,
      entries: transcriptEntries,
      overallPercentage: record.overallPercentage,
      overallGrade: record.overallGrade,
      isCompleted: record.isCompleted,
      issuedAt: now,
      issuedByFacultyId: cleanFacultyId,
      reissuedFromTranscriptId: existingTranscript?.transcriptId,
    );

    await credentialRepository.saveTranscript(transcript);

    await credentialRepository.saveAuditRecord(CredentialAuditRecord(
      auditId: 'audit_tr_iss_${now.millisecondsSinceEpoch}_$newVersion',
      action: CredentialAuditAction.transcriptIssued,
      actorId: cleanFacultyId,
      actorRole: 'faculty',
      learnerId: learnerId,
      targetId: newTranscriptId,
      reason: 'Official transcript v$newVersion issued',
      newValue: {
        'transcriptId': newTranscriptId,
        'version': newVersion,
        'status': transcript.status.name
      },
      timestamp: now,
    ));

    return transcript;
  }

  /// Formally voids an issued academic transcript with mandatory justification.
  Future<AcademicTranscript> voidTranscript({
    required String transcriptId,
    required String facultyId,
    required String reason,
  }) async {
    final cleanFacultyId = facultyId.trim();
    final cleanReason = reason.trim();

    if (cleanFacultyId.isEmpty) {
      throw CredentialSecurityException('Faculty authorization required.');
    }
    if (cleanReason.isEmpty) {
      throw CredentialValidationException(
          'Void justification reason cannot be empty.');
    }

    final transcript = await credentialRepository.getTranscript(transcriptId);
    if (transcript == null) {
      throw CredentialNotFoundException('Transcript $transcriptId not found.');
    }

    final now = _clock();
    final voided = transcript.markVoid(
      voidByFacultyId: cleanFacultyId,
      reason: cleanReason,
      voidAt: now,
    );

    await credentialRepository.saveTranscript(voided);

    await credentialRepository.saveAuditRecord(CredentialAuditRecord(
      auditId: 'audit_tr_void_${now.millisecondsSinceEpoch}',
      action: CredentialAuditAction.transcriptVoided,
      actorId: cleanFacultyId,
      actorRole: 'faculty',
      learnerId: transcript.learnerId,
      targetId: transcriptId,
      reason: cleanReason,
      oldValue: {'status': transcript.status.name},
      newValue: {'status': voided.status.name, 'reason': cleanReason},
      timestamp: now,
    ));

    return voided;
  }

  // ---------------------------------------------------------------------------
  // 4. Completion Certificate Issuance & Revocation
  // ---------------------------------------------------------------------------

  /// Issues an official Course/Program Completion Certificate.
  ///
  /// Prevents issuance if learner is ineligible or if duplicate active certificate exists.
  /// Computes canonical SHA-256 fingerprint.
  Future<CompletionCertificate> issueCompletionCertificate({
    required String learnerId,
    required String cohortId,
    required String facultyId,
    String? learnerName,
    String? institutionName,
    String? programName,
    String? tenantId,
  }) async {
    final cleanFacultyId = facultyId.trim();
    final cleanLearnerId = learnerId.trim();
    final cleanCohortId = cohortId.trim();

    if (cleanFacultyId.isEmpty) {
      throw CredentialSecurityException('Faculty authorization required.');
    }
    if (cleanFacultyId == cleanLearnerId) {
      throw CredentialSecurityException(
        'A learner cannot issue their own completion certificate.',
      );
    }

    // Eligibility check
    final eligibility = await evaluateCompletionEligibility(
      learnerId: cleanLearnerId,
      cohortId: cleanCohortId,
      tenantId: tenantId,
    );

    if (!eligibility.isEligible) {
      throw CredentialValidationException(
        'Learner $cleanLearnerId is ineligible for certificate: ${eligibility.unmetCriteria.join("; ")}',
      );
    }

    // Duplicate issuance prevention
    final existingCert =
        await credentialRepository.getCertificateForLearnerCohort(
      learnerId: cleanLearnerId,
      cohortId: cleanCohortId,
      tenantId: tenantId,
    );

    if (existingCert != null &&
        existingCert.status == CertificateStatus.issued) {
      throw CredentialDuplicateException(
        'An active completion certificate (${existingCert.credentialId}) has already been issued for learner $cleanLearnerId in cohort $cleanCohortId.',
      );
    }

    final cohort = await cohortRepository.getCohortById(cleanCohortId);
    final instName = institutionName ?? 'QuizForge Institute of Technology';
    final progName =
        programName ?? cohort?.name ?? 'Comprehensive Legal Assessment Course';
    final now = _clock();

    // Generate unguessable canonical credential ID
    final randomSuffix = _generateRandomHex(8);
    final credentialId =
        'QFA-CERT-${cleanCohortId.replaceAll(RegExp(r"[^A-Za-z0-9]"), "").toUpperCase()}-${cleanLearnerId.replaceAll(RegExp(r"[^A-Za-z0-9]"), "").toUpperCase()}-$randomSuffix';
    final certificateId = 'cert_${cleanCohortId}_$cleanLearnerId';

    final certificate = CompletionCertificate(
      certificateId: certificateId,
      credentialId: credentialId,
      learnerId: cleanLearnerId,
      learnerName: learnerName,
      tenantId: cohort?.tenantId ?? tenantId ?? 'default_tenant',
      institutionName: instName,
      programName: progName,
      cohortId: cleanCohortId,
      completionDate: now,
      issuedAt: now,
      issuedByFacultyId: cleanFacultyId,
      status: CertificateStatus.issued,
      signatureAlgorithm: 'SHA-256',
      isDigitalSignature: false,
    );

    await credentialRepository.saveCertificate(certificate);

    await credentialRepository.saveAuditRecord(CredentialAuditRecord(
      auditId: 'audit_cert_iss_${now.millisecondsSinceEpoch}',
      action: CredentialAuditAction.certificateIssued,
      actorId: cleanFacultyId,
      actorRole: 'faculty',
      learnerId: cleanLearnerId,
      targetId: credentialId,
      reason: 'Official certificate issued upon completion',
      newValue: {
        'certificateId': certificateId,
        'credentialId': credentialId,
        'fingerprint': certificate.fingerprint,
      },
      timestamp: now,
    ));

    return certificate;
  }

  /// Formally revokes an issued completion certificate.
  Future<CompletionCertificate> revokeCertificate({
    required String certificateId,
    required String facultyId,
    required String reason,
  }) async {
    final cleanFacultyId = facultyId.trim();
    final cleanReason = reason.trim();

    if (cleanFacultyId.isEmpty) {
      throw CredentialSecurityException('Faculty actor identifier required.');
    }
    if (cleanReason.isEmpty) {
      throw CredentialValidationException(
          'Revocation justification reason cannot be empty.');
    }

    final certificate =
        await credentialRepository.getCertificate(certificateId);
    if (certificate == null) {
      throw CredentialNotFoundException(
          'Certificate $certificateId not found.');
    }

    final now = _clock();
    final revoked = certificate.revoke(
      facultyId: cleanFacultyId,
      reason: cleanReason,
      revokedAt: now,
    );

    await credentialRepository.saveCertificate(revoked);

    await credentialRepository.saveAuditRecord(CredentialAuditRecord(
      auditId: 'audit_cert_rev_${now.millisecondsSinceEpoch}',
      action: CredentialAuditAction.certificateRevoked,
      actorId: cleanFacultyId,
      actorRole: 'faculty',
      learnerId: certificate.learnerId,
      targetId: certificate.credentialId,
      reason: cleanReason,
      oldValue: {'status': certificate.status.name},
      newValue: {'status': revoked.status.name, 'reason': cleanReason},
      timestamp: now,
    ));

    return revoked;
  }

  // ---------------------------------------------------------------------------
  // 5. Verification Boundaries (Public & Offline)
  // ---------------------------------------------------------------------------

  /// Public credential verification boundary.
  ///
  /// Locates credential by ID -> Checks status -> Recomputes canonical fingerprint ->
  /// Returns minimal public disclosure.
  Future<CredentialVerificationResult> verifyCredential({
    required String credentialId,
    Map<String, dynamic>? clientPayload,
  }) async {
    final cleanId = credentialId.trim();
    if (cleanId.isEmpty) {
      return CredentialVerificationResult.notFound(cleanId);
    }

    final certificate =
        await credentialRepository.getCertificateByCredentialId(cleanId);

    if (certificate == null) {
      return CredentialVerificationResult.notFound(cleanId);
    }

    // Mask learner name for privacy (e.g. "Abhinav R.")
    final displayName =
        _maskLearnerName(certificate.learnerName ?? certificate.learnerId);

    if (certificate.status == CertificateStatus.revoked) {
      return CredentialVerificationResult.revoked(
        credentialId: certificate.credentialId,
        institutionName: certificate.institutionName,
        programName: certificate.programName,
        completionDate: certificate.completionDate,
        issuedAt: certificate.issuedAt,
        learnerDisplayName: displayName,
        reason: certificate.revocationReason,
      );
    }

    // If client supplied modified verification payload, test against that payload
    if (clientPayload != null) {
      final presentedFingerprint =
          clientPayload['fingerprint'] as String? ?? '';
      final payloadLid =
          clientPayload['learnerId'] as String? ?? certificate.learnerId;
      final payloadProg =
          clientPayload['programName'] as String? ?? certificate.programName;

      final testFingerprint = CompletionCertificate.computeFingerprint(
        credentialId: certificate.credentialId,
        learnerId: payloadLid,
        institutionName: certificate.institutionName,
        programName: payloadProg,
        cohortId: certificate.cohortId,
        completionDate: certificate.completionDate,
        issuedAt: certificate.issuedAt,
        issuedByFacultyId: certificate.issuedByFacultyId,
        tenantId: certificate.tenantId,
      );

      if (testFingerprint != certificate.fingerprint ||
          (presentedFingerprint.isNotEmpty &&
              presentedFingerprint != certificate.fingerprint)) {
        return CredentialVerificationResult.invalid(
          credentialId: certificate.credentialId,
          institutionName: certificate.institutionName,
          programName: certificate.programName,
        );
      }
    }

    // Verify stored record integrity against its fingerprint
    if (!certificate.verifyIntegrity()) {
      return CredentialVerificationResult.invalid(
        credentialId: certificate.credentialId,
        institutionName: certificate.institutionName,
        programName: certificate.programName,
      );
    }

    return CredentialVerificationResult.valid(
      credentialId: certificate.credentialId,
      institutionName: certificate.institutionName,
      programName: certificate.programName,
      completionDate: certificate.completionDate,
      issuedAt: certificate.issuedAt,
      learnerDisplayName: displayName,
    );
  }

  /// Offline verification boundary verifying a standalone certificate document.
  CredentialVerificationResult verifyCredentialOffline({
    required CompletionCertificate certificate,
  }) {
    final displayName =
        _maskLearnerName(certificate.learnerName ?? certificate.learnerId);

    if (certificate.status == CertificateStatus.revoked) {
      return CredentialVerificationResult.revoked(
        credentialId: certificate.credentialId,
        institutionName: certificate.institutionName,
        programName: certificate.programName,
        completionDate: certificate.completionDate,
        issuedAt: certificate.issuedAt,
        learnerDisplayName: displayName,
        reason: certificate.revocationReason,
      );
    }

    if (!certificate.verifyIntegrity()) {
      return CredentialVerificationResult.invalid(
        credentialId: certificate.credentialId,
        institutionName: certificate.institutionName,
        programName: certificate.programName,
      );
    }

    return CredentialVerificationResult.valid(
      credentialId: certificate.credentialId,
      institutionName: certificate.institutionName,
      programName: certificate.programName,
      completionDate: certificate.completionDate,
      issuedAt: certificate.issuedAt,
      learnerDisplayName: displayName,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generateRandomHex(int length) {
    final rand = Random();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(rand.nextInt(16).toRadixString(16));
    }
    return buffer.toString().toUpperCase();
  }

  String _maskLearnerName(String raw) {
    final parts = raw.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first} ${parts.last[0]}.';
    }
    if (raw.length > 3) {
      return '${raw.substring(0, 3)}***';
    }
    return raw;
  }

  Future<List<String>> _resolveRequiredAssessmentsForCohort(
    String cohortId,
    Cohort cohort,
  ) async {
    // 1. Explicit list in cohort metadata
    if (cohort.metadata['requiredAssessments'] is List) {
      return (cohort.metadata['requiredAssessments'] as List)
          .map((e) => e.toString())
          .toList();
    }
    // 2. Cohort assignments
    final assignments =
        await cohortRepository.listAssignments(cohortId: cohortId);
    final fromAssignments = assignments
        .where((a) => a.targetType == CohortAssignmentTargetType.assessment)
        .map((a) => a.targetId)
        .toList();
    if (fromAssignments.isNotEmpty) {
      return fromAssignments;
    }
    // 3. Assessments associated directly with this cohort
    if (assessmentRepository != null) {
      final assessments =
          await assessmentRepository!.listAssessments(cohortId: cohortId);
      if (assessments.isNotEmpty) {
        return assessments.map((a) => a.assessmentId).toList();
      }
    }
    // 4. Fallback to existing cohort gradebook entries
    final entries =
        await gradebookRepository.listGradeEntries(cohortId: cohortId);
    final distinct = entries.map((e) => e.assessmentId).toSet().toList();
    return distinct;
  }
}
