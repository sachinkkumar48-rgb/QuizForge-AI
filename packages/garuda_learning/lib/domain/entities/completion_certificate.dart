/// Completion Certificate & Eligibility Domain Entities (TITAN-KO-051.0 P51).
///
/// Production domain models representing course/program completion eligibility,
/// official certificate issuance, tamper-evident SHA-256 credential fingerprinting,
/// and revocation lifecycles.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Minimal formal lifecycle states for a completion certificate.
enum CertificateStatus {
  /// Learner meets all criteria, ready for formal issuance.
  eligible,

  /// Officially issued, active, and valid.
  issued,

  /// Formally revoked by an authorized institutional authority.
  revoked,
}

/// Evaluated completion eligibility determination for a learner in a cohort/program.
@immutable
class CompletionEligibility {
  /// Whether the learner has fulfilled all authoritative completion requirements.
  final bool isEligible;

  /// Target learner identifier.
  final String learnerId;

  /// Target cohort identifier.
  final String cohortId;

  /// Total required assessments defined for the cohort.
  final int totalRequiredAssessments;

  /// Total assessments attempted and evaluated.
  final int completedAssessments;

  /// Total assessments whose grades have been published.
  final int publishedAssessments;

  /// Authoritative aggregated percentage across published assessments.
  final double overallPercentage;

  /// Explicit list of missing requirements or failure justifications if ineligible.
  final List<String> unmetCriteria;

  const CompletionEligibility({
    required this.isEligible,
    required this.learnerId,
    required this.cohortId,
    required this.totalRequiredAssessments,
    required this.completedAssessments,
    required this.publishedAssessments,
    required this.overallPercentage,
    this.unmetCriteria = const [],
  });

  Map<String, dynamic> toJson() => {
        'isEligible': isEligible,
        'learnerId': learnerId,
        'cohortId': cohortId,
        'totalRequiredAssessments': totalRequiredAssessments,
        'completedAssessments': completedAssessments,
        'publishedAssessments': publishedAssessments,
        'overallPercentage': overallPercentage,
        'unmetCriteria': unmetCriteria,
      };

