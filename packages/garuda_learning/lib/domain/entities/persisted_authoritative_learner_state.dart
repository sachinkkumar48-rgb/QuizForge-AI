/// Persisted Authoritative Learner State Domain Entity (TITAN-KO-039.0 P39).
///
/// Immutable representation of authoritative learner state designed for durable,
/// deterministic storage and recovery across application restarts.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'authoritative_persistence_error.dart';
import 'learner_objective_status.dart';
import 'learner_progress.dart';

/// Persisted contract encapsulating authoritative state, revision, schema version,
/// and cryptographic integrity verification.
@immutable
class PersistedAuthoritativeLearnerState {
  /// Current supported schema version for authoritative state persistence.
  static const int currentSchemaVersion = 1;

  /// Schema version of the persisted payload.
  final int schemaVersion;

  /// Monotonic revision sequence number (strictly >= 1).
  final int revision;

  /// Normalized target learner identifier.
  final String learnerId;

  /// Normalized target examination identifier (lowercase, trimmed).
  final String examId;

  /// Progress records keyed by canonical objective ID (deterministically sorted).
  final Map<String, LearnerProgress> progressMap;

  /// Set of session IDs already incorporated into this state (deterministically sorted).
  final Set<String> processedSessionIds;

  /// Authoritative last updated UTC timestamp.
  final DateTime lastUpdatedAt;

  /// Cryptographic fingerprint matching AuthoritativeLearnerState.stateFingerprint.
  final String stateFingerprint;

  /// SHA-256 checksum over the canonical persisted state payload for corruption detection.
  final String checksum;

  /// Optional deterministic recovery and audit metadata.
  final Map<String, dynamic> metadata;

