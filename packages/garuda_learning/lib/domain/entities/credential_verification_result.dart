/// Credential Verification Domain Entities (TITAN-KO-051.0 P51).
///
/// Production domain models representing public and institutional credential
/// verification boundaries with minimal disclosure principles.
library;

import 'package:meta/meta.dart';

/// Exhaustive verification outcome status.
enum CredentialVerificationStatus {
  /// Valid credential whose canonical payload perfectly matches its SHA-256 fingerprint.
  valid,

  /// Invalid credential due to cryptographic fingerprint mismatch (tampering detected).
  invalid,

  /// Formally revoked credential by the issuing institution.
  revoked,

  /// Credential identifier was not found in authoritative records.
  notFound,
}

/// Verification outcome object returned by the verification boundary.
///
/// Discloses only minimal public information to external verifiers.
@immutable
class CredentialVerificationResult {
  /// Primary verification state.
  final CredentialVerificationStatus status;

  /// Query credential identifier.
  final String credentialId;

  /// Issuing institution name (omitted if not found).
  final String? institutionName;

  /// Certified program or curriculum name.
  final String? programName;

  /// UTC completion date.
  final DateTime? completionDate;

  /// UTC issuance date.
  final DateTime? issuedAt;

  /// Privacy-preserving learner display name (e.g. "Abhinav R.").
  final String? learnerDisplayName;

  /// UTC timestamp when verification was executed.
  final DateTime verificationTimestamp;

  /// Informational or error message.
  final String message;

  /// Whether the verification revealed tampering.
  final bool isTampered;

  CredentialVerificationResult({
    required this.status,
    required this.credentialId,
    this.institutionName,
    this.programName,
    this.completionDate,
    this.issuedAt,
    this.learnerDisplayName,
    DateTime? verificationTimestamp,
    required this.message,
    this.isTampered = false,
  }) : verificationTimestamp =
            (verificationTimestamp ?? DateTime.now()).toUtc();

  bool get isValid => status == CredentialVerificationStatus.valid;
  bool get isRevoked => status == CredentialVerificationStatus.revoked;
  bool get isNotFound => status == CredentialVerificationStatus.notFound;
  bool get isInvalid => status == CredentialVerificationStatus.invalid;

  /// Factory helper for not found outcome.
  factory CredentialVerificationResult.notFound(String credentialId) =>
      CredentialVerificationResult(
        status: CredentialVerificationStatus.notFound,
        credentialId: credentialId,
        message:
            'No institutional credential found for identifier $credentialId.',
      );

  /// Factory helper for revoked credential.
  factory CredentialVerificationResult.revoked({
    required String credentialId,
    String? institutionName,
    String? programName,
    DateTime? completionDate,
    DateTime? issuedAt,
    String? learnerDisplayName,
    String? reason,
  }) =>
      CredentialVerificationResult(
        status: CredentialVerificationStatus.revoked,
        credentialId: credentialId,
        institutionName: institutionName,
        programName: programName,
        completionDate: completionDate,
        issuedAt: issuedAt,
        learnerDisplayName: learnerDisplayName,
        message:
            'This credential has been formally revoked by $institutionName.${reason != null ? " Reason: $reason" : ""}',
      );

  /// Factory helper for invalid / tampered credential.
  factory CredentialVerificationResult.invalid({
    required String credentialId,
    String? institutionName,
    String? programName,
  }) =>
      CredentialVerificationResult(
        status: CredentialVerificationStatus.invalid,
        credentialId: credentialId,
        institutionName: institutionName,
        programName: programName,
        isTampered: true,
        message:
            'Cryptographic integrity failure: The presented credential data does not match the canonical fingerprint.',
      );

  /// Factory helper for authentic, valid credential.
  factory CredentialVerificationResult.valid({
    required String credentialId,
    required String institutionName,
    required String programName,
    required DateTime completionDate,
    required DateTime issuedAt,
    required String learnerDisplayName,
  }) =>
      CredentialVerificationResult(
        status: CredentialVerificationStatus.valid,
        credentialId: credentialId,
        institutionName: institutionName,
        programName: programName,
        completionDate: completionDate,
        issuedAt: issuedAt,
        learnerDisplayName: learnerDisplayName,
        message:
            'Credential is authentic, verified, and officially in good standing.',
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'credentialId': credentialId,
        if (institutionName != null) 'institutionName': institutionName,
        if (programName != null) 'programName': programName,
        if (completionDate != null)
          'completionDate': completionDate!.toIso8601String(),
        if (issuedAt != null) 'issuedAt': issuedAt!.toIso8601String(),
        if (learnerDisplayName != null)
          'learnerDisplayName': learnerDisplayName,
        'verificationTimestamp': verificationTimestamp.toIso8601String(),
        'message': message,
        'isTampered': isTampered,
      };

  factory CredentialVerificationResult.fromJson(Map<String, dynamic> json) =>
      CredentialVerificationResult(
        status: CredentialVerificationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CredentialVerificationStatus.notFound,
        ),
        credentialId: json['credentialId'] as String? ?? '',
        institutionName: json['institutionName'] as String?,
        programName: json['programName'] as String?,
        completionDate: json['completionDate'] != null
            ? DateTime.parse(json['completionDate'] as String).toUtc()
            : null,
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'] as String).toUtc()
            : null,
        learnerDisplayName: json['learnerDisplayName'] as String?,
        verificationTimestamp: json['verificationTimestamp'] != null
            ? DateTime.parse(json['verificationTimestamp'] as String).toUtc()
            : null,
        message: json['message'] as String? ?? '',
        isTampered: json['isTampered'] as bool? ?? false,
      );
}
