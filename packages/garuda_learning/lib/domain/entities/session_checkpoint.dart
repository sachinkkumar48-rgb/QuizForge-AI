/// Session Checkpoint Domain Entity (TITAN-KO-040.0 P40).
///
/// Encapsulates an immutable, crash-safe checkpoint snapshot for an active or
/// completed adaptive learning session, capturing minimal cursor and revision
/// coordinates without duplicating authoritative learner state.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'session_recovery_error.dart';

/// Immutable checkpoint capturing the minimal required state to resume an adaptive session.
@immutable
class SessionCheckpoint {
  /// Current supported schema version for session checkpoints.
  static const int currentSchemaVersion = 1;

  /// Schema version of this checkpoint payload.
  final int schemaVersion;

  /// Strictly positive monotonic checkpoint sequence revision (>= 1).
  final int checkpointRevision;

  /// Revision of the associated AuthoritativeLearnerState at this checkpoint (>= 1).
  final int authoritativeStateRevision;

  /// Identifier of the target learning session.
  final String sessionId;

  /// Normalized target learner identifier.
  final String learnerId;

  /// Normalized target examination identifier (lowercase, trimmed).
  final String examId;

  /// 0-based question sequence index representing the next question cursor (>= 0).
  final int questionIndex;

  /// Deterministically ordered list of question IDs that have been completed.
  final List<String> completedQuestionIds;

  /// Identifier of the currently active learning objective.
  final String activeObjectiveId;

  /// UTC timestamp when this checkpoint was generated.
  final DateTime timestamp;

  /// Whether the session reached a terminal completion state at this checkpoint.
  final bool isCompleted;

  /// SHA-256 cryptographic checksum over the canonical serialization for bitrot/tampering protection.
  final String checksum;

  /// Optional extensible audit and recovery metadata.
  final Map<String, dynamic> metadata;

