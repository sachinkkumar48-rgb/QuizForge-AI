import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [CredentialRepository] (TITAN-KO P51 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/credentials`.
class HttpCredentialRepository implements CredentialRepository {
  final ApiClient _apiClient;
  final InMemoryCredentialRepository _local;

  HttpCredentialRepository({
    ApiClient? apiClient,
    InMemoryCredentialRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryCredentialRepository();

  // ---------------------------------------------------------------------------
  // Transcripts
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveTranscript(AcademicTranscript transcript) async {
    await _local.saveTranscript(transcript);
    try {
      await _apiClient.post('/api/v1/lms/credentials/transcripts', body: transcript.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveTranscript failed, cached locally: $e', tag: 'HttpCredentialRepo');
    }
  }

  @override
  Future<AcademicTranscript?> getTranscript(String transcriptId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/credentials/transcripts/${Uri.encodeComponent(transcriptId)}');
      if (res.isNotEmpty && (res['transcript'] != null || res['transcriptId'] != null)) {
        final tMap = (res['transcript'] is Map)
            ? Map<String, dynamic>.from(res['transcript'] as Map)
            : Map<String, dynamic>.from(res);
        final transcript = AcademicTranscript.fromJson(tMap);
        await _local.saveTranscript(transcript);
        return transcript;
      }
    } catch (e) {
      AppLogger.debug('Remote getTranscript fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.getTranscript(transcriptId);
  }

  @override
  Future<AcademicTranscript?> getOfficialTranscriptForLearner({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'learnerId=${Uri.encodeComponent(learnerId)}',
        'cohortId=${Uri.encodeComponent(cohortId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/credentials/transcripts/official?${params.join('&')}');
      if (res.isNotEmpty && (res['transcript'] != null || res['transcriptId'] != null)) {
        final tMap = (res['transcript'] is Map)
            ? Map<String, dynamic>.from(res['transcript'] as Map)
            : Map<String, dynamic>.from(res);
        final transcript = AcademicTranscript.fromJson(tMap);
        await _local.saveTranscript(transcript);
        return transcript;
      }
    } catch (e) {
      AppLogger.debug('Remote getOfficialTranscriptForLearner fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.getOfficialTranscriptForLearner(
      learnerId: learnerId,
      cohortId: cohortId,
      tenantId: tenantId,
    );
  }

  @override
  Future<List<AcademicTranscript>> listTranscriptsForLearner({
    required String learnerId,
    String? tenantId,
  }) {
    return listTranscripts(learnerId: learnerId, tenantId: tenantId);
  }

  @override
  Future<List<AcademicTranscript>> listTranscripts({
    String? cohortId,
    String? tenantId,
    String? learnerId,
    TranscriptStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/credentials/transcripts$query');
      final dynamic listData = res['transcripts'] ?? res['data'];
      if (listData is List) {
        final transcripts = listData
            .map((t) => AcademicTranscript.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList();
        for (final t in transcripts) {
          await _local.saveTranscript(t);
        }
        return transcripts;
      }
    } catch (e) {
      AppLogger.debug('Remote listTranscripts fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.listTranscripts(cohortId: cohortId, tenantId: tenantId, status: status);
  }

  // ---------------------------------------------------------------------------
  // Certificates
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveCertificate(CompletionCertificate certificate) async {
    await _local.saveCertificate(certificate);
    try {
      await _apiClient.post('/api/v1/lms/credentials/certificates', body: certificate.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveCertificate failed: $e', tag: 'HttpCredentialRepo');
    }
  }

  @override
  Future<CompletionCertificate?> getCertificate(String certificateId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/credentials/certificates/${Uri.encodeComponent(certificateId)}');
      if (res.isNotEmpty && (res['certificate'] != null || res['certificateId'] != null)) {
        final cMap = (res['certificate'] is Map)
            ? Map<String, dynamic>.from(res['certificate'] as Map)
            : Map<String, dynamic>.from(res);
        final certificate = CompletionCertificate.fromJson(cMap);
        await _local.saveCertificate(certificate);
        return certificate;
      }
    } catch (e) {
      AppLogger.debug('Remote getCertificate fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.getCertificate(certificateId);
  }

  @override
  Future<CompletionCertificate?> getCertificateByCredentialId(String credentialId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/credentials/certificates/by-credential/${Uri.encodeComponent(credentialId)}');
      if (res.isNotEmpty && (res['certificate'] != null || res['certificateId'] != null)) {
        final cMap = (res['certificate'] is Map)
            ? Map<String, dynamic>.from(res['certificate'] as Map)
            : Map<String, dynamic>.from(res);
        final certificate = CompletionCertificate.fromJson(cMap);
        await _local.saveCertificate(certificate);
        return certificate;
      }
    } catch (e) {
      AppLogger.debug('Remote getCertificateByCredentialId fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.getCertificateByCredentialId(credentialId);
  }

  @override
  Future<CompletionCertificate?> getCertificateForLearnerCohort({
    required String learnerId,
    required String cohortId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'learnerId=${Uri.encodeComponent(learnerId)}',
        'cohortId=${Uri.encodeComponent(cohortId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/credentials/certificates/by-learner-cohort?${params.join('&')}');
      if (res.isNotEmpty && (res['certificate'] != null || res['certificateId'] != null)) {
        final cMap = (res['certificate'] is Map)
            ? Map<String, dynamic>.from(res['certificate'] as Map)
            : Map<String, dynamic>.from(res);
        final certificate = CompletionCertificate.fromJson(cMap);
        await _local.saveCertificate(certificate);
        return certificate;
      }
    } catch (e) {
      AppLogger.debug('Remote getCertificateForLearnerCohort fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.getCertificateForLearnerCohort(
      learnerId: learnerId,
      cohortId: cohortId,
      tenantId: tenantId,
    );
  }

  @override
  Future<List<CompletionCertificate>> listCertificatesForLearner({
    required String learnerId,
    String? tenantId,
  }) {
    return listCertificates(learnerId: learnerId, tenantId: tenantId);
  }

  @override
  Future<List<CompletionCertificate>> listCertificates({
    String? cohortId,
    String? tenantId,
    String? learnerId,
    CertificateStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/credentials/certificates$query');
      final dynamic listData = res['certificates'] ?? res['data'];
      if (listData is List) {
        final certs = listData
            .map((c) => CompletionCertificate.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
        for (final c in certs) {
          await _local.saveCertificate(c);
        }
        return certs;
      }
    } catch (e) {
      AppLogger.debug('Remote listCertificates fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.listCertificates(cohortId: cohortId, tenantId: tenantId, status: status);
  }

  // ---------------------------------------------------------------------------
  // Audit Logs
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditRecord(CredentialAuditRecord record) async {
    await _local.saveAuditRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/credentials/audit', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAuditRecord failed: $e', tag: 'HttpCredentialRepo');
    }
  }

  @override
  Future<List<CredentialAuditRecord>> listAuditRecords({
    String? learnerId,
    String? targetId,
  }) async {
    try {
      final params = <String>[];
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (targetId != null) params.add('targetId=${Uri.encodeComponent(targetId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/credentials/audit$query');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => CredentialAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecords fallback to local: $e', tag: 'HttpCredentialRepo');
    }
    return _local.listAuditRecords(learnerId: learnerId, targetId: targetId);
  }

  // ---------------------------------------------------------------------------
  // Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() => _local.exportSnapshot();

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) => _local.importSnapshot(snapshot);

  @override
  Future<void> clear() => _local.clear();
}
