/// P51 Academic Transcripts & Credential Verification End-to-End Integration Suite (TITAN-KO-051.0).
///
/// Section 21 Mandatory Closed-Loop Acceptance Scenario:
/// LEARNER -> COMPLETES REQUIRED ACADEMIC WORK
/// FACULTY -> REVIEWS PUBLISHED GRADES
/// SYSTEM -> DETERMINES COMPLETION ELIGIBILITY
/// FACULTY -> GENERATES OFFICIAL TRANSCRIPT
/// VERIFY:
/// - correct learner
/// - correct cohort/program
/// - only published grades
/// - correct scores/grades
/// - deterministic ordering
/// - official status
/// Then:
/// FACULTY -> ISSUES CERTIFICATE
/// VERIFY:
/// - credential ID generated
/// - fingerprint generated
/// - certificate persisted
/// - learner can see certificate
/// Then:
/// EXTERNAL VERIFIER -> ENTERS CREDENTIAL ID -> VERIFIES
/// EXPECTED: VALID
/// Then alter verification payload.
/// EXPECTED: INVALID / integrity failure
/// Then revoke certificate.
/// EXPECTED: REVOKED
/// Then restart application and repeat verification.
/// EXPECTED: same authoritative status.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 14, 0, 0);

  late InMemoryCredentialRepository credRepo;
  late InMemoryGradebookRepository gradebookRepo;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAssessmentRepository assessmentRepo;
  late GradebookService gradebookService;
  late AcademicCredentialService credentialService;

  setUp(() async {
    credRepo = InMemoryCredentialRepository();
    gradebookRepo = InMemoryGradebookRepository();
    cohortRepo = InMemoryCohortRepository();
    assessmentRepo = InMemoryAssessmentRepository();

    gradebookService = GradebookService(
      repository: gradebookRepo,
      cohortRepository: cohortRepo,
      clock: () => now,
    );

    credentialService = AcademicCredentialService(
      credentialRepository: credRepo,
      gradebookRepository: gradebookRepo,
      cohortRepository: cohortRepo,
      assessmentRepository: assessmentRepo,
      clock: () => now,
    );

    // 1. Institutional Cohort
    await cohortRepo.saveCohort(Cohort(
      cohortId: 'cohort_bar_exam_2026',
      name: 'All India Bar Examination Intensive',
      examId: 'aibe_2026',
      primaryFacultyId: 'faculty_adv_sharma',
      learnerIds: {'learner_abhinav'},
      tenantId: 'tenant_bar_council',
      metadata: {'academicPeriod': 'Winter 2026'},
    ));

    // 2. Assessments
    await assessmentRepo.saveAssessment(Assessment(
      assessmentId: 'assess_crpc_01',
      title: 'Code of Criminal Procedure & Evidence',
      examId: 'aibe_2026',
      cohortIds: {'cohort_bar_exam_2026'},
      creatorFacultyId: 'faculty_adv_sharma',
      tenantId: 'tenant_bar_council',
      questionIds: ['q1', 'q2', 'q3'],
    ));

    await assessmentRepo.saveAssessment(Assessment(
      assessmentId: 'assess_cpc_01',
      title: 'Code of Civil Procedure & Pleadings',
      examId: 'aibe_2026',
      cohortIds: {'cohort_bar_exam_2026'},
      creatorFacultyId: 'faculty_adv_sharma',
      tenantId: 'tenant_bar_council',
      questionIds: ['q4', 'q5', 'q6'],
    ));
  });

  test(
      'Section 21: Full Closed-Loop Transcript, Certificate & Verification Acceptance',
      () async {
    // -------------------------------------------------------------------------
    // STEP 1: LEARNER COMPLETES REQUIRED ACADEMIC WORK
    // Raw evaluation results stored in gradebook as evaluated (unpublished)
    // -------------------------------------------------------------------------
    final entry1 = GradebookEntry(
      entryId: GradebookEntry.generateId(
        cohortId: 'cohort_bar_exam_2026',
        assessmentId: 'assess_crpc_01',
        learnerId: 'learner_abhinav',
      ),
      tenantId: 'tenant_bar_council',
      cohortId: 'cohort_bar_exam_2026',
      assessmentId: 'assess_crpc_01',
      learnerId: 'learner_abhinav',
      originalScore: 88.0,
      originalMaxScore: 100.0,
      originalPercentage: 88.0,
      finalScore: 88.0,
      finalMaxScore: 100.0,
      finalPercentage: 88.0,
      letterGrade: 'A',
      gradingStatus: GradingStatus.evaluated,
      publicationStatus: GradePublicationStatus.unpublished,
    );
    await gradebookRepo.saveGradeEntry(entry1);

    final entry2 = GradebookEntry(
      entryId: GradebookEntry.generateId(
        cohortId: 'cohort_bar_exam_2026',
        assessmentId: 'assess_cpc_01',
        learnerId: 'learner_abhinav',
      ),
      tenantId: 'tenant_bar_council',
      cohortId: 'cohort_bar_exam_2026',
      assessmentId: 'assess_cpc_01',
      learnerId: 'learner_abhinav',
      originalScore: 92.0,
      originalMaxScore: 100.0,
      originalPercentage: 92.0,
      finalScore: 92.0,
      finalMaxScore: 100.0,
      finalPercentage: 92.0,
      letterGrade: 'A+',
      gradingStatus: GradingStatus.evaluated,
      publicationStatus: GradePublicationStatus.unpublished,
    );
    await gradebookRepo.saveGradeEntry(entry2);

    // Verify: unpublished grades NOT eligible yet
    final initialEligibility =
        await credentialService.evaluateCompletionEligibility(
      learnerId: 'learner_abhinav',
      cohortId: 'cohort_bar_exam_2026',
    );
    expect(initialEligibility.isEligible, isFalse);
    expect(initialEligibility.unmetCriteria,
        contains(contains('not been published')));

    // -------------------------------------------------------------------------
    // STEP 2: FACULTY REVIEWS AND PUBLISHES GRADES
    // -------------------------------------------------------------------------
    await gradebookService.publishCohortGrades(
      'cohort_bar_exam_2026',
      facultyId: 'faculty_adv_sharma',
    );

    // -------------------------------------------------------------------------
    // STEP 3: SYSTEM DETERMINES COMPLETION ELIGIBILITY
    // -------------------------------------------------------------------------
    final postPublishEligibility =
        await credentialService.evaluateCompletionEligibility(
      learnerId: 'learner_abhinav',
      cohortId: 'cohort_bar_exam_2026',
    );
    expect(postPublishEligibility.isEligible, isTrue);
    expect(postPublishEligibility.completedAssessments, 2);
    expect(postPublishEligibility.publishedAssessments, 2);
    expect(postPublishEligibility.overallPercentage, 90.0);
    expect(postPublishEligibility.unmetCriteria, isEmpty);

    // -------------------------------------------------------------------------
    // STEP 4: FACULTY GENERATES OFFICIAL TRANSCRIPT
    // -------------------------------------------------------------------------
    final transcript = await credentialService.issueOfficialTranscript(
      learnerId: 'learner_abhinav',
      cohortId: 'cohort_bar_exam_2026',
      facultyId: 'faculty_adv_sharma',
      programName: 'Bar Examination Certification Course',
      academicPeriod: 'Winter 2026',
    );

    // VERIFY:
    // - correct learner
    expect(transcript.learnerId, 'learner_abhinav');
    // - correct cohort/program
    expect(transcript.cohortId, 'cohort_bar_exam_2026');
    expect(transcript.programName, 'Bar Examination Certification Course');
    // - only published grades
    expect(transcript.entries.length, 2);
    // - correct scores/grades
    expect(transcript.overallPercentage, 90.0);
    expect(transcript.overallGrade, 'A');
    // - deterministic ordering (alphabetical by assessmentId)
    expect(transcript.entries[0].assessmentId, 'assess_cpc_01');
    expect(transcript.entries[0].assessmentTitle,
        'Code of Civil Procedure & Pleadings');
    expect(transcript.entries[1].assessmentId, 'assess_crpc_01');
    expect(transcript.entries[1].assessmentTitle,
        'Code of Criminal Procedure & Evidence');
    // - official status
    expect(transcript.status, TranscriptStatus.official);
    expect(transcript.version, 1);

    // -------------------------------------------------------------------------
    // STEP 5: FACULTY ISSUES CERTIFICATE
    // -------------------------------------------------------------------------
    final certificate = await credentialService.issueCompletionCertificate(
      learnerId: 'learner_abhinav',
      cohortId: 'cohort_bar_exam_2026',
      facultyId: 'faculty_adv_sharma',
      learnerName: 'Abhinav Rajput',
      programName: 'Bar Examination Certification Course',
    );

    // VERIFY:
    // - credential ID generated
    expect(certificate.credentialId, isNotEmpty);
    expect(certificate.credentialId,
        startsWith('QFA-CERT-COHORTBAREXAM2026-LEARNERABHINAV-'));
    // - fingerprint generated
    expect(certificate.fingerprint, isNotEmpty);
    expect(certificate.fingerprint.length, 64);
    // - certificate persisted
    final storedCert = await credRepo.getCertificate(certificate.certificateId);
    expect(storedCert, isNotNull);
    // - learner can see certificate
    final learnerCerts =
        await credRepo.listCertificatesForLearner(learnerId: 'learner_abhinav');
    expect(learnerCerts.length, 1);
    expect(learnerCerts.first.credentialId, certificate.credentialId);

    // -------------------------------------------------------------------------
    // STEP 6: EXTERNAL VERIFIER ENTERS CREDENTIAL ID -> VERIFIES
    // EXPECTED: VALID
    // -------------------------------------------------------------------------
    final validVerification = await credentialService.verifyCredential(
      credentialId: certificate.credentialId,
    );
    expect(validVerification.status, CredentialVerificationStatus.valid);
    expect(validVerification.isValid, isTrue);
    expect(validVerification.learnerDisplayName, 'Abhinav R.');
    expect(
        validVerification.programName, 'Bar Examination Certification Course');
    expect(validVerification.isTampered, isFalse);

    // -------------------------------------------------------------------------
    // STEP 7: ALTER VERIFICATION PAYLOAD
    // EXPECTED: INVALID / integrity failure
    // -------------------------------------------------------------------------
    final tamperedVerification = await credentialService.verifyCredential(
      credentialId: certificate.credentialId,
      clientPayload: {
        'fingerprint': 'tampered_sha256_hash_99999999999999999999999999999999',
        'programName': 'Fraudulent Executive Degree',
      },
    );
    expect(tamperedVerification.status, CredentialVerificationStatus.invalid);
    expect(tamperedVerification.isInvalid, isTrue);
    expect(tamperedVerification.isTampered, isTrue);

    // -------------------------------------------------------------------------
    // STEP 8: REVOKE CERTIFICATE
    // EXPECTED: REVOKED
    // -------------------------------------------------------------------------
    await credentialService.revokeCertificate(
      certificateId: certificate.certificateId,
      facultyId: 'faculty_adv_sharma',
      reason: 'Course requirements amended by Bar Council order',
    );

    final revokedVerification = await credentialService.verifyCredential(
      credentialId: certificate.credentialId,
    );
    expect(revokedVerification.status, CredentialVerificationStatus.revoked);
    expect(revokedVerification.isRevoked, isTrue);
    expect(revokedVerification.message,
        contains('Course requirements amended by Bar Council order'));

    // -------------------------------------------------------------------------
    // STEP 9: RESTART APPLICATION AND REPEAT VERIFICATION
    // EXPECTED: SAME AUTHORITATIVE STATUS
    // -------------------------------------------------------------------------
    final snapshot = await credRepo.exportSnapshot();

    // Restart: brand new instances simulating reboot
    final rebootedCredRepo = InMemoryCredentialRepository();
    await rebootedCredRepo.importSnapshot(snapshot);

    final rebootedService = AcademicCredentialService(
      credentialRepository: rebootedCredRepo,
      gradebookRepository: gradebookRepo,
      cohortRepository: cohortRepo,
      assessmentRepository: assessmentRepo,
      clock: () => now,
    );

    final postRestartVerification = await rebootedService.verifyCredential(
      credentialId: certificate.credentialId,
    );
    expect(
        postRestartVerification.status, CredentialVerificationStatus.revoked);
    expect(postRestartVerification.isRevoked, isTrue);
    expect(postRestartVerification.message,
        contains('Course requirements amended by Bar Council order'));

    // Transcripts also survived restart intact
    final rebootedTranscripts =
        await rebootedCredRepo.listTranscriptsForLearner(
      learnerId: 'learner_abhinav',
    );
    expect(rebootedTranscripts.length, 1);
    expect(rebootedTranscripts.first.transcriptId, transcript.transcriptId);
    expect(rebootedTranscripts.first.overallGrade, 'A');
    expect(rebootedTranscripts.first.status, TranscriptStatus.official);
  });
}
