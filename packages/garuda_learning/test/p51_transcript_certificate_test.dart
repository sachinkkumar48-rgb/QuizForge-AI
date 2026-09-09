/// P51 Academic Transcripts, Completion Certificates & Credential Verification Test Suite (TITAN-KO-051.0).
///
/// Comprehensive suite verifying all 34 required test cases from Section 20:
/// 1. academic record construction
/// 2. unpublished grades excluded
/// 3. published grades included
/// 4. transcript generation
/// 5. deterministic ordering
/// 6. deterministic transcript content
/// 7. transcript ID
/// 8. transcript persistence
/// 9. transcript immutability
/// 10. transcript reissue
/// 11. old transcript preservation
/// 12. completion eligibility
/// 13. incomplete learner rejected
/// 14. certificate issuance
/// 15. certificate ID
/// 16. credential fingerprint
/// 17. fingerprint determinism
/// 18. credential tamper detection
/// 19. valid verification
/// 20. invalid verification
/// 21. revoked verification
/// 22. missing credential
/// 23. duplicate issuance prevention
/// 24. certificate persistence
/// 25. offline credential persistence
/// 26. synchronization
/// 27. learner isolation
/// 28. tenant isolation
/// 29. faculty authorization
/// 30. certificate revocation
/// 31. audit trail
/// 32. end-to-end transcript workflow
/// 33. end-to-end certificate workflow
/// 34. external/public verification boundary
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 1, 10, 0, 0);

  late InMemoryCredentialRepository credRepo;
  late InMemoryGradebookRepository gradebookRepo;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAssessmentRepository assessmentRepo;
  late AcademicCredentialService service;

  setUp(() async {
    credRepo = InMemoryCredentialRepository();
    gradebookRepo = InMemoryGradebookRepository();
    cohortRepo = InMemoryCohortRepository();
    assessmentRepo = InMemoryAssessmentRepository();

    service = AcademicCredentialService(
      credentialRepository: credRepo,
      gradebookRepository: gradebookRepo,
      cohortRepository: cohortRepo,
      assessmentRepository: assessmentRepo,
      clock: () => baseTime,
    );

    // Seed standard cohort
    await cohortRepo.saveCohort(Cohort(
      cohortId: 'cohort_law_101',
      name: 'Constitutional Law Mastery 2026',
      examId: 'clat_pg_2026',
      primaryFacultyId: 'faculty_sharma',
      learnerIds: {'learner_001', 'learner_002'},
      metadata: {'academicPeriod': 'Autumn 2026'},
    ));

    // Seed assessments
    await assessmentRepo.saveAssessment(Assessment(
      assessmentId: 'assess_const_01',
      tenantId: 'tenant_nlsiu',
      cohortIds: {'cohort_law_101'},
      creatorFacultyId: 'faculty_sharma',
      examId: 'clat_pg_2026',
      title: 'Fundamental Rights & Judicial Review',
      questionIds: ['q1', 'q2'],
    ));
    await assessmentRepo.saveAssessment(Assessment(
      assessmentId: 'assess_const_02',
      tenantId: 'tenant_nlsiu',
      cohortIds: {'cohort_law_101'},
      creatorFacultyId: 'faculty_sharma',
      examId: 'clat_pg_2026',
      title: 'Directive Principles & State Policy',
      questionIds: ['q3', 'q4'],
    ));
  });

  // Helper to ingest grades
  Future<void> ingestGrade({
    required String cohortId,
    required String assessmentId,
    required String learnerId,
    required double score,
    required double maxScore,
    required bool isPublished,
    bool isPassing = true,
  }) async {
    final entry = GradebookEntry(
      entryId: GradebookEntry.generateId(
        cohortId: cohortId,
        assessmentId: assessmentId,
        learnerId: learnerId,
      ),
      tenantId: 'tenant_nlsiu',
      cohortId: cohortId,
      assessmentId: assessmentId,
      learnerId: learnerId,
      finalScore: score,
      finalMaxScore: maxScore,
      finalPercentage: (score / maxScore) * 100.0,
      letterGrade: isPassing ? 'A' : 'F',
      gradingStatus:
          isPublished ? GradingStatus.published : GradingStatus.evaluated,
      publicationStatus: isPublished
          ? GradePublicationStatus.published
          : GradePublicationStatus.unpublished,
      publishedAt: isPublished ? baseTime : null,
      publishedByFacultyId: isPublished ? 'faculty_sharma' : null,
    );
    await gradebookRepo.saveGradeEntry(entry);
  }

  group('Section 20: Academic Record & Transcripts', () {
    // 1. academic record construction
    test('1. academic record construction aggregates authoritative outcomes',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final record = await service.generateAcademicRecord(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        requestingActorId: 'faculty_sharma',
      );

      expect(record.learnerId, 'learner_001');
      expect(record.cohortId, 'cohort_law_101');
      expect(record.entries.length, 1);
      expect(record.entries.first.assessmentId, 'assess_const_01');
      expect(record.entries.first.assessmentTitle,
          'Fundamental Rights & Judicial Review');
      expect(record.overallPercentage, 85.0);
      expect(record.overallGrade, 'A');
    });

    // 2. unpublished grades excluded
    test('2. unpublished grades excluded from academic record', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: false, // NOT published
      );

      final record = await service.generateAcademicRecord(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        requestingActorId: 'faculty_sharma',
      );

      expect(record.entries, isEmpty);
      expect(record.totalAssessments, 0);
    });

    // 3. published grades included
    test('3. published grades included while unpublished are ignored',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true, // published
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 95.0,
        maxScore: 100.0,
        isPublished: false, // unpublished
      );

      final record = await service.generateAcademicRecord(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        requestingActorId: 'faculty_sharma',
      );

      expect(record.entries.length, 1);
      expect(record.entries.first.assessmentId, 'assess_const_01');
      expect(record.totalAssessments, 1);
    });

    // 4. transcript generation
    test('4. transcript generation produces official academic transcript',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 88.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final transcript = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(transcript.status, TranscriptStatus.official);
      expect(transcript.version, 1);
      expect(transcript.learnerId, 'learner_001');
      expect(transcript.issuedByFacultyId, 'faculty_sharma');
      expect(transcript.entries.length, 1);
    });

    // 5. deterministic ordering
    test('5. deterministic ordering sorts assessments stably by ID', () async {
      // Ingest in reverse order
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 92.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 84.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final transcript = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(transcript.entries[0].assessmentId, 'assess_const_01');
      expect(transcript.entries[1].assessmentId, 'assess_const_02');
    });

    // 6. deterministic transcript content
    test('6. deterministic transcript content given identical inputs',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 88.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final rec1 = await service.generateAcademicRecord(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        requestingActorId: 'faculty_sharma',
      );
      final rec2 = await service.generateAcademicRecord(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        requestingActorId: 'faculty_sharma',
      );

      expect(rec1.overallPercentage, rec2.overallPercentage);
      expect(rec1.entries.length, rec2.entries.length);
      expect(rec1.entries.first.finalScore, rec2.entries.first.finalScore);
    });

    // 7. transcript ID
    test('7. transcript ID follows canonical naming convention', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 75.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final transcript = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(transcript.transcriptId, 'tr_cohort_law_101_learner_001_v1');
    });

    // 8. transcript persistence
    test('8. transcript persistence saves and retrieves from repository',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final transcript = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final retrieved = await credRepo.getTranscript(transcript.transcriptId);
      expect(retrieved, isNotNull);
      expect(retrieved!.transcriptId, transcript.transcriptId);
      expect(retrieved.status, TranscriptStatus.official);
    });

    // 9. transcript immutability
    test('9. transcript immutability prevents silent in-place overwrite',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final v1 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(v1.version, 1);
      expect(v1.status, TranscriptStatus.official);

      // Mutating gradebook should not alter already saved v1
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 95.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final storedV1 = await credRepo.getTranscript(v1.transcriptId);
      expect(storedV1!.entries.first.score, 80.0);
    });

    // 10. transcript reissue
    test('10. transcript reissue increments version and supersedes previous',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final v1 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );
      expect(v1.version, 1);

      // Academic correction or new grade
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final v2 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(v2.version, 2);
      expect(v2.status, TranscriptStatus.official);
      expect(v2.transcriptId, 'tr_cohort_law_101_learner_001_v2');
      expect(v2.reissuedFromTranscriptId, v1.transcriptId);
    });

    // 11. old transcript preservation
    test(
        '11. old transcript preservation marks v1 as reissued without deletion',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final v1 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final v2 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final historicalV1 = await credRepo.getTranscript(v1.transcriptId);
      expect(historicalV1, isNotNull);
      expect(historicalV1!.status, TranscriptStatus.reissued);
      expect(historicalV1.supersededByTranscriptId, v2.transcriptId);
    });
  });

  group('Section 20: Completion Eligibility & Certificates', () {
    // 12. completion eligibility
    test('12. completion eligibility detects fully completed program',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final eligibility = await service.evaluateCompletionEligibility(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
      );

      expect(eligibility.isEligible, isTrue);
      expect(eligibility.completedAssessments, 2);
      expect(eligibility.publishedAssessments, 2);
      expect(eligibility.unmetCriteria, isEmpty);
    });

    // 13. incomplete learner rejected
    test('13. incomplete learner rejected for certificate issuance', () async {
      // Only 1 of 2 assessments completed
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final eligibility = await service.evaluateCompletionEligibility(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
      );

      expect(eligibility.isEligible, isFalse);
      expect(eligibility.unmetCriteria, isNotEmpty);

      expect(
        () => service.issueCompletionCertificate(
          learnerId: 'learner_001',
          cohortId: 'cohort_law_101',
          facultyId: 'faculty_sharma',
        ),
        throwsA(isA<CredentialValidationException>()),
      );
    });

    // 14. certificate issuance
    test(
        '14. certificate issuance creates official certificate with criteria met',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
        learnerName: 'Abhinav Rajput',
      );

      expect(cert.status, CertificateStatus.issued);
      expect(cert.learnerId, 'learner_001');
      expect(cert.learnerName, 'Abhinav Rajput');
      expect(cert.isDigitalSignature, isFalse);
      expect(cert.signatureAlgorithm, 'SHA-256');
    });

    // 15. certificate ID
    test('15. certificate ID and credential ID are unguessable and formatted',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(cert.certificateId, 'cert_cohort_law_101_learner_001');
      expect(
          cert.credentialId, startsWith('QFA-CERT-COHORTLAW101-LEARNER001-'));
      expect(cert.credentialId.length, greaterThan(30));
    });

    // 16. credential fingerprint
    test('16. credential fingerprint computes valid SHA-256 hash', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(cert.fingerprint, isNotEmpty);
      expect(cert.fingerprint.length, 64); // SHA-256 hex length
      expect(cert.verifyIntegrity(), isTrue);
    });

    // 17. fingerprint determinism
    test('17. fingerprint determinism produces identical hash for same data',
        () {
      final now = DateTime.utc(2026, 11, 1, 12, 0, 0);
      final fp1 = CompletionCertificate.computeFingerprint(
        credentialId: 'QFA-CERT-001',
        learnerId: 'learner_001',
        institutionName: 'QuizForge Institute of Technology',
        programName: 'Constitutional Law',
        cohortId: 'cohort_law_101',
        completionDate: now,
        issuedAt: now,
        issuedByFacultyId: 'faculty_sharma',
        tenantId: 'tenant_nlsiu',
      );
      final fp2 = CompletionCertificate.computeFingerprint(
        credentialId: 'QFA-CERT-001',
        learnerId: 'learner_001',
        institutionName: 'QuizForge Institute of Technology',
        programName: 'Constitutional Law',
        cohortId: 'cohort_law_101',
        completionDate: now,
        issuedAt: now,
        issuedByFacultyId: 'faculty_sharma',
        tenantId: 'tenant_nlsiu',
      );

      expect(fp1, fp2);
    });

    // 18. credential tamper detection
    test('18. credential tamper detection flags tampered certificate content',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      // Tampered certificate with modified learnerId
      final tampered = cert.copyWith(learnerId: 'malicious_impostor');
      expect(tampered.verifyIntegrity(), isFalse);
    });

    // 19. valid verification
    test('19. valid verification confirms genuine untouched certificate',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
        learnerName: 'Abhinav Rajput',
      );

      final result =
          await service.verifyCredential(credentialId: cert.credentialId);
      expect(result.isValid, isTrue);
      expect(result.status, CredentialVerificationStatus.valid);
      expect(result.learnerDisplayName, 'Abhinav R.');
      expect(result.isTampered, isFalse);
    });

    // 20. invalid verification
    test('20. invalid verification flags payload discrepancy', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      // Client attempts to verify with tampered program name
      final result = await service.verifyCredential(
        credentialId: cert.credentialId,
        clientPayload: {
          'fingerprint': 'tampered_hash',
          'programName': 'Fake Degree',
        },
      );

      expect(result.status, CredentialVerificationStatus.invalid);
      expect(result.isTampered, isTrue);
    });

    // 21. revoked verification
    test('21. revoked verification returns revoked status', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      await service.revokeCertificate(
        certificateId: cert.certificateId,
        facultyId: 'faculty_sharma',
        reason: 'Academic integrity disciplinary action',
      );

      final result =
          await service.verifyCredential(credentialId: cert.credentialId);
      expect(result.status, CredentialVerificationStatus.revoked);
      expect(result.isRevoked, isTrue);
      expect(
          result.message, contains('Academic integrity disciplinary action'));
    });

    // 22. missing credential
    test('22. missing credential returns notFound outcome', () async {
      final result =
          await service.verifyCredential(credentialId: 'NON_EXISTENT_ID');
      expect(result.status, CredentialVerificationStatus.notFound);
      expect(result.isNotFound, isTrue);
    });

    // 23. duplicate issuance prevention
    test('23. duplicate issuance prevention blocks second active certificate',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      expect(
        () => service.issueCompletionCertificate(
          learnerId: 'learner_001',
          cohortId: 'cohort_law_101',
          facultyId: 'faculty_sharma',
        ),
        throwsA(isA<CredentialDuplicateException>()),
      );
    });

    // 24. certificate persistence
    test('24. certificate persistence saves and recovers through snapshot',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final snapshot = await credRepo.exportSnapshot();

      // Clear repo to simulate full application restart
      final newRepo = InMemoryCredentialRepository();
      await newRepo.importSnapshot(snapshot);

      final recovered =
          await newRepo.getCertificateByCredentialId(cert.credentialId);
      expect(recovered, isNotNull);
      expect(recovered!.credentialId, cert.credentialId);
      expect(recovered.verifyIntegrity(), isTrue);
    });

    // 25. offline credential persistence
    test(
        '25. offline credential persistence verifies offline without remote lookup',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final offlineResult = service.verifyCredentialOffline(certificate: cert);
      expect(offlineResult.isValid, isTrue);
    });

    // 26. synchronization
    test('26. synchronization preserves idempotency and prevents overwrites',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final snap = await credRepo.exportSnapshot();
      // Import again (idempotent sync)
      await credRepo.importSnapshot(snap);

      final existing =
          await credRepo.getCertificateByCredentialId(cert.credentialId);
      expect(existing, isNotNull);
      expect(existing!.fingerprint, cert.fingerprint);
    });

    // 27. learner isolation
    test(
        '27. learner isolation rejects cross-learner private record inspection',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );

      // learner_002 tries to view learner_001's private record
      expect(
        () => service.generateAcademicRecord(
          learnerId: 'learner_001',
          cohortId: 'cohort_law_101',
          requestingActorId: 'learner_002',
          requestingActorRole: 'learner',
        ),
        throwsA(isA<CredentialSecurityException>()),
      );
    });

    // 28. tenant isolation
    test('28. tenant isolation blocks access from foreign tenant', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );

      expect(
        () => service.generateAcademicRecord(
          learnerId: 'learner_001',
          cohortId: 'cohort_law_101',
          requestingActorId: 'faculty_foreign',
          tenantId: 'foreign_institution_tenant',
        ),
        throwsA(isA<CredentialSecurityException>()),
      );
    });

    // 29. faculty authorization
    test('29. faculty authorization prevents learner self-issuing certificate',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      expect(
        () => service.issueCompletionCertificate(
          learnerId: 'learner_001',
          cohortId: 'cohort_law_101',
          facultyId: 'learner_001', // Self-issuance attempt
        ),
        throwsA(isA<CredentialSecurityException>()),
      );
    });

    // 30. certificate revocation
    test('30. certificate revocation updates status and records reason',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final revoked = await service.revokeCertificate(
        certificateId: cert.certificateId,
        facultyId: 'faculty_sharma',
        reason: 'Plagiarism detected post-issuance',
      );

      expect(revoked.status, CertificateStatus.revoked);
      expect(revoked.revocationReason, 'Plagiarism detected post-issuance');
      expect(revoked.revokedByFacultyId, 'faculty_sharma');
    });

    // 31. audit trail
    test('31. audit trail logs all issuance and revocation actions', () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );

      await service.revokeCertificate(
        certificateId: cert.certificateId,
        facultyId: 'faculty_sharma',
        reason: 'Administrative void',
      );

      final audit = await credRepo.listAuditRecords(learnerId: 'learner_001');
      expect(audit.length, 3);
      expect(audit[0].action, CredentialAuditAction.transcriptIssued);
      expect(audit[1].action, CredentialAuditAction.certificateIssued);
      expect(audit[2].action, CredentialAuditAction.certificateRevoked);
    });

    // 32. end-to-end transcript workflow
    test('32. end-to-end transcript workflow from grades to reissue and void',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 80.0,
        maxScore: 100.0,
        isPublished: true,
      );

      // Issue v1
      final v1 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );
      expect(v1.version, 1);
      expect(v1.status, TranscriptStatus.official);

      // Reissue v2
      final v2 = await service.issueOfficialTranscript(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
      );
      expect(v2.version, 2);
      expect(v2.status, TranscriptStatus.official);

      // Void v2
      final voidedV2 = await service.voidTranscript(
        transcriptId: v2.transcriptId,
        facultyId: 'faculty_sharma',
        reason: 'Correction needed in grading schema',
      );
      expect(voidedV2.status, TranscriptStatus.voidRecord);
      expect(voidedV2.voidReason, 'Correction needed in grading schema');
    });

    // 33. end-to-end certificate workflow
    test(
        '33. end-to-end certificate workflow: complete -> issue -> verify -> revoke',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
        learnerName: 'Abhinav Rajput',
      );

      // Verify active
      final vResult =
          await service.verifyCredential(credentialId: cert.credentialId);
      expect(vResult.status, CredentialVerificationStatus.valid);

      // Revoke
      await service.revokeCertificate(
        certificateId: cert.certificateId,
        facultyId: 'faculty_sharma',
        reason: 'Revoked for testing',
      );

      // Verify revoked
      final vRevoked =
          await service.verifyCredential(credentialId: cert.credentialId);
      expect(vRevoked.status, CredentialVerificationStatus.revoked);
    });

    // 34. external/public verification boundary
    test(
        '34. external/public verification boundary prevents private data leakage',
        () async {
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_01',
        learnerId: 'learner_001',
        score: 85.0,
        maxScore: 100.0,
        isPublished: true,
      );
      await ingestGrade(
        cohortId: 'cohort_law_101',
        assessmentId: 'assess_const_02',
        learnerId: 'learner_001',
        score: 90.0,
        maxScore: 100.0,
        isPublished: true,
      );

      final cert = await service.issueCompletionCertificate(
        learnerId: 'learner_001',
        cohortId: 'cohort_law_101',
        facultyId: 'faculty_sharma',
        learnerName: 'Abhinav Rajput',
      );

      final publicResult =
          await service.verifyCredential(credentialId: cert.credentialId);

      final json = publicResult.toJson();
      // Verify no sensitive analytics or private answers are leaked in public response
      expect(json.containsKey('answers'), isFalse);
      expect(json.containsKey('analytics'), isFalse);
      expect(json.containsKey('questionHistory'), isFalse);
      expect(publicResult.learnerDisplayName, 'Abhinav R.');
    });
  });
}