  SessionCheckpoint({
    this.schemaVersion = currentSchemaVersion,
    required this.checkpointRevision,
    required this.authoritativeStateRevision,
    required String sessionId,
    required String learnerId,
    required String examId,
    required this.questionIndex,
    required List<String> completedQuestionIds,
    required String activeObjectiveId,
    required DateTime timestamp,
    this.isCompleted = false,
    String? checksum,
    Map<String, dynamic>? metadata,
  })  : sessionId = sessionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        activeObjectiveId = activeObjectiveId.trim(),
        timestamp = timestamp.toUtc(),
        completedQuestionIds = List<String>.unmodifiable(
          List<String>.from(completedQuestionIds),
        ),
        metadata = metadata == null
            ? const {}
            : Map<String, dynamic>.unmodifiable(
                SplayTreeMap<String, dynamic>.from(metadata),
              ),
        checksum = checksum ??
            _computeChecksum(
              schemaVersion: schemaVersion,
              checkpointRevision: checkpointRevision,
              authoritativeStateRevision: authoritativeStateRevision,
              sessionId: sessionId.trim(),
              learnerId: learnerId.trim(),
              examId: examId.trim().toLowerCase(),
              questionIndex: questionIndex,
              completedQuestionIds: completedQuestionIds,
              activeObjectiveId: activeObjectiveId.trim(),
              timestamp: timestamp.toUtc(),
              isCompleted: isCompleted,
              metadata: metadata ?? const {},
            ) {
    if (this.sessionId.isEmpty) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'sessionId cannot be empty in SessionCheckpoint',
      );
    }
    if (this.learnerId.isEmpty) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'learnerId cannot be empty in SessionCheckpoint',
      );
    }
    if (this.examId.isEmpty) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'examId cannot be empty in SessionCheckpoint',
      );
    }
    if (this.activeObjectiveId.isEmpty) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'activeObjectiveId cannot be empty in SessionCheckpoint',
      );
    }
    if (checkpointRevision < 1) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message:
            'checkpointRevision must be >= 1, received: $checkpointRevision',
      );
    }
    if (authoritativeStateRevision < 1) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message:
            'authoritativeStateRevision must be >= 1, received: $authoritativeStateRevision',
      );
    }
    if (questionIndex < 0) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'questionIndex cannot be negative, received: $questionIndex',
      );
    }
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.incompatibleVersion,
        message:
            'Unsupported checkpoint schema version: $schemaVersion (supported: 1..$currentSchemaVersion)',
      );
    }
    if (this.checksum.trim().isEmpty) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'checksum cannot be empty in SessionCheckpoint',
      );
    }
  }

  /// Total count of completed questions captured at this checkpoint.
  int get completedCount => completedQuestionIds.length;

  /// Creates a copy of this checkpoint advancing cursor and revisions.
  SessionCheckpoint copyWith({
    int? checkpointRevision,
    int? authoritativeStateRevision,
    int? questionIndex,
    List<String>? completedQuestionIds,
    String? activeObjectiveId,
    DateTime? timestamp,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) {
    return SessionCheckpoint(
      schemaVersion: schemaVersion,
      checkpointRevision: checkpointRevision ?? this.checkpointRevision,
      authoritativeStateRevision:
          authoritativeStateRevision ?? this.authoritativeStateRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: questionIndex ?? this.questionIndex,
      completedQuestionIds: completedQuestionIds ?? this.completedQuestionIds,
      activeObjectiveId: activeObjectiveId ?? this.activeObjectiveId,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this checkpoint to a canonical JSON map with lexicographically sorted keys.
  Map<String, dynamic> toCanonicalJsonMap() {
    final map = SplayTreeMap<String, dynamic>();
    map['activeObjectiveId'] = activeObjectiveId;
    map['authoritativeStateRevision'] = authoritativeStateRevision;
    map['checkpointRevision'] = checkpointRevision;
    map['checksum'] = checksum;
    map['completedQuestionIds'] = List<String>.from(completedQuestionIds);
    map['examId'] = examId;
    map['isCompleted'] = isCompleted;
    map['learnerId'] = learnerId;
    map['metadata'] = SplayTreeMap<String, dynamic>.from(metadata);
    map['questionIndex'] = questionIndex;
    map['schemaVersion'] = schemaVersion;
    map['sessionId'] = sessionId;
    map['timestamp'] = timestamp.toIso8601String();
    return map;
  }

  /// Serializes to a deterministic canonical JSON string.
  String toCanonicalJson() => jsonEncode(toCanonicalJsonMap());

  /// Standard JSON map serialization.
  Map<String, dynamic> toJson() => toCanonicalJsonMap();

  /// Deserializes from JSON map with strict integrity and checksum verification.
  factory SessionCheckpoint.fromJson(Map<String, dynamic> json) {
    final schema = json['schemaVersion'] as int?;
    if (schema == null) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing required field: schemaVersion',
      );
    }
    if (schema > currentSchemaVersion) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.incompatibleVersion,
        message:
            'Unsupported checkpoint schema version $schema > current $currentSchemaVersion',
      );
    }

    final checkpointRev = json['checkpointRevision'] as int?;
    if (checkpointRev == null || checkpointRev < 1) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or invalid checkpointRevision (must be >= 1)',
      );
    }

    final authRev = json['authoritativeStateRevision'] as int?;
    if (authRev == null || authRev < 1) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or invalid authoritativeStateRevision (must be >= 1)',
      );
    }

    final sessId = json['sessionId'] as String?;
    if (sessId == null || sessId.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or empty sessionId',
      );
    }

    final lId = json['learnerId'] as String?;
    if (lId == null || lId.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or empty learnerId',
      );
    }

    final eId = json['examId'] as String?;
    if (eId == null || eId.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or empty examId',
      );
    }

    final qIdx = json['questionIndex'] as int?;
    if (qIdx == null || qIdx < 0) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or negative questionIndex',
      );
    }

    final completedList = json['completedQuestionIds'] as List<dynamic>?;
    if (completedList == null) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing completedQuestionIds',
      );
    }
    final completedIds = completedList.map((e) => e.toString()).toList();

    final activeObj = json['activeObjectiveId'] as String?;
    if (activeObj == null || activeObj.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing or empty activeObjectiveId',
      );
    }

    final tsRaw = json['timestamp'] as String?;
    if (tsRaw == null || tsRaw.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing timestamp',
      );
    }
    final parsedTs = DateTime.parse(tsRaw).toUtc();

    final isDone = json['isCompleted'] as bool? ?? false;
    final storedChecksum = json['checksum'] as String?;
    if (storedChecksum == null || storedChecksum.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Missing checksum in checkpoint payload',
      );
    }

    final rawMeta = json['metadata'] as Map<String, dynamic>? ?? const {};

    // Verify cryptographic checksum
    final computedChecksum = _computeChecksum(
      schemaVersion: schema,
      checkpointRevision: checkpointRev,
      authoritativeStateRevision: authRev,
      sessionId: sessId.trim(),
      learnerId: lId.trim(),
      examId: eId.trim().toLowerCase(),
      questionIndex: qIdx,
      completedQuestionIds: completedIds,
      activeObjectiveId: activeObj.trim(),
      timestamp: parsedTs,
      isCompleted: isDone,
      metadata: rawMeta,
    );

    if (computedChecksum != storedChecksum) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message:
            'Checkpoint checksum verification failed (data corruption detected). Expected: $computedChecksum, received: $storedChecksum',
        details: {
          'expectedChecksum': computedChecksum,
          'storedChecksum': storedChecksum,
          'sessionId': sessId,
        },
      );
    }

    return SessionCheckpoint(
      schemaVersion: schema,
      checkpointRevision: checkpointRev,
      authoritativeStateRevision: authRev,
      sessionId: sessId,
      learnerId: lId,
      examId: eId,
      questionIndex: qIdx,
      completedQuestionIds: completedIds,
      activeObjectiveId: activeObj,
      timestamp: parsedTs,
      isCompleted: isDone,
      checksum: storedChecksum,
      metadata: rawMeta,
    );
  }

  /// Deserializes from raw JSON string with strict validation.
  factory SessionCheckpoint.fromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw const SessionRecoveryException(
          code: SessionRecoveryErrorCode.corruptedCheckpoint,
          message: 'Decoded JSON is not a Map<String, dynamic>',
        );
      }
      return SessionCheckpoint.fromJson(decoded);
    } on SessionRecoveryException {
      rethrow;
    } catch (e) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'Failed to parse checkpoint JSON: $e',
      );
    }
  }

  /// Calculates SHA-256 checksum over canonical parameters.
  static String _computeChecksum({
    required int schemaVersion,
    required int checkpointRevision,
    required int authoritativeStateRevision,
    required String sessionId,
    required String learnerId,
    required String examId,
    required int questionIndex,
    required List<String> completedQuestionIds,
    required String activeObjectiveId,
    required DateTime timestamp,
    required bool isCompleted,
    required Map<String, dynamic> metadata,
  }) {
    final map = SplayTreeMap<String, dynamic>();
    map['activeObjectiveId'] = activeObjectiveId;
    map['authoritativeStateRevision'] = authoritativeStateRevision;
    map['checkpointRevision'] = checkpointRevision;
    map['completedQuestionIds'] = List<String>.from(completedQuestionIds);
    map['examId'] = examId;
    map['isCompleted'] = isCompleted;
    map['learnerId'] = learnerId;
    map['metadata'] = SplayTreeMap<String, dynamic>.from(metadata);
    map['questionIndex'] = questionIndex;
    map['schemaVersion'] = schemaVersion;
    map['sessionId'] = sessionId;
    map['timestamp'] = timestamp.toIso8601String();

    final canonicalString = jsonEncode(map);
    return sha256.convert(utf8.encode(canonicalString)).toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionCheckpoint &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          checkpointRevision == other.checkpointRevision &&
          authoritativeStateRevision == other.authoritativeStateRevision &&
          questionIndex == other.questionIndex &&
          isCompleted == other.isCompleted &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        examId,
        checkpointRevision,
        authoritativeStateRevision,
        questionIndex,
        isCompleted,
        checksum,
      );

  @override
  String toString() =>
      'SessionCheckpoint($sessionId [$learnerId:$examId] rev: $checkpointRevision, authRev: $authoritativeStateRevision, cursor: $questionIndex, completed: $isCompleted)';
}
