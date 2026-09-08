/// Sync Conflict Domain Entity (TITAN-KO-047.0 P47).
///
/// Captures typed divergence between local and remote AuthoritativeLearnerState
/// snapshots without obscuring conflicts behind generic exceptions.
library;

import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'persisted_authoritative_learner_state.dart';

/// Explicit reason why a sync conflict was triggered.
enum SyncConflictReason {
  /// Local state revision is less than or equal to current remote revision.
  staleRevision,

  /// Both local and remote states have diverged with independent session histories.
  divergentHistory,

  /// Concurrent updates occurred from different client devices at the same revision.
  concurrentEdits,
}

/// Typed representation of a state conflict between local and remote learner snapshots.
@immutable
class SyncConflict {
  /// Unique conflict record identifier.
  final String conflictId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Monotonic revision of the local candidate state.
  final int localRevision;

  /// Monotonic revision of the current remote state.
  final int remoteRevision;

  /// Cryptographic SHA-256 fingerprint of the local candidate state.
  final String localFingerprint;

  /// Cryptographic SHA-256 fingerprint of the remote state.
  final String remoteFingerprint;

  /// Complete local AuthoritativeLearnerState at conflict time.
  final AuthoritativeLearnerState localState;

  /// Complete remote AuthoritativeLearnerState at conflict time.
  final AuthoritativeLearnerState remoteState;

  /// Diagnosed cause of the conflict.
  final SyncConflictReason reason;

  /// UTC timestamp when the conflict was detected.
  final DateTime detectedAt;

  /// Resulting resolved state after applying deterministic resolution rules, if resolved.
  final AuthoritativeLearnerState? resolvedState;

  /// Description of the resolution strategy applied.
  final String? resolutionStrategy;

  SyncConflict({
    required String conflictId,
    required String learnerId,
    required String examId,
    required this.localRevision,
    required this.remoteRevision,
    required String localFingerprint,
    required String remoteFingerprint,
    required this.localState,
    required this.remoteState,
    required this.reason,
    DateTime? detectedAt,
    this.resolvedState,
    this.resolutionStrategy,
  })  : conflictId = conflictId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        localFingerprint = localFingerprint.trim(),
        remoteFingerprint = remoteFingerprint.trim(),
        detectedAt = detectedAt ?? DateTime.now().toUtc() {
    if (this.conflictId.isEmpty)
      throw ArgumentError('conflictId cannot be empty');
    if (this.learnerId.isEmpty)
      throw ArgumentError('learnerId cannot be empty');
    if (this.examId.isEmpty) throw ArgumentError('examId cannot be empty');
    if (this.localFingerprint.isEmpty)
      throw ArgumentError('localFingerprint cannot be empty');
    if (this.remoteFingerprint.isEmpty)
      throw ArgumentError('remoteFingerprint cannot be empty');
  }

  /// Whether this conflict has been resolved with a merged state.
  bool get isResolved => resolvedState != null;

  SyncConflict copyWith({
    String? conflictId,
    String? learnerId,
    String? examId,
    int? localRevision,
    int? remoteRevision,
    String? localFingerprint,
    String? remoteFingerprint,
    AuthoritativeLearnerState? localState,
    AuthoritativeLearnerState? remoteState,
    SyncConflictReason? reason,
    DateTime? detectedAt,
    AuthoritativeLearnerState? resolvedState,
    String? resolutionStrategy,
  }) {
    return SyncConflict(
      conflictId: conflictId ?? this.conflictId,
      learnerId: learnerId ?? this.learnerId,
      examId: examId ?? this.examId,
      localRevision: localRevision ?? this.localRevision,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      localFingerprint: localFingerprint ?? this.localFingerprint,
      remoteFingerprint: remoteFingerprint ?? this.remoteFingerprint,
      localState: localState ?? this.localState,
      remoteState: remoteState ?? this.remoteState,
      reason: reason ?? this.reason,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedState: resolvedState ?? this.resolvedState,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
    );
  }

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'learnerId': learnerId,
        'examId': examId,
        'localRevision': localRevision,
        'remoteRevision': remoteRevision,
        'localFingerprint': localFingerprint,
        'remoteFingerprint': remoteFingerprint,
        'localState': PersistedAuthoritativeLearnerState.fromAuthoritativeState(
                localState)
            .toJson(),
        'remoteState':
            PersistedAuthoritativeLearnerState.fromAuthoritativeState(
                    remoteState)
                .toJson(),
        'reason': reason.name,
        'detectedAt': detectedAt.toIso8601String(),
        'resolvedState': resolvedState != null
            ? PersistedAuthoritativeLearnerState.fromAuthoritativeState(
                    resolvedState!)
                .toJson()
            : null,
        'resolutionStrategy': resolutionStrategy,
      };

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      conflictId: json['conflictId'] as String,
      learnerId: json['learnerId'] as String,
      examId: json['examId'] as String,
      localRevision: json['localRevision'] as int,
      remoteRevision: json['remoteRevision'] as int,
      localFingerprint: json['localFingerprint'] as String,
      remoteFingerprint: json['remoteFingerprint'] as String,
      localState: PersistedAuthoritativeLearnerState.fromJson(
        Map<String, dynamic>.from(json['localState'] as Map),
      ).toAuthoritativeState(),
      remoteState: PersistedAuthoritativeLearnerState.fromJson(
        Map<String, dynamic>.from(json['remoteState'] as Map),
      ).toAuthoritativeState(),
      reason: SyncConflictReason.values.byName(json['reason'] as String),
      detectedAt: DateTime.parse(json['detectedAt'] as String).toUtc(),
      resolvedState: json['resolvedState'] != null
          ? PersistedAuthoritativeLearnerState.fromJson(
              Map<String, dynamic>.from(json['resolvedState'] as Map),
            ).toAuthoritativeState()
          : null,
      resolutionStrategy: json['resolutionStrategy'] as String?,
    );
  }
}
