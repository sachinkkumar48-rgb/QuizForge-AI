/// In-Memory Academic Credential Repository Implementation (TITAN-KO-051.0 P51).
///
/// Thread-safe in-memory store supporting snapshots, restart persistence,
/// and failure simulation for unit testing and offline execution.
library;

import '../domain/entities/academic_transcript.dart';
import '../domain/entities/completion_certificate.dart';
import '../domain/entities/credential_audit_record.dart';
import 'credential_repository.dart';

class InMemoryCredentialRepository implements CredentialRepository {
  final Map<String, AcademicTranscript> _transcripts = {};
  final Map<String, CompletionCertificate> _certificates = {};
  final List<CredentialAuditRecord> _auditRecords = [];

  bool _simulateFailure = false;

  void setSimulateFailure(bool simulate) {
    _simulateFailure = simulate;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw CredentialException('Simulated repository storage failure');
    }
  }

  // ---------------------------------------------------------------------------
  // Transcripts
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveTranscript(AcademicTranscript transcript) async {
    _checkFailure();
    _transcripts[transcript.transcriptId] = transcript;
  }

  @override
  Future<AcademicTranscript?> getTranscript(String transcriptId) async {
    _checkFailure();
    return _transcripts[transcriptId];
  }

  @override
  Future<AcademicTranscript?> getOfficialTranscriptForLearner({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  }) async {
    _checkFailure();
    final candidates = _transcripts.values.where((t) {
      if (t.learnerId != learnerId) return false;
      if (t.cohortId != cohortId) return false;
      if (tenantId != null && t.tenantId != tenantId) return false;
      return t.status == TranscriptStatus.official;
    }).toList();

    if (candidates.isEmpty) return null;
    // Return highest version if multiple
    candidates.sort((a, b) => b.version.compareTo(a.version));
    return candidates.first;
  }

  @override
  Future<List<AcademicTranscript>> listTranscriptsForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    _checkFailure();
    final results = _transcripts.values.where((t) {
      if (t.learnerId != learnerId) return false;
      if (tenantId != null && t.tenantId != tenantId) return false;
      return true;
    }).toList();

    results.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return results;
  }

  @override
  Future<List<AcademicTranscript>> listTranscripts({
    String? cohortId,
    String? tenantId,
    TranscriptStatus? status,
  }) async {
    _checkFailure();
    final results = _transcripts.values.where((t) {
      if (cohortId != null && t.cohortId != cohortId) return false;
      if (tenantId != null && t.tenantId != tenantId) return false;
      if (status != null && t.status != status) return false;
      return true;
    }).toList();

    results.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return results;
  }

  // ---------------------------------------------------------------------------
  // Certificates
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveCertificate(CompletionCertificate certificate) async {
    _checkFailure();
    _certificates[certificate.certificateId] = certificate;
  }

  @override
  Future<CompletionCertificate?> getCertificate(String certificateId) async {
    _checkFailure();
    return _certificates[certificateId];
  }

  @override
  Future<CompletionCertificate?> getCertificateByCredentialId(
      String credentialId) async {
    _checkFailure();
    final cleanId = credentialId.trim();
    for (final cert in _certificates.values) {
      if (cert.credentialId == cleanId) {
        return cert;
      }
    }
    return null;
  }

  @override
  Future<CompletionCertificate?> getCertificateForLearnerCohort({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  }) async {
    _checkFailure();
    for (final cert in _certificates.values) {
      if (cert.learnerId == learnerId && cert.cohortId == cohortId) {
        if (tenantId != null && cert.tenantId != tenantId) continue;
        return cert;
      }
    }
    return null;
  }

  @override
  Future<List<CompletionCertificate>> listCertificatesForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    _checkFailure();
    final results = _certificates.values.where((c) {
      if (c.learnerId != learnerId) return false;
      if (tenantId != null && c.tenantId != tenantId) return false;
      return true;
    }).toList();

    results.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return results;
  }

  @override
  Future<List<CompletionCertificate>> listCertificates({
    String? cohortId,
    String? tenantId,
    CertificateStatus? status,
  }) async {
    _checkFailure();
    final results = _certificates.values.where((c) {
      if (cohortId != null && c.cohortId != cohortId) return false;
      if (tenantId != null && c.tenantId != tenantId) return false;
      if (status != null && c.status != status) return false;
      return true;
    }).toList();

    results.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return results;
  }

  // ---------------------------------------------------------------------------
  // Audit Logs
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditRecord(CredentialAuditRecord record) async {
    _checkFailure();
    _auditRecords.add(record);
  }

  @override
  Future<List<CredentialAuditRecord>> listAuditRecords({
    String? learnerId,
    String? targetId,
  }) async {
    _checkFailure();
    final results = _auditRecords.where((r) {
      if (learnerId != null && r.learnerId != learnerId) return false;
      if (targetId != null && r.targetId != targetId) return false;
      return true;
    }).toList();

    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  // ---------------------------------------------------------------------------
  // Persistence & Snapshots
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'transcripts':
          _transcripts.values.map((t) => t.toJson()).toList(growable: false),
      'certificates':
          _certificates.values.map((c) => c.toJson()).toList(growable: false),
      'auditRecords':
          _auditRecords.map((a) => a.toJson()).toList(growable: false),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _transcripts.clear();
    _certificates.clear();
    _auditRecords.clear();

    final transcriptsRaw = snapshot['transcripts'] as List<dynamic>? ?? [];
    for (final raw in transcriptsRaw) {
      final t = AcademicTranscript.fromJson(raw as Map<String, dynamic>);
      _transcripts[t.transcriptId] = t;
    }

    final certificatesRaw = snapshot['certificates'] as List<dynamic>? ?? [];
    for (final raw in certificatesRaw) {
      final c = CompletionCertificate.fromJson(raw as Map<String, dynamic>);
      _certificates[c.certificateId] = c;
    }

    final auditRaw = snapshot['auditRecords'] as List<dynamic>? ?? [];
    for (final raw in auditRaw) {
      final a = CredentialAuditRecord.fromJson(raw as Map<String, dynamic>);
      _auditRecords.add(a);
    }
  }

  @override
  Future<void> clear() async {
    _transcripts.clear();
    _certificates.clear();
    _auditRecords.clear();
  }
}