  factory CompletionEligibility.fromJson(Map<String, dynamic> json) =>
      CompletionEligibility(
        isEligible: json['isEligible'] as bool? ?? false,
        learnerId: json['learnerId'] as String? ?? '',
        cohortId: json['cohortId'] as String? ?? '',
        totalRequiredAssessments:
            (json['totalRequiredAssessments'] as num?)?.toInt() ?? 0,
        completedAssessments:
            (json['completedAssessments'] as num?)?.toInt() ?? 0,
        publishedAssessments:
            (json['publishedAssessments'] as num?)?.toInt() ?? 0,
        overallPercentage:
            (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
        unmetCriteria: (json['unmetCriteria'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Authoritative Course / Program Completion Certificate.
///
/// Features a canonical tamper-evident SHA-256 fingerprint.
/// NOTE: A cryptographic hash provides tamper-evidence of the canonical record;
/// it does NOT constitute an asymmetric PKI digital signature without an institutional private key.
@immutable
class CompletionCertificate {
  /// Internal unique certificate identifier (e.g. 'cert_cohort1_learner1').
  final String certificateId;

  /// Externally verifiable credential identifier (e.g. 'QFA-CERT-COHORT1-LEARNER1-ABC123').
  final String credentialId;

  /// Enrolled learner identifier.
  final String learnerId;

  /// Optional display name of the learner.
  final String? learnerName;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Issuing institution name.
  final String institutionName;

  /// Certified program or curriculum title.
  final String programName;

  /// Associated cohort identifier.
  final String cohortId;

  /// UTC date on which completion criteria were fully satisfied.
  final DateTime completionDate;

  /// UTC timestamp when this certificate was officially issued.
  final DateTime issuedAt;

  /// Authorized faculty/administrator actor identifier.
  final String issuedByFacultyId;

  /// Current formal certificate lifecycle status.
  final CertificateStatus status;

  /// Mandatory administrative justification if certificate is revoked.
  final String? revocationReason;

  /// UTC revocation timestamp.
  final DateTime? revokedAt;

  /// Actor who revoked the certificate.
  final String? revokedByFacultyId;

  /// Deterministic SHA-256 hash of canonical credential fields.
  final String fingerprint;

  /// Algorithm used for the fingerprint.
  final String signatureAlgorithm;

  /// Explicit indicator that this is a tamper-evident checksum, not an asymmetric PKI signature.
  final bool isDigitalSignature;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  CompletionCertificate({
    required this.certificateId,
    required this.credentialId,
    required this.learnerId,
    this.learnerName,
    this.tenantId = 'default_tenant',
    this.institutionName = 'QuizForge Institute of Technology',
    required this.programName,
    required this.cohortId,
    DateTime? completionDate,
    DateTime? issuedAt,
    required this.issuedByFacultyId,
    this.status = CertificateStatus.issued,
    this.revocationReason,
    this.revokedAt,
    this.revokedByFacultyId,
    String? fingerprint,
    this.signatureAlgorithm = 'SHA-256',
    this.isDigitalSignature = false,
    Map<String, dynamic>? metadata,
  })  : completionDate = (completionDate ?? DateTime.now()).toUtc(),
        issuedAt = (issuedAt ?? DateTime.now()).toUtc(),
        fingerprint = fingerprint ??
            computeFingerprint(
              credentialId: credentialId,
              learnerId: learnerId,
              institutionName: institutionName,
              programName: programName,
              cohortId: cohortId,
              completionDate: (completionDate ?? DateTime.now()).toUtc(),
              issuedAt: (issuedAt ?? DateTime.now()).toUtc(),
              issuedByFacultyId: issuedByFacultyId,
              tenantId: tenantId,
            ),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (certificateId.trim().isEmpty) {
      throw ArgumentError('certificateId cannot be empty');
    }
    if (credentialId.trim().isEmpty) {
      throw ArgumentError('credentialId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (programName.trim().isEmpty) {
      throw ArgumentError('programName cannot be empty');
    }
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (issuedByFacultyId.trim().isEmpty) {
      throw ArgumentError('issuedByFacultyId cannot be empty');
    }
  }

  bool get isIssued => status == CertificateStatus.issued;
  bool get isRevoked => status == CertificateStatus.revoked;

  /// Computes the canonical SHA-256 fingerprint for the certificate payload.
  static String computeFingerprint({
    required String credentialId,
    required String learnerId,
    required String institutionName,
    required String programName,
    required String cohortId,
    required DateTime completionDate,
    required DateTime issuedAt,
    required String issuedByFacultyId,
    required String tenantId,
  }) {
    // Canonical format: v1|cid:...|lid:...|inst:...|prog:...|coh:...|comp:...|iss:...|fac:...|ten:...
    final canonicalPayload = 'v1|cid:${credentialId.trim()}'
        '|lid:${learnerId.trim()}'
        '|inst:${institutionName.trim()}'
        '|prog:${programName.trim()}'
        '|coh:${cohortId.trim()}'
        '|comp:${completionDate.toUtc().toIso8601String()}'
        '|iss:${issuedAt.toUtc().toIso8601String()}'
        '|fac:${issuedByFacultyId.trim()}'
        '|ten:${tenantId.trim()}';

    final bytes = utf8.encode(canonicalPayload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies whether the certificate's payload matches its cryptographic fingerprint.
  bool verifyIntegrity() {
    final expected = computeFingerprint(
      credentialId: credentialId,
      learnerId: learnerId,
      institutionName: institutionName,
      programName: programName,
      cohortId: cohortId,
      completionDate: completionDate,
      issuedAt: issuedAt,
      issuedByFacultyId: issuedByFacultyId,
      tenantId: tenantId,
    );
    return expected == fingerprint;
  }

  /// Returns a revoked copy of this certificate.
  CompletionCertificate revoke({
    required String facultyId,
    required String reason,
    DateTime? revokedAt,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Revocation reason cannot be empty');
    }
    return copyWith(
      status: CertificateStatus.revoked,
      revocationReason: cleanReason,
      revokedByFacultyId: facultyId.trim(),
      revokedAt: (revokedAt ?? DateTime.now()).toUtc(),
    );
  }

  CompletionCertificate copyWith({
    String? certificateId,
    String? credentialId,
    String? learnerId,
    String? learnerName,
    String? tenantId,
    String? institutionName,
    String? programName,
    String? cohortId,
    DateTime? completionDate,
    DateTime? issuedAt,
    String? issuedByFacultyId,
    CertificateStatus? status,
    String? revocationReason,
    DateTime? revokedAt,
    String? revokedByFacultyId,
    String? fingerprint,
    String? signatureAlgorithm,
    bool? isDigitalSignature,
    Map<String, dynamic>? metadata,
  }) {
    return CompletionCertificate(
      certificateId: certificateId ?? this.certificateId,
      credentialId: credentialId ?? this.credentialId,
      learnerId: learnerId ?? this.learnerId,
      learnerName: learnerName ?? this.learnerName,
      tenantId: tenantId ?? this.tenantId,
      institutionName: institutionName ?? this.institutionName,
      programName: programName ?? this.programName,
      cohortId: cohortId ?? this.cohortId,
      completionDate: completionDate ?? this.completionDate,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedByFacultyId: issuedByFacultyId ?? this.issuedByFacultyId,
      status: status ?? this.status,
      revocationReason: revocationReason ?? this.revocationReason,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedByFacultyId: revokedByFacultyId ?? this.revokedByFacultyId,
      fingerprint: fingerprint ?? this.fingerprint,
      signatureAlgorithm: signatureAlgorithm ?? this.signatureAlgorithm,
      isDigitalSignature: isDigitalSignature ?? this.isDigitalSignature,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'credentialId': credentialId,
        'learnerId': learnerId,
        if (learnerName != null) 'learnerName': learnerName,
        'tenantId': tenantId,
        'institutionName': institutionName,
        'programName': programName,
        'cohortId': cohortId,
        'completionDate': completionDate.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
        'issuedByFacultyId': issuedByFacultyId,
        'status': status.name,
        if (revocationReason != null) 'revocationReason': revocationReason,
        if (revokedAt != null) 'revokedAt': revokedAt!.toIso8601String(),
        if (revokedByFacultyId != null)
          'revokedByFacultyId': revokedByFacultyId,
        'fingerprint': fingerprint,
        'signatureAlgorithm': signatureAlgorithm,
        'isDigitalSignature': isDigitalSignature,
        'metadata': metadata,
      };

  factory CompletionCertificate.fromJson(Map<String, dynamic> json) =>
      CompletionCertificate(
        certificateId: json['certificateId'] as String? ?? '',
        credentialId: json['credentialId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        learnerName: json['learnerName'] as String?,
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        institutionName: json['institutionName'] as String? ??
            'QuizForge Institute of Technology',
        programName: json['programName'] as String? ?? '',
        cohortId: json['cohortId'] as String? ?? '',
        completionDate: json['completionDate'] != null
            ? DateTime.parse(json['completionDate'] as String).toUtc()
            : null,
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'] as String).toUtc()
            : null,
        issuedByFacultyId: json['issuedByFacultyId'] as String? ?? '',
        status: CertificateStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CertificateStatus.issued,
        ),
        revocationReason: json['revocationReason'] as String?,
        revokedAt: json['revokedAt'] != null
            ? DateTime.parse(json['revokedAt'] as String).toUtc()
            : null,
        revokedByFacultyId: json['revokedByFacultyId'] as String?,
        fingerprint: json['fingerprint'] as String?,
        signatureAlgorithm: json['signatureAlgorithm'] as String? ?? 'SHA-256',
        isDigitalSignature: json['isDigitalSignature'] as bool? ?? false,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );
}
