/// Authoritative Application Result (TITAN-KO-039.0 P39).
///
/// Immutable domain model representing the structured, verifiable outcome of
/// applying a [ReconciledLearningStateProposal] to P19 authoritative persistence.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'authoritative_application_decision.dart';
import 'authoritative_application_error.dart';
import 'authoritative_learner_state.dart';
import 'reconciliation_decision.dart';

@immutable
class AuthoritativeApplicationResult {
  /// Deterministic operation identity.
  final String operationId;

  /// Categorical decision outcome of the application attempt.
  final AuthoritativeApplicationDecision decision;

  /// Target learner identifier.
  final String learnerId;

  /// Target exam identifier.
  final String examId;

  /// SHA-256 fingerprint of the source [ReconciledLearningStateProposal].
  final String proposalFingerprint;

  /// State fingerprint prior to application.
  final String previousStateFingerprint;

  /// State fingerprint following application.
  final String resultingStateFingerprint;

  /// Count of progress records written or modified in authoritative persistence.
  final int appliedChangesCount;

  /// Whether this proposal was already applied (duplicate idempotency).
  final bool isDuplicate;

  /// Whether the operation succeeded (applied, alreadyApplied, or noOp).
  final bool isSuccess;

  /// Timestamp when application was performed.
  final DateTime appliedAt;

  /// Full provenance trail from P36 -> P37 -> P38 -> P39.
  final ReconciliationProvenance provenance;

  /// Authoritative learner state verified after write, if available.
  final AuthoritativeLearnerState? resultingState;

  /// Structured error payload if operation failed.
  final AuthoritativeApplicationError? error;

  /// Deterministic SHA-256 fingerprint of this application result.
  final String fingerprint;

  AuthoritativeApplicationResult({
    required this.operationId,
    required this.decision,
    required this.learnerId,
    required this.examId,
    required this.proposalFingerprint,
    required this.previousStateFingerprint,
    required this.resultingStateFingerprint,
    required this.appliedChangesCount,
    required this.isDuplicate,
    required this.isSuccess,
    required DateTime appliedAt,
    required this.provenance,
    this.resultingState,
    this.error,
    String? fingerprint,
  })  : appliedAt = appliedAt.toUtc(),
        fingerprint = fingerprint ??
            _computeFingerprint(
              operationId: operationId,
              decision: decision,
              learnerId: learnerId,
              examId: examId,
              proposalFingerprint: proposalFingerprint,
              previousStateFingerprint: previousStateFingerprint,
              resultingStateFingerprint: resultingStateFingerprint,
              appliedChangesCount: appliedChangesCount,
              isDuplicate: isDuplicate,
              isSuccess: isSuccess,
              appliedAt: appliedAt.toUtc(),
              provenance: provenance,
            ) {
    if (operationId.trim().isEmpty) {
      throw ArgumentError('operationId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (proposalFingerprint.trim().isEmpty) {
      throw ArgumentError('proposalFingerprint cannot be empty');
    }
    if (previousStateFingerprint.trim().isEmpty) {
      throw ArgumentError('previousStateFingerprint cannot be empty');
    }
    if (resultingStateFingerprint.trim().isEmpty) {
      throw ArgumentError('resultingStateFingerprint cannot be empty');
    }
  }

  static String _computeFingerprint({
    required String operationId,
    required AuthoritativeApplicationDecision decision,
    required String learnerId,
    required String examId,
    required String proposalFingerprint,
    required String previousStateFingerprint,
    required String resultingStateFingerprint,
    required int appliedChangesCount,
    required bool isDuplicate,
    required bool isSuccess,
    required DateTime appliedAt,
    required ReconciliationProvenance provenance,
  }) {
    final payload = {
      'operationId': operationId.trim(),
      'decision': decision.serialName,
      'learnerId': learnerId.trim(),
      'examId': examId.trim(),
      'proposalFingerprint': proposalFingerprint.trim(),
      'previousStateFingerprint': previousStateFingerprint.trim(),
      'resultingStateFingerprint': resultingStateFingerprint.trim(),
      'appliedChangesCount': appliedChangesCount,
      'isDuplicate': isDuplicate,
      'isSuccess': isSuccess,
      'appliedAt': appliedAt.toIso8601String(),
      'provenance': provenance.toJson(),
    };
    final canonicalJson = jsonEncode(payload);
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  /// Generates a deterministic, repeatable operation identity.
  static String computeOperationId({
    required String learnerId,
    required String examId,
    required String reconciliationId,
    required String proposalFingerprint,
    required String previousStateFingerprint,
  }) {
    final raw =
        '$learnerId|$examId|$reconciliationId|$proposalFingerprint|$previousStateFingerprint';
    final hash = sha256.convert(utf8.encode(raw)).toString();
    return 'op_${hash.substring(0, 24)}';
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'decision': decision.serialName,
        'learnerId': learnerId,
        'examId': examId,
        'proposalFingerprint': proposalFingerprint,
        'previousStateFingerprint': previousStateFingerprint,
        'resultingStateFingerprint': resultingStateFingerprint,
        'appliedChangesCount': appliedChangesCount,
        'isDuplicate': isDuplicate,
        'isSuccess': isSuccess,
        'appliedAt': appliedAt.toIso8601String(),
        'provenance': provenance.toJson(),
        if (resultingState != null) 'resultingState': resultingState!.toJson(),
        if (error != null) 'error': error!.toJson(),
        'fingerprint': fingerprint,
      };

  factory AuthoritativeApplicationResult.fromJson(Map<String, dynamic> json) {
    return AuthoritativeApplicationResult(
      operationId: json['operationId'] as String,
      decision: AuthoritativeApplicationDecision.fromString(
          json['decision'] as String),
      learnerId: json['learnerId'] as String,
      examId: json['examId'] as String,
      proposalFingerprint: json['proposalFingerprint'] as String,
      previousStateFingerprint: json['previousStateFingerprint'] as String,
      resultingStateFingerprint: json['resultingStateFingerprint'] as String,
      appliedChangesCount: (json['appliedChangesCount'] as num).toInt(),
      isDuplicate: json['isDuplicate'] as bool,
      isSuccess: json['isSuccess'] as bool,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      provenance: ReconciliationProvenance.fromJson(
          Map<String, dynamic>.from(json['provenance'] as Map)),
      resultingState: json['resultingState'] != null
          ? AuthoritativeLearnerState.fromJson(
              Map<String, dynamic>.from(json['resultingState'] as Map))
          : null,
      error: json['error'] != null
          ? AuthoritativeApplicationError.fromJson(
              Map<String, dynamic>.from(json['error'] as Map))
          : null,
      fingerprint: json['fingerprint'] as String?,
    );
  }

  @override
  String toString() =>
      'AuthoritativeApplicationResult(op: $operationId, decision: ${decision.serialName}, changes: $appliedChangesCount, success: $isSuccess)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthoritativeApplicationResult &&
          runtimeType == other.runtimeType &&
          operationId == other.operationId &&
          fingerprint == other.fingerprint;

  @override
  int get hashCode => Object.hash(operationId, fingerprint);
}
