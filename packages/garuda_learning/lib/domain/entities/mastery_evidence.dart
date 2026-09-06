/// Mastery Evidence Entities (TITAN-KO-040.0 P40).
///
/// Encapsulates discrete, strongly typed learning evidence items converted from
/// practice sessions, diagnostic assessments, and remedial activities.
library;

import 'package:meta/meta.dart';

/// Categorical evidence type reflecting the source and nature of learner performance.
enum MasteryEvidenceType {
  /// Correct response submitted during standard or adaptive practice.
  practiceCorrect,

  /// Incorrect response submitted during standard or adaptive practice.
  practiceIncorrect,

  /// Question explicitly skipped by the learner during practice.
  practiceSkipped,

  /// Diagnostic placement or benchmark assessment correct response.
  diagnosticCorrect,

  /// Diagnostic placement or benchmark assessment incorrect response.
  diagnosticIncorrect,

  /// Confirmed completion of a targeted remedial lesson or reading unit.
  remedialCompleted,

  /// Remedial lesson attempted but left incomplete.
  remedialUncompleted;

  /// Whether this evidence item represents a positive achievement.
  bool get isPositive =>
      this == MasteryEvidenceType.practiceCorrect ||
      this == MasteryEvidenceType.diagnosticCorrect ||
      this == MasteryEvidenceType.remedialCompleted;

  /// Whether this evidence represents an active practice attempt.
  bool get isPractice =>
      this == MasteryEvidenceType.practiceCorrect ||
      this == MasteryEvidenceType.practiceIncorrect ||
      this == MasteryEvidenceType.practiceSkipped;

  /// Serializes to snake_case string.
  String toJson() {
    switch (this) {
      case MasteryEvidenceType.practiceCorrect:
        return 'practice_correct';
      case MasteryEvidenceType.practiceIncorrect:
        return 'practice_incorrect';
      case MasteryEvidenceType.practiceSkipped:
        return 'practice_skipped';
      case MasteryEvidenceType.diagnosticCorrect:
        return 'diagnostic_correct';
      case MasteryEvidenceType.diagnosticIncorrect:
        return 'diagnostic_incorrect';
      case MasteryEvidenceType.remedialCompleted:
        return 'remedial_completed';
      case MasteryEvidenceType.remedialUncompleted:
        return 'remedial_uncompleted';
    }
  }

  /// Deserializes from string format with fallback to practiceIncorrect.
  static MasteryEvidenceType fromJson(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'practice_correct':
        return MasteryEvidenceType.practiceCorrect;
      case 'practice_incorrect':
        return MasteryEvidenceType.practiceIncorrect;
      case 'practice_skipped':
        return MasteryEvidenceType.practiceSkipped;
      case 'diagnostic_correct':
        return MasteryEvidenceType.diagnosticCorrect;
      case 'diagnostic_incorrect':
        return MasteryEvidenceType.diagnosticIncorrect;
      case 'remedial_completed':
        return MasteryEvidenceType.remedialCompleted;
      case 'remedial_uncompleted':
        return MasteryEvidenceType.remedialUncompleted;
      default:
        return MasteryEvidenceType.practiceIncorrect;
    }
  }
}

/// Immutable, atomic evidence item contributing to topic/concept mastery estimation.
@immutable
class MasteryEvidenceItem {
  /// Unique identifier of this evidence record.
  final String evidenceId;

  /// Specific categorical evidence classification.
  final MasteryEvidenceType evidenceType;

  /// Syllabus topic or concept identifier.
  final String topicId;

  /// Specific learning objective identifier, if available.
  final String? objectiveId;

  /// Associated question identifier, if originating from a question attempt.
  final String? questionId;

  /// Difficulty level of the question ('Easy', 'Medium', 'Hard').
  final String difficulty;

  /// Whether the answer was evaluated as correct.
  final bool isCorrect;

  /// Whether the question was skipped.
  final bool isSkipped;

  /// Deterministic weighting multiplier (defaults to 1.0).
  final double weight;

  /// UTC timestamp when this evidence occurred.
  final DateTime timestamp;

  /// Audit provenance tracking source session or activity ID.
  final String provenance;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  MasteryEvidenceItem({
    required String evidenceId,
    required this.evidenceType,
    required String topicId,
    this.objectiveId,
    this.questionId,
    String? difficulty,
    required this.isCorrect,
    this.isSkipped = false,
    this.weight = 1.0,
    required this.timestamp,
    String? provenance,
    Map<String, dynamic>? metadata,
  })  : evidenceId = evidenceId.trim(),
        topicId = topicId.trim(),
        difficulty = difficulty?.trim().isNotEmpty == true
            ? difficulty!.trim()
            : 'Medium',
        provenance = provenance?.trim() ?? '',
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.evidenceId.isEmpty) {
      throw ArgumentError('evidenceId cannot be empty');
    }
    if (this.topicId.isEmpty) {
      throw ArgumentError('topicId cannot be empty');
    }
    if (weight < 0.0) {
      throw ArgumentError('weight cannot be negative');
    }
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'evidenceId': evidenceId,
        'evidenceType': evidenceType.toJson(),
        'topicId': topicId,
        if (objectiveId != null) 'objectiveId': objectiveId,
        if (questionId != null) 'questionId': questionId,
        'difficulty': difficulty,
        'isCorrect': isCorrect,
        'isSkipped': isSkipped,
        'weight': weight,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'provenance': provenance,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from a JSON map.
  factory MasteryEvidenceItem.fromJson(Map<String, dynamic> json) {
    return MasteryEvidenceItem(
      evidenceId: json['evidenceId'] as String? ?? '',
      evidenceType:
          MasteryEvidenceType.fromJson(json['evidenceType'] as String?),
      topicId: json['topicId'] as String? ?? '',
      objectiveId: json['objectiveId'] as String?,
      questionId: json['questionId'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      isCorrect: json['isCorrect'] as bool? ?? false,
      isSkipped: json['isSkipped'] as bool? ?? false,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      timestamp: DateTime.parse(
              json['timestamp'] as String? ?? '2026-01-01T00:00:00.000Z')
          .toUtc(),
      provenance: json['provenance'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryEvidenceItem &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          evidenceType == other.evidenceType &&
          topicId == other.topicId &&
          objectiveId == other.objectiveId &&
          questionId == other.questionId &&
          difficulty == other.difficulty &&
          isCorrect == other.isCorrect &&
          isSkipped == other.isSkipped &&
          weight == other.weight &&
          timestamp == other.timestamp &&
          provenance == other.provenance;

  @override
  int get hashCode => Object.hash(
        evidenceId,
        evidenceType,
        topicId,
        objectiveId,
        questionId,
        difficulty,
        isCorrect,
        isSkipped,
        weight,
        timestamp,
        provenance,
      );

  @override
  String toString() =>
      'MasteryEvidenceItem(id: $evidenceId, topic: $topicId, type: ${evidenceType.name}, correct: $isCorrect, diff: $difficulty)';
}