  PersistedAuthoritativeLearnerState({
    this.schemaVersion = currentSchemaVersion,
    required this.revision,
    required String learnerId,
    required String examId,
    required Map<String, LearnerProgress> progressMap,
    Set<String>? processedSessionIds,
    required DateTime lastUpdatedAt,
    required this.stateFingerprint,
    String? checksum,
    Map<String, dynamic>? metadata,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        lastUpdatedAt = lastUpdatedAt.toUtc(),
        progressMap = Map<String, LearnerProgress>.unmodifiable(
          progressMap is SplayTreeMap<String, LearnerProgress>
              ? progressMap
              : SplayTreeMap<String, LearnerProgress>.from(progressMap),
        ),
        processedSessionIds = Set<String>.unmodifiable(
          processedSessionIds is SplayTreeSet<String>
              ? processedSessionIds
              : SplayTreeSet<String>.from(
                  processedSessionIds ?? const <String>{}),
        ),
        metadata = metadata == null
            ? const {}
            : Map<String, dynamic>.unmodifiable(
                SplayTreeMap<String, dynamic>.from(metadata)),
        checksum = checksum ??
            _computeChecksum(
              schemaVersion: schemaVersion,
              revision: revision,
              learnerId: learnerId.trim(),
              examId: examId.trim().toLowerCase(),
              progressMap: progressMap,
              processedSessionIds: processedSessionIds ?? const <String>{},
              lastUpdatedAt: lastUpdatedAt.toUtc(),
              stateFingerprint: stateFingerprint,
              metadata: metadata ?? const {},
            ) {
    if (this.learnerId.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message:
            'learnerId cannot be empty in PersistedAuthoritativeLearnerState',
      );
    }
    if (this.examId.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'examId cannot be empty in PersistedAuthoritativeLearnerState',
      );
    }
    if (revision < 1) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.invalidNumericValue,
        message: 'revision must be >= 1, received: $revision',
      );
    }
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
        message:
            'Unsupported schema version: $schemaVersion (supported: 1..$currentSchemaVersion)',
      );
    }
    if (stateFingerprint.trim().isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'stateFingerprint cannot be empty',
      );
    }
    if (this.checksum.trim().isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'checksum cannot be empty',
      );
    }
  }

  /// Constructs a persisted record directly from an [AuthoritativeLearnerState].
  factory PersistedAuthoritativeLearnerState.fromAuthoritativeState(
    AuthoritativeLearnerState state, {
    int? revision,
    int schemaVersion = currentSchemaVersion,
    Map<String, dynamic>? metadata,
  }) {
    final effectiveRevision = revision ?? state.revision;
    return PersistedAuthoritativeLearnerState(
      schemaVersion: schemaVersion,
      revision: effectiveRevision,
      learnerId: state.learnerId,
      examId: state.examId,
      progressMap: state.progressMap,
      processedSessionIds: state.processedSessionIds,
      lastUpdatedAt: state.lastUpdatedAt,
      stateFingerprint: state.stateFingerprint,
      metadata: metadata,
    );
  }

  /// Reconstructs the live immutable [AuthoritativeLearnerState].
  AuthoritativeLearnerState toAuthoritativeState() {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt,
      stateFingerprint: stateFingerprint,
      revision: revision,
    );
  }

  /// Computes canonical checksum string across all state attributes.
  static String _computeChecksum({
    required int schemaVersion,
    required int revision,
    required String learnerId,
    required String examId,
    required Map<String, LearnerProgress> progressMap,
    required Set<String> processedSessionIds,
    required DateTime lastUpdatedAt,
    required String stateFingerprint,
    required Map<String, dynamic> metadata,
  }) {
    final sb = StringBuffer();
    sb.write(
        '$schemaVersion|$revision|$learnerId|$examId|${lastUpdatedAt.toUtc().toIso8601String()}|$stateFingerprint|');

    final sortedProgressKeys = progressMap is SplayTreeMap
        ? progressMap.keys
        : (progressMap.keys.toList()..sort());
    for (final key in sortedProgressKeys) {
      final p = progressMap[key]!;
      sb.write(
          '$key:${p.attemptCount}:${p.correctCount}:${p.successRate.toStringAsFixed(4)}:${p.status.name}:${p.lastAttemptAt?.toUtc().toIso8601String() ?? "null"};');
    }

    sb.write('|');
    final sortedSessionIds = processedSessionIds is SplayTreeSet
        ? processedSessionIds
        : (processedSessionIds.toList()..sort());
    sb.write(sortedSessionIds.join(','));

    if (metadata.isNotEmpty) {
      sb.write('|');
      final sortedMetaKeys = metadata.keys.toList()..sort();
      for (final k in sortedMetaKeys) {
        sb.write('$k=${metadata[k]};');
      }
    }

    return sha256.convert(utf8.encode(sb.toString())).toString();
  }

  /// Deterministic Map representation with lexicographically ordered keys.
  Map<String, dynamic> toJson() {
    final sortedProgress = SplayTreeMap<String, dynamic>();
    for (final entry in progressMap.entries) {
      sortedProgress[entry.key] = entry.value.toJson();
    }

    final sortedSessions = processedSessionIds.toList()..sort();

    final map = SplayTreeMap<String, dynamic>();
    map['checksum'] = checksum;
    map['examId'] = examId;
    map['lastUpdatedAt'] = lastUpdatedAt.toUtc().toIso8601String();
    map['learnerId'] = learnerId;
    if (metadata.isNotEmpty) {
      map['metadata'] = SplayTreeMap<String, dynamic>.from(metadata);
    }
    map['processedSessionIds'] = sortedSessions;
    map['progressMap'] = sortedProgress;
    map['revision'] = revision;
    map['schemaVersion'] = schemaVersion;
    map['stateFingerprint'] = stateFingerprint;

    return map;
  }

  /// Canonical JSON string serialization guaranteeing identical string outputs
  /// for identical logical states.
  String toCanonicalJson() => jsonEncode(toJson());

  /// Strict deserializer from JSON map with deep validation and typed errors.
  factory PersistedAuthoritativeLearnerState.fromJson(
      Map<String, dynamic> json) {
    // 1. Schema version validation first
    final rawSchema = json['schemaVersion'];
    if (rawSchema == null) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
        message: 'Missing schemaVersion (legacy schema v0)',
        details: {
          'persistedSchemaVersion': 0,
          'currentSchemaVersion': currentSchemaVersion,
        },
      );
    }
    if (rawSchema is! int) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.invalidNumericValue,
        message: 'schemaVersion must be an integer, received: $rawSchema',
      );
    }
    if (rawSchema != currentSchemaVersion) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
        message:
            'Unsupported schema version $rawSchema (active: $currentSchemaVersion)',
        details: {
          'persistedSchemaVersion': rawSchema,
          'currentSchemaVersion': currentSchemaVersion,
        },
      );
    }

    // 2. Required fields check for schema 1
    const requiredFields = [
      'schemaVersion',
      'revision',
      'learnerId',
      'examId',
      'lastUpdatedAt',
      'progressMap',
      'processedSessionIds',
      'stateFingerprint',
      'checksum',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.missingRequiredField,
          message: 'Missing required field in persisted state: "$field"',
          details: {'field': field},
        );
      }
    }

    // 3. Revision validation
    final rawRevision = json['revision'];
    if (rawRevision is! int || rawRevision < 1) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.invalidNumericValue,
        message: 'revision must be an integer >= 1, received: $rawRevision',
      );
    }

    // 4. Learner & Exam ID validation
    final learnerId = (json['learnerId'] as String).trim();
    final examId = (json['examId'] as String).trim().toLowerCase();
    if (learnerId.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'learnerId cannot be empty',
      );
    }
    if (examId.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'examId cannot be empty',
      );
    }

    // 5. Date validation
    final rawDate = json['lastUpdatedAt'];
    DateTime lastUpdatedAt;
    try {
      lastUpdatedAt = DateTime.parse(rawDate as String).toUtc();
    } catch (e) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.malformedPayload,
        message: 'Invalid lastUpdatedAt timestamp format: "$rawDate"',
      );
    }

    // 6. Progress Map validation & Deserialization
    final rawProgressMap = json['progressMap'];
    if (rawProgressMap is! Map) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.malformedPayload,
        message: 'progressMap must be a JSON map',
      );
    }

    final progressMap = SplayTreeMap<String, LearnerProgress>();
    for (final entry in rawProgressMap.entries) {
      final objId = entry.key as String;
      final val = entry.value;
      if (val is! Map) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.malformedPayload,
          message: 'Progress entry for "$objId" must be a map',
        );
      }
      final pMap = Map<String, dynamic>.from(val);

      // Validate progress fields
      if (!pMap.containsKey('learnerId') ||
          !pMap.containsKey('objectiveId') ||
          !pMap.containsKey('attemptCount') ||
          !pMap.containsKey('correctCount') ||
          !pMap.containsKey('status')) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.missingRequiredField,
          message: 'Progress entry for "$objId" is missing required fields',
        );
      }

      if (pMap['learnerId'] != learnerId) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Progress record learnerId "${pMap['learnerId']}" does not match root learnerId "$learnerId"',
        );
      }

      final attemptCount = pMap['attemptCount'];
      final correctCount = pMap['correctCount'];
      if (attemptCount is! int || attemptCount < 0) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.invalidNumericValue,
          message:
              'attemptCount for "$objId" must be non-negative integer, got $attemptCount',
        );
      }
      if (correctCount is! int ||
          correctCount < 0 ||
          correctCount > attemptCount) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.invalidNumericValue,
          message:
              'correctCount ($correctCount) must be between 0 and attemptCount ($attemptCount) for "$objId"',
        );
      }

      if (pMap.containsKey('successRate') && pMap['successRate'] != null) {
        final rate = (pMap['successRate'] as num).toDouble();
        if (rate < 0.0 || rate > 1.0) {
          throw AuthoritativePersistenceException(
            code: AuthoritativePersistenceErrorCode.invalidNumericValue,
            message:
                'successRate for "$objId" must be between 0.0 and 1.0, got $rate',
          );
        }
      }

      // Status enum validation
      final statusStr = pMap['status'] as String?;
      final validStatus =
          LearnerObjectiveStatus.values.any((s) => s.name == statusStr);
      if (!validStatus) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.invalidEnumValue,
          message:
              'Invalid LearnerObjectiveStatus "$statusStr" for objective "$objId"',
          details: {
            'value': statusStr,
            'validValues':
                LearnerObjectiveStatus.values.map((s) => s.name).toList(),
          },
        );
      }

      progressMap[objId] = LearnerProgress.fromJson(pMap);
    }

    // 7. Processed sessions validation
    final rawSessions = json['processedSessionIds'];
    if (rawSessions is! List) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.malformedPayload,
        message: 'processedSessionIds must be a JSON array',
      );
    }
    final processedSessionIds = SplayTreeSet<String>.from(
      rawSessions.map((s) => s.toString().trim()),
    );

    // 8. State fingerprint validation
    final stateFingerprint = (json['stateFingerprint'] as String).trim();
    if (stateFingerprint.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'stateFingerprint cannot be empty',
      );
    }

    // Verify state fingerprint matches internal contents
    final reconstructedState = AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt,
      revision: rawRevision,
    );
    if (reconstructedState.stateFingerprint != stateFingerprint) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.inconsistentState,
        message:
            'Structural corruption: declared stateFingerprint "$stateFingerprint" does not match recomputed fingerprint "${reconstructedState.stateFingerprint}"',
      );
    }

    // 9. Metadata extraction
    final metadata = json.containsKey('metadata') && json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};

    // 10. Checksum validation (detect bitrot / tampering)
    final storedChecksum = (json['checksum'] as String).trim();
    final computedChecksum = _computeChecksum(
      schemaVersion: rawSchema,
      revision: rawRevision,
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt,
      stateFingerprint: stateFingerprint,
      metadata: metadata,
    );

    if (storedChecksum != computedChecksum) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.corruptedChecksum,
        message:
            'Persisted state checksum mismatch: expected "$storedChecksum", computed "$computedChecksum"',
        details: {
          'storedChecksum': storedChecksum,
          'computedChecksum': computedChecksum,
        },
      );
    }

    return PersistedAuthoritativeLearnerState(
      schemaVersion: rawSchema,
      revision: rawRevision,
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt,
      stateFingerprint: stateFingerprint,
      checksum: storedChecksum,
      metadata: metadata,
    );
  }

  /// Deserializer parsing a raw JSON string.
  factory PersistedAuthoritativeLearnerState.fromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.malformedPayload,
          message: 'Raw JSON must decode to a JSON object/map',
        );
      }
      return PersistedAuthoritativeLearnerState.fromJson(decoded);
    } on FormatException catch (e) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.malformedPayload,
        message: 'Malformed JSON payload: ${e.message}',
      );
    }
  }

  /// Creates a copy with specified modifications.
  PersistedAuthoritativeLearnerState copyWith({
    int? schemaVersion,
    int? revision,
    String? learnerId,
    String? examId,
    Map<String, LearnerProgress>? progressMap,
    Set<String>? processedSessionIds,
    DateTime? lastUpdatedAt,
    String? stateFingerprint,
    String? checksum,
    Map<String, dynamic>? metadata,
  }) {
    return PersistedAuthoritativeLearnerState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      revision: revision ?? this.revision,
      learnerId: learnerId ?? this.learnerId,
      examId: examId ?? this.examId,
      progressMap: progressMap ?? this.progressMap,
      processedSessionIds: processedSessionIds ?? this.processedSessionIds,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      stateFingerprint: stateFingerprint ?? this.stateFingerprint,
      checksum: checksum,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedAuthoritativeLearnerState &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          revision == other.revision &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          stateFingerprint == other.stateFingerprint &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        revision,
        learnerId,
        examId,
        stateFingerprint,
        checksum,
      );

  @override
  String toString() =>
      'PersistedAuthoritativeLearnerState(v$schemaVersion, rev: $revision, learner: $learnerId, exam: $examId, fp: ${stateFingerprint.substring(0, 8)}..., chk: ${checksum.substring(0, 8)}...)';
}
