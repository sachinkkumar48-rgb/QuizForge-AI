/// Remedial Practice Session Config (TITAN-KO-025.0 P25).
///
/// Immutable domain specification binding a completed [RemedialLesson] to a
/// targeted re-testing/practice retry session (P18/P19).
library;

import 'package:meta/meta.dart';

import 'question_selection_policy.dart';
import 'question_sequencer_policy.dart';
import 'session_configuration.dart';

/// Specification for a targeted re-testing practice session following remedial study.
@immutable
class RemedialPracticeSessionConfig {
  /// Unique identifier of this practice retry configuration.
  final String configId;

  /// Target learner identifier.
  final String learnerId;

  /// Target learning objective identifier being re-assessed.
  final String objectiveId;

  /// Provenance reference to the remedial lesson that prepared the learner.
  final String remedialLessonId;

  /// Deterministically selected set of P15 question IDs targeted for re-testing.
  final List<String> targetQuestionIds;

  /// Maximum questions to attempt in this retry session (validated in range [1, 50]).
  final int questionLimit;

  /// UTC timestamp when this configuration was generated.
  final DateTime createdAt;

  /// Immutable configuration metadata.
  final Map<String, dynamic> metadata;

  RemedialPracticeSessionConfig({
    required this.configId,
    required this.learnerId,
    required this.objectiveId,
    required this.remedialLessonId,
    required List<String> targetQuestionIds,
    this.questionLimit = 5,
    required DateTime createdAt,
    Map<String, dynamic>? metadata,
  })  : targetQuestionIds = List<String>.unmodifiable(targetQuestionIds),
        createdAt = createdAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (configId.trim().isEmpty) {
      throw ArgumentError(
          'configId cannot be empty for RemedialPracticeSessionConfig');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for RemedialPracticeSessionConfig');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'objectiveId cannot be empty for RemedialPracticeSessionConfig');
    }
    if (remedialLessonId.trim().isEmpty) {
      throw ArgumentError(
          'remedialLessonId cannot be empty for RemedialPracticeSessionConfig');
    }
    if (questionLimit < 1 || questionLimit > 50) {
      throw ArgumentError(
          'questionLimit ($questionLimit) must be between 1 and 50');
    }
  }

  /// Whether this config contains targeted questions.
  bool get hasTargetQuestions => targetQuestionIds.isNotEmpty;

  /// Converts this remedial retry specification into a standard P19 [SessionConfiguration]
  /// for orchestration by the [LearningSessionOrchestrator].
  SessionConfiguration toSessionConfiguration({
    QuestionSelectionPolicy selectionPolicy =
        QuestionSelectionPolicy.incorrectFocus,
    QuestionSequencerPolicy sequencerPolicy =
        QuestionSequencerPolicy.difficultyAscending,
    bool allowRepeatAttempts = false,
  }) {
    return SessionConfiguration(
      learnerId: learnerId,
      objectiveIds: [objectiveId],
      questionLimit: questionLimit,
      selectionPolicy: selectionPolicy,
      sequencerPolicy: sequencerPolicy,
      allowRepeatAttempts: allowRepeatAttempts,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'configId': configId,
        'learnerId': learnerId,
        'objectiveId': objectiveId,
        'remedialLessonId': remedialLessonId,
        'targetQuestionIds': targetQuestionIds,
        'questionLimit': questionLimit,
        'createdAt': createdAt.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory RemedialPracticeSessionConfig.fromJson(Map<String, dynamic> json) =>
      RemedialPracticeSessionConfig(
        configId: json['configId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        remedialLessonId: json['remedialLessonId'] as String? ?? '',
        targetQuestionIds:
            (json['targetQuestionIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        questionLimit: json['questionLimit'] as int? ?? 5,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : DateTime.utc(2026, 1, 1),
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedialPracticeSessionConfig &&
          runtimeType == other.runtimeType &&
          configId == other.configId &&
          learnerId == other.learnerId &&
          objectiveId == other.objectiveId &&
          remedialLessonId == other.remedialLessonId &&
          questionLimit == other.questionLimit;

  @override
  int get hashCode => Object.hash(
        configId,
        learnerId,
        objectiveId,
        remedialLessonId,
        questionLimit,
      );

  @override
  String toString() =>
      'RemedialPracticeSessionConfig($configId: $learnerId -> $objectiveId [lesson: $remedialLessonId])';
}
