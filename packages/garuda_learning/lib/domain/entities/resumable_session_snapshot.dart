/// Resumable Session Snapshot Domain Entity (TITAN-KO-040.0 P40).
///
/// Durable, integrity-protected representation of an interrupted adaptive learning
/// session, preserving session coordinates, progression, question lineage, and attempt
/// deduplication tokens without duplicating authoritative learner state.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'resumable_session_status.dart';
import 'session_checkpoint.dart';
import 'session_checkpoint_exceptions.dart';
import 'session_identity.dart';
import 'session_recovery_error.dart';

/// Durable snapshot preserving the complete resumable state of an adaptive session.
@immutable
class ResumableSessionSnapshot {
  /// Current supported schema version for session snapshots.
  static const int currentSchemaVersion = 1;

  /// Schema version of this snapshot payload.
  final int schemaVersion;

  /// Explicit session identity coordinates.
  final SessionIdentity identity;

  /// 0-based question sequence index representing the active question cursor.
  final int currentQuestionIndex;

  /// Canonical question ID at the active cursor, or null if session is completed.
  final String? currentQuestionId;

  /// Deterministically ordered list of question IDs that have been completed.
  final List<String> completedQuestionIds;

  /// Set of deterministic attempt identity tokens processed in this session.
  final List<String> processedAttemptTokens;

  /// Accumulated practice score within this session.
  final double accumulatedScore;

  /// Count of correctly answered questions.
  final int correctCount;

  /// Identifier of the currently active learning objective.
  final String activeObjectiveId;

  /// Learning objective IDs completed during this session.
  final List<String> completedObjectiveIds;

  /// Learning objective IDs pending completion.
  final List<String> pendingObjectiveIds;

  /// Monotonically increasing checkpoint revision sequence number (>= 1).
  final int checkpointRevision;

  /// Associated AuthoritativeLearnerState revision at the time of this checkpoint (>= 1).
  final int authoritativeStateRevision;

  /// UTC timestamp when this snapshot was created.
  final DateTime timestamp;

  /// SHA-256 cryptographic checksum over the canonical payload for corruption protection.
  final String checksum;

  /// Optional extensible audit and diagnostic metadata.
  final Map<String, dynamic> metadata;

  ResumableSessionSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.identity,
    required this.currentQuestionIndex,
    this.currentQuestionId,
    required List<String> completedQuestionIds,
    required List<String> processedAttemptTokens,
    this.accumulatedScore = 0.0,
    this.correctCount = 0,
    required String activeObjectiveId,
    List<String>? completedObjectiveIds,
    List<String>? pendingObjectiveIds,
    required this.checkpointRevision,
    required this.authoritativeStateRevision,
    required DateTime timestamp,
    String? checksum,
    Map<String, dynamic>? metadata,
  })  : completedQuestionIds = List<String>.unmodifiable(
          List<String>.from(completedQuestionIds),
        ),
        processedAttemptTokens = List<String>.unmodifiable(
          List<String>.from(processedAttemptTokens),
        ),
        activeObjectiveId = activeObjectiveId.trim(),
        completedObjectiveIds = List<String>.unmodifiable(
          List<String>.from(completedObjectiveIds ?? const <String>[]),
        ),
        pendingObjectiveIds = List<String>.unmodifiable(
          List<String>.from(pendingObjectiveIds ?? const <String>[]),
        ),
        timestamp = timestamp.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}),
        checksum = checksum ??
            _computeChecksum(
              schemaVersion: schemaVersion,
              sessionId: identity.sessionId,
              learnerId: identity.learnerId,
              examId: identity.examId,
              status: identity.status.name,
              currentQuestionIndex: currentQuestionIndex,
              currentQuestionId: currentQuestionId,
              completedQuestionIds: completedQuestionIds,
              processedAttemptTokens: processedAttemptTokens,
              accumulatedScore: accumulatedScore,
              correctCount: correctCount,
              activeObjectiveId: activeObjectiveId.trim(),
              checkpointRevision: checkpointRevision,
              authoritativeStateRevision: authoritativeStateRevision,
              timestamp: timestamp.toUtc(),
            ) {
    if (checkpointRevision < 1) {
      throw ArgumentError(
          'checkpointRevision must be >= 1 (got $checkpointRevision)');
    }
    if (authoritativeStateRevision < 1) {
      throw ArgumentError(
          'authoritativeStateRevision must be >= 1 (got $authoritativeStateRevision)');
    }
    if (currentQuestionIndex < 0) {
      throw ArgumentError(
          'currentQuestionIndex cannot be negative ($currentQuestionIndex)');
    }
    if (this.checksum.trim().isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.corruptedCheckpoint,
        message: 'checksum cannot be empty in ResumableSessionSnapshot',
      );
    }
  }

  /// Session identifier shortcut.
  String get sessionId => identity.sessionId;

  /// Learner identifier shortcut.
  String get learnerId => identity.learnerId;

  /// Exam identifier shortcut.
  String get examId => identity.examId;

  /// Session status shortcut.
  ResumableSessionStatus get status => identity.status;

  /// Whether the session reached a completed terminal state.
  bool get isCompleted => status == ResumableSessionStatus.completed;

  /// Converts this snapshot into a standard [SessionCheckpoint].
  SessionCheckpoint toCheckpoint() {
    return SessionCheckpoint(
      schemaVersion: schemaVersion,
      checkpointRevision: checkpointRevision,
      authoritativeStateRevision: authoritativeStateRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: currentQuestionIndex,
      completedQuestionIds: completedQuestionIds,
      activeObjectiveId: activeObjectiveId,
      timestamp: timestamp,
      isCompleted: isCompleted,
      metadata: {
        ...metadata,
        'accumulatedScore': accumulatedScore,
        'correctCount': correctCount,
        'processedAttemptTokens': processedAttemptTokens,
        'completedObjectiveIds': completedObjectiveIds,
        'pendingObjectiveIds': pendingObjectiveIds,
      },
    );
  }

  /// Creates a copy of this snapshot with updated properties and automatically recalculates checksum.
  ResumableSessionSnapshot copyWith({
    int? schemaVersion,
    SessionIdentity? identity,
    int? currentQuestionIndex,
    String? currentQuestionId,
    List<String>? completedQuestionIds,
    List<String>? processedAttemptTokens,
    double? accumulatedScore,
    int? correctCount,
    String? activeObjectiveId,
    List<String>? completedObjectiveIds,
    List<String>? pendingObjectiveIds,
    int? checkpointRevision,
    int? authoritativeStateRevision,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ResumableSessionSnapshot(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      identity: identity ?? this.identity,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      completedQuestionIds: completedQuestionIds ?? this.completedQuestionIds,
      processedAttemptTokens:
          processedAttemptTokens ?? this.processedAttemptTokens,
      accumulatedScore: accumulatedScore ?? this.accumulatedScore,
      correctCount: correctCount ?? this.correctCount,
      activeObjectiveId: activeObjectiveId ?? this.activeObjectiveId,
      completedObjectiveIds:
          completedObjectiveIds ?? this.completedObjectiveIds,
      pendingObjectiveIds: pendingObjectiveIds ?? this.pendingObjectiveIds,
      checkpointRevision: checkpointRevision ?? this.checkpointRevision,
      authoritativeStateRevision:
          authoritativeStateRevision ?? this.authoritativeStateRevision,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a snapshot from an existing [SessionCheckpoint].
  factory ResumableSessionSnapshot.fromCheckpoint(
    SessionCheckpoint checkpoint, {
    SessionIdentity? identity,
  }) {
    final meta = checkpoint.metadata;
    final accumulatedScore =
        (meta['accumulatedScore'] as num?)?.toDouble() ?? 0.0;
    final correctCount = meta['correctCount'] as int? ?? 0;
    final processedAttemptTokens =
        (meta['processedAttemptTokens'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    final completedObjectiveIds =
        (meta['completedObjectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    final pendingObjectiveIds =
        (meta['pendingObjectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final statusStr = meta['status'] as String?;
    final status = statusStr != null
        ? ResumableSessionStatus.values.firstWhere(
            (s) => s.name == statusStr,
            orElse: () => checkpoint.isCompleted
                ? ResumableSessionStatus.completed
                : ResumableSessionStatus.active,
          )
        : (checkpoint.isCompleted
            ? ResumableSessionStatus.completed
            : ResumableSessionStatus.active);

    final resolvedIdentity = identity ??
        SessionIdentity(
          sessionId: checkpoint.sessionId,
          learnerId: checkpoint.learnerId,
          examId: checkpoint.examId,
          startedAt: meta['startedAt'] != null
              ? DateTime.parse(meta['startedAt'] as String).toUtc()
              : checkpoint.timestamp,
          lastCheckpointAt: checkpoint.timestamp,
          status: status,
        );

    return ResumableSessionSnapshot(
      schemaVersion: checkpoint.schemaVersion,
      identity: resolvedIdentity,
      currentQuestionIndex: checkpoint.questionIndex,
      currentQuestionId: meta['currentQuestionId'] as String?,
      completedQuestionIds: checkpoint.completedQuestionIds,
      processedAttemptTokens: processedAttemptTokens,
      accumulatedScore: accumulatedScore,
      correctCount: correctCount,
      activeObjectiveId: checkpoint.activeObjectiveId,
      completedObjectiveIds: completedObjectiveIds,
      pendingObjectiveIds: pendingObjectiveIds,
      checkpointRevision: checkpoint.checkpointRevision,
      authoritativeStateRevision: checkpoint.authoritativeStateRevision,
      timestamp: checkpoint.timestamp,
      metadata: Map<String, dynamic>.from(checkpoint.metadata),
    );
  }

  /// Verifies whether the cryptographic SHA-256 checksum matches snapshot content.
  bool verifyChecksum() {
    final expected = _computeChecksum(
      schemaVersion: schemaVersion,
      sessionId: identity.sessionId,
      learnerId: identity.learnerId,
      examId: identity.examId,
      status: identity.status.name,
      currentQuestionIndex: currentQuestionIndex,
      currentQuestionId: currentQuestionId,
      completedQuestionIds: completedQuestionIds,
      processedAttemptTokens: processedAttemptTokens,
      accumulatedScore: accumulatedScore,
      correctCount: correctCount,
      activeObjectiveId: activeObjectiveId,
      checkpointRevision: checkpointRevision,
      authoritativeStateRevision: authoritativeStateRevision,
      timestamp: timestamp,
    );
    return checksum == expected;
  }

  /// Serializes to canonical sorted JSON map.
  Map<String, dynamic> toJson() {
    final map = SplayTreeMap<String, dynamic>();
    map['accumulatedScore'] = accumulatedScore;
    map['activeObjectiveId'] = activeObjectiveId;
    map['authoritativeStateRevision'] = authoritativeStateRevision;
    map['checkpointRevision'] = checkpointRevision;
    map['checksum'] = checksum;
    map['completedObjectiveIds'] = completedObjectiveIds;
    map['completedQuestionIds'] = completedQuestionIds;
    map['correctCount'] = correctCount;
    map['currentQuestionId'] = currentQuestionId;
    map['currentQuestionIndex'] = currentQuestionIndex;
    map['identity'] = identity.toJson();
    map['metadata'] = metadata;
    map['pendingObjectiveIds'] = pendingObjectiveIds;
    map['processedAttemptTokens'] = processedAttemptTokens;
    map['schemaVersion'] = schemaVersion;
    map['timestamp'] = timestamp.toIso8601String();
    return map;
  }

  /// Serializes to canonical JSON string.
  String toCanonicalJson() => jsonEncode(toJson());

  /// Deserializes from raw JSON string with strict checksum and schema validation.
  factory ResumableSessionSnapshot.fromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw CheckpointIntegrityException(
          message: 'Raw JSON is not a valid JSON map',
        );
      }
      return ResumableSessionSnapshot.fromJson(decoded);
    } on SessionCheckpointException {
      rethrow;
    } catch (e) {
      throw CheckpointIntegrityException(
        message: 'Failed to decode JSON for snapshot: $e',
      );
    }
  }

  /// Deserializes from JSON map with cryptographic verification.
  factory ResumableSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final schema = json['schemaVersion'] as int? ?? 1;
    if (schema > currentSchemaVersion) {
      throw CheckpointSchemaException(
        message: 'Unsupported future schema version: $schema',
        schemaVersion: schema,
      );
    }

    final identityMap = json['identity'] as Map<String, dynamic>?;
    if (identityMap == null) {
      throw CheckpointIntegrityException(
          message: 'Missing identity in snapshot');
    }
    final identity = SessionIdentity.fromJson(identityMap);

    final storedChecksum = json['checksum'] as String?;
    if (storedChecksum == null || storedChecksum.trim().isEmpty) {
      throw CheckpointIntegrityException(
          message: 'Missing checksum in snapshot');
    }

    final completedList =
        (json['completedQuestionIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final attemptList =
        (json['processedAttemptTokens'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final snapshot = ResumableSessionSnapshot(
      schemaVersion: schema,
      identity: identity,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      currentQuestionId: json['currentQuestionId'] as String?,
      completedQuestionIds: completedList,
      processedAttemptTokens: attemptList,
      accumulatedScore: (json['accumulatedScore'] as num?)?.toDouble() ?? 0.0,
      correctCount: json['correctCount'] as int? ?? 0,
      activeObjectiveId: json['activeObjectiveId'] as String? ?? 'lo_general',
      completedObjectiveIds:
          (json['completedObjectiveIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      pendingObjectiveIds:
          (json['pendingObjectiveIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      checkpointRevision: json['checkpointRevision'] as int? ?? 1,
      authoritativeStateRevision:
          json['authoritativeStateRevision'] as int? ?? 1,
      timestamp: DateTime.parse(json['timestamp'] as String),
      checksum: storedChecksum,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

    if (!snapshot.verifyChecksum()) {
      throw CheckpointIntegrityException(
        message: 'Snapshot cryptographic checksum verification failed',
        foundChecksum: storedChecksum,
      );
    }

    return snapshot;
  }

  static String _computeChecksum({
    required int schemaVersion,
    required String sessionId,
    required String learnerId,
    required String examId,
    required String status,
    required int currentQuestionIndex,
    required String? currentQuestionId,
    required List<String> completedQuestionIds,
    required List<String> processedAttemptTokens,
    required double accumulatedScore,
    required int correctCount,
    required String activeObjectiveId,
    required int checkpointRevision,
    required int authoritativeStateRevision,
    required DateTime timestamp,
  }) {
    final payload = [
      schemaVersion,
      sessionId.trim(),
      learnerId.trim(),
      examId.trim().toLowerCase(),
      status,
      currentQuestionIndex,
      currentQuestionId ?? '',
      completedQuestionIds.join(','),
      processedAttemptTokens.join(','),
      accumulatedScore.toStringAsFixed(4),
      correctCount,
      activeObjectiveId.trim(),
      checkpointRevision,
      authoritativeStateRevision,
      timestamp.toUtc().toIso8601String(),
    ].join('|');

    return sha256.convert(utf8.encode(payload)).toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumableSessionSnapshot &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          identity == other.identity &&
          currentQuestionIndex == other.currentQuestionIndex &&
          currentQuestionId == other.currentQuestionId &&
          checkpointRevision == other.checkpointRevision &&
          authoritativeStateRevision == other.authoritativeStateRevision &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        identity,
        currentQuestionIndex,
        currentQuestionId,
        checkpointRevision,
        authoritativeStateRevision,
        checksum,
      );

  @override
  String toString() =>
      'ResumableSessionSnapshot($sessionId [$learnerId:$examId] chkRev: $checkpointRevision, authRev: $authoritativeStateRevision, cursor: $currentQuestionIndex)';
}
