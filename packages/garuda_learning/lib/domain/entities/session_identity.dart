/// Session Identity Domain Entity (TITAN-KO-040.0 P40).
///
/// Immutable identity aggregate model tracking session coordinates, lifecycle status,
/// and checkpoint timestamps for adaptive learning sessions.
library;

import 'package:meta/meta.dart';

import 'resumable_session_status.dart';
import 'session_recovery_error.dart';

/// Immutable identity aggregate representing an adaptive learning session.
@immutable
class SessionIdentity {
  /// Unique session identifier.
  final String sessionId;

  /// Target learner identifier.
  final String learnerId;

  /// Examination identifier (lowercase, trimmed).
  final String examId;

  /// UTC timestamp when session was initialized.
  final DateTime startedAt;

  /// UTC timestamp of the most recent session checkpoint.
  final DateTime lastCheckpointAt;

  /// Current lifecycle execution and recovery status.
  final ResumableSessionStatus status;

  SessionIdentity({
    required String sessionId,
    required String learnerId,
    required String examId,
    required DateTime startedAt,
    required DateTime lastCheckpointAt,
    this.status = ResumableSessionStatus.created,
  })  : sessionId = sessionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        startedAt = startedAt.toUtc(),
        lastCheckpointAt = lastCheckpointAt.toUtc() {
    if (this.sessionId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'sessionId cannot be empty for SessionIdentity',
      );
    }
    if (this.learnerId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.identityMismatch,
        message: 'learnerId cannot be empty for SessionIdentity',
      );
    }
    if (this.examId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.identityMismatch,
        message: 'examId cannot be empty for SessionIdentity',
      );
    }
  }

  /// Whether the session is in a terminal state (completed, abandoned, failed).
  bool get isTerminal => status.isTerminal;

  /// Whether the session is currently active and can receive attempts.
  bool get canAcceptInput => status.canAcceptInput;

  /// Creates a copy with modified properties.
  SessionIdentity copyWith({
    String? sessionId,
    String? learnerId,
    String? examId,
    DateTime? startedAt,
    DateTime? lastCheckpointAt,
    ResumableSessionStatus? status,
  }) {
    return SessionIdentity(
      sessionId: sessionId ?? this.sessionId,
      learnerId: learnerId ?? this.learnerId,
      examId: examId ?? this.examId,
      startedAt: startedAt ?? this.startedAt,
      lastCheckpointAt: lastCheckpointAt ?? this.lastCheckpointAt,
      status: status ?? this.status,
    );
  }

  /// Serializes identity to JSON map.
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'examId': examId,
        'startedAt': startedAt.toIso8601String(),
        'lastCheckpointAt': lastCheckpointAt.toIso8601String(),
        'status': status.name,
      };

  /// Deserializes identity from JSON map.
  factory SessionIdentity.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'created';
    final status = ResumableSessionStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ResumableSessionStatus.created,
    );

    return SessionIdentity(
      sessionId: json['sessionId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastCheckpointAt: DateTime.parse(json['lastCheckpointAt'] as String),
      status: status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionIdentity &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          startedAt == other.startedAt &&
          lastCheckpointAt == other.lastCheckpointAt &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        examId,
        startedAt,
        lastCheckpointAt,
        status,
      );

  @override
  String toString() =>
      'SessionIdentity($sessionId [$learnerId:$examId] status: ${status.name})';
}
