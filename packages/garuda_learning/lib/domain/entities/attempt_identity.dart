/// Attempt Identity Domain Entity (TITAN-KO-040.0 P40).
///
/// Deterministic immutable attempt identifier preventing duplicate outcome
/// application across crashes and session resumptions.
library;

import 'package:meta/meta.dart';

import 'session_recovery_error.dart';

/// Immutable deterministic identifier for an attempt on a question within a session.
@immutable
class AttemptIdentity {
  /// Session identifier.
  final String sessionId;

  /// Question identifier.
  final String questionId;

  /// Strictly positive attempt sequence index (1, 2, ...).
  final int attemptSequence;

  AttemptIdentity({
    required String sessionId,
    required String questionId,
    this.attemptSequence = 1,
  })  : sessionId = sessionId.trim(),
        questionId = questionId.trim() {
    if (this.sessionId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'sessionId cannot be empty for AttemptIdentity',
      );
    }
    if (this.questionId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'questionId cannot be empty for AttemptIdentity',
      );
    }
    if (attemptSequence < 1) {
      throw ArgumentError(
          'attemptSequence must be >= 1 (got $attemptSequence)');
    }
  }

  /// Canonical token representation: "$sessionId:$questionId:$attemptSequence".
  String get token => '$sessionId:$questionId:$attemptSequence';

  /// Parses an AttemptIdentity from its canonical string token.
  factory AttemptIdentity.parse(String token) {
    final parts = token.split(':');
    if (parts.length < 3) {
      throw FormatException('Invalid attempt identity token format: "$token"');
    }
    final seq = int.tryParse(parts.last);
    if (seq == null || seq < 1) {
      throw FormatException('Invalid attempt sequence in token: "$token"');
    }
    final qId = parts[parts.length - 2];
    final sId = parts.sublist(0, parts.length - 2).join(':');

    return AttemptIdentity(
      sessionId: sId,
      questionId: qId,
      attemptSequence: seq,
    );
  }

  /// Parses an AttemptIdentity from its token representation.
  factory AttemptIdentity.fromToken(String token) =>
      AttemptIdentity.parse(token);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'questionId': questionId,
        'attemptSequence': attemptSequence,
        'token': token,
      };

  factory AttemptIdentity.fromJson(Map<String, dynamic> json) =>
      AttemptIdentity(
        sessionId: json['sessionId'] as String? ?? '',
        questionId: json['questionId'] as String? ?? '',
        attemptSequence: json['attemptSequence'] as int? ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptIdentity &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          questionId == other.questionId &&
          attemptSequence == other.attemptSequence;

  @override
  int get hashCode => Object.hash(sessionId, questionId, attemptSequence);

  @override
  String toString() => token;
}
