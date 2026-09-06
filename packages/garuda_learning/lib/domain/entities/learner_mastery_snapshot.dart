/// Learner Mastery Snapshot Domain Entity (TITAN-KO-040.0 P40).
///
/// Encapsulates the complete, immutable point-in-time progressive mastery state
/// across syllabus topics for a specific learner and examination tenant context.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'adaptive_mastery_decision_output.dart';
import 'mastery_exceptions.dart';
import 'topic_mastery_profile.dart';

/// Immutable aggregate snapshot capturing the progressive mastery state across topics.
@immutable
class LearnerMasterySnapshot {
  /// Supported schema version.
  static const int currentSchemaVersion = 1;

  /// Schema version of the payload for forward/backward compatibility.
  final int schemaVersion;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Monotonic revision sequence number of the underlying authoritative state.
  final int authoritativeRevision;

  /// Topic mastery profiles keyed by canonical topicId, deterministically sorted.
  final Map<String, TopicMasteryProfile> topicProfiles;

  /// Derived deterministic adaptive decision signals.
  final AdaptiveMasteryDecisionOutput decisionOutput;

  /// Timestamp when this snapshot was evaluated.
  final DateTime evaluatedAt;

  /// SHA-256 cryptographic checksum over the canonical JSON payload.
  final String checksum;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  LearnerMasterySnapshot({
    this.schemaVersion = currentSchemaVersion,
    required String learnerId,
    required String examId,
    required this.authoritativeRevision,
    required Map<String, TopicMasteryProfile> topicProfiles,
    required this.decisionOutput,
    required this.evaluatedAt,
    String? checksum,
    Map<String, dynamic>? metadata,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        topicProfiles = Map<String, TopicMasteryProfile>.unmodifiable(
          topicProfiles is SplayTreeMap<String, TopicMasteryProfile>
              ? topicProfiles
              : SplayTreeMap<String, TopicMasteryProfile>.from(topicProfiles),
        ),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}),
        checksum = checksum ??
            _computeChecksum(
              schemaVersion,
              learnerId.trim(),
              examId.trim().toLowerCase(),
              authoritativeRevision,
              topicProfiles,
              evaluatedAt,
            ) {
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty in LearnerMasterySnapshot');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty in LearnerMasterySnapshot');
    }
    if (authoritativeRevision < 1) {
      throw ArgumentError('authoritativeRevision must be >= 1');
    }
  }

  /// Deterministic canonical SHA-256 checksum computation.
  static String _computeChecksum(
    int schemaVersion,
    String learnerId,
    String examId,
    int revision,
    Map<String, TopicMasteryProfile> profiles,
    DateTime timestamp,
  ) {
    final sortedProfiles = SplayTreeMap<String, dynamic>();
    for (final entry in profiles.entries) {
      sortedProfiles[entry.key] = entry.value.toJson();
    }

    final canonicalPayload = jsonEncode({
      'schemaVersion': schemaVersion,
      'learnerId': learnerId,
      'examId': examId,
      'authoritativeRevision': revision,
      'topicProfiles': sortedProfiles,
      'evaluatedAt': timestamp.toUtc().toIso8601String(),
    });

    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  /// Verifies cryptographic checksum integrity.
  bool verifyChecksum() {
    final computed = _computeChecksum(
      schemaVersion,
      learnerId,
      examId,
      authoritativeRevision,
      topicProfiles,
      evaluatedAt,
    );
    return computed == checksum;
  }

  /// Serializes to a standard JSON map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'learnerId': learnerId,
        'examId': examId,
        'authoritativeRevision': authoritativeRevision,
        'topicProfiles': topicProfiles.map((k, v) => MapEntry(k, v.toJson())),
        'decisionOutput': decisionOutput.toJson(),
        'evaluatedAt': evaluatedAt.toUtc().toIso8601String(),
        'checksum': checksum,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from a JSON map with schema and tenant validation.
  factory LearnerMasterySnapshot.fromJson(Map<String, dynamic> json) {
    final schema = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schema > currentSchemaVersion) {
      throw UnsupportedMasterySchemaException(
        message: 'Unsupported mastery snapshot schema version $schema',
        supportedVersion: currentSchemaVersion,
        foundVersion: schema,
      );
    }

    final learnerId = json['learnerId'] as String?;
    final examId = json['examId'] as String?;
    if (learnerId == null || learnerId.trim().isEmpty) {
      throw const MalformedMasteryDataException(
        message: 'Missing or empty learnerId in mastery snapshot JSON',
      );
    }
    if (examId == null || examId.trim().isEmpty) {
      throw const MalformedMasteryDataException(
        message: 'Missing or empty examId in mastery snapshot JSON',
      );
    }

    final rawProfiles =
        json['topicProfiles'] as Map<String, dynamic>? ?? const {};
    final profiles = <String, TopicMasteryProfile>{};
    for (final entry in rawProfiles.entries) {
      if (entry.value is Map<String, dynamic>) {
        profiles[entry.key] =
            TopicMasteryProfile.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    final rawDecision = json['decisionOutput'];
    final decision = rawDecision is Map<String, dynamic>
        ? AdaptiveMasteryDecisionOutput.fromJson(rawDecision)
        : AdaptiveMasteryDecisionOutput(
            weakestTopics: const [],
            strongestTopics: const [],
            remediationRequiredTopics: const [],
            approachingMasteryTopics: const [],
            insufficientEvidenceTopics: const [],
            recommendedDifficultyBand: const {},
            masteryDistribution: const {},
            overallMasteryScore: 0.0,
            overallConfidence: 0.0,
          );

    final evaluatedAt = DateTime.parse(
            json['evaluatedAt'] as String? ?? '2026-01-01T00:00:00.000Z')
        .toUtc();

    final checksum = json['checksum'] as String? ?? '';

    final snapshot = LearnerMasterySnapshot(
      schemaVersion: schema,
      learnerId: learnerId,
      examId: examId,
      authoritativeRevision:
          (json['authoritativeRevision'] as num?)?.toInt() ?? 1,
      topicProfiles: profiles,
      decisionOutput: decision,
      evaluatedAt: evaluatedAt,
      checksum: checksum.isNotEmpty ? checksum : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );

    if (checksum.isNotEmpty && !snapshot.verifyChecksum()) {
      throw MalformedMasteryDataException(
        message:
            'Checksum mismatch in LearnerMasterySnapshot (tampered or corrupt payload)',
        details: {'expected': checksum, 'computed': snapshot.checksum},
      );
    }

    return snapshot;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnerMasterySnapshot &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          authoritativeRevision == other.authoritativeRevision &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        learnerId,
        examId,
        authoritativeRevision,
        checksum,
      );

  @override
  String toString() =>
      'LearnerMasterySnapshot($learnerId:$examId@rev$authoritativeRevision, topics: ${topicProfiles.length})';
}
