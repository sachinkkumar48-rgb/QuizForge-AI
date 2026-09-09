/// Academic Credential Repository Contract (TITAN-KO-051.0 P51).
///
/// Abstract repository interface specifying storage, retrieval,
/// snapshot persistence, and audit logging for transcripts and certificates.
library;

import '../domain/entities/academic_transcript.dart';
import '../domain/entities/completion_certificate.dart';
import '../domain/entities/credential_audit_record.dart';

/// Base exception for academic credential storage operations.
class CredentialException implements Exception {
  final String message;
  final dynamic cause;
  CredentialException(this.message, [this.cause]);
  @override
  String toString() => 'CredentialException: $message';
}

/// Thrown when a requested transcript or certificate cannot be located.
class CredentialNotFoundException extends CredentialException {
  CredentialNotFoundException(super.message, [super.cause]);
}

/// Thrown when credential data fails business rules or validation.
class CredentialValidationException extends CredentialException {
  CredentialValidationException(super.message, [super.cause]);
}

/// Thrown when an unauthorized actor attempts an issuing/revoking or isolation breach.
class CredentialSecurityException extends CredentialException {
  CredentialSecurityException(super.message, [super.cause]);
}

/// Thrown when duplicate certificate issuance is attempted for an active certificate.
class CredentialDuplicateException extends CredentialException {
  CredentialDuplicateException(super.message, [super.cause]);
}

/// Abstract contract for managing transcripts, certificates, and credential audit trails.
abstract class CredentialRepository {
  // Transcripts
  Future<void> saveTranscript(AcademicTranscript transcript);
  Future<AcademicTranscript?> getTranscript(String transcriptId);
  Future<AcademicTranscript?> getOfficialTranscriptForLearner({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  });
  Future<List<AcademicTranscript>> listTranscriptsForLearner({
    required String learnerId,
    String? tenantId,
  });
  Future<List<AcademicTranscript>> listTranscripts({
    String? cohortId,
    String? tenantId,
    TranscriptStatus? status,
  });

  // Certificates
  Future<void> saveCertificate(CompletionCertificate certificate);
  Future<CompletionCertificate?> getCertificate(String certificateId);
  Future<CompletionCertificate?> getCertificateByCredentialId(
      String credentialId);
  Future<CompletionCertificate?> getCertificateForLearnerCohort({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  });
  Future<List<CompletionCertificate>> listCertificatesForLearner({
    required String learnerId,
    String? tenantId,
  });
  Future<List<CompletionCertificate>> listCertificates({
    String? cohortId,
    String? tenantId,
    CertificateStatus? status,
  });

  // Audit Logs
  Future<void> saveAuditRecord(CredentialAuditRecord record);
  Future<List<CredentialAuditRecord>> listAuditRecords({
    String? learnerId,
    String? targetId,
  });

  // Persistence & Snapshots
  Future<Map<String, dynamic>> exportSnapshot();
  Future<void> importSnapshot(Map<String, dynamic> snapshot);
  Future<void> clear();
}
