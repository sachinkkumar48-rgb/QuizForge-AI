/// Session Configuration Entity (TITAN-KO-019.0 P19).
///
/// Immutable configuration model for initializing a practice session.
library;

import 'package:meta/meta.dart';

import 'question_selection_policy.dart';
import 'question_sequencer_policy.dart';

@immutable
class SessionConfiguration {
  /// Target learner identifier.
  final String learnerId;

  /// Target learning objective IDs included in the session.
  final List<String> objectiveIds;

  /// Maximum number of questions to select for the session.
  final int questionLimit;

  /// Policy used to select questions for practice.
  final QuestionSelectionPolicy selectionPolicy;

  /// Policy used to sequence questions deterministically.
  final QuestionSequencerPolicy sequencerPolicy;

  /// Whether repeated attempts of questions are allowed within the session.
  final bool allowRepeatAttempts;

  SessionConfiguration({
    required this.learnerId,
    required List<String> objectiveIds,
    this.questionLimit = 10,
    this.selectionPolicy = QuestionSelectionPolicy.allObjectiveQuestions,
    this.sequencerPolicy = QuestionSequencerPolicy.curriculumOrder,
    this.allowRepeatAttempts = true,
  }) : objectiveIds = List<String>.unmodifiable(objectiveIds) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty in SessionConfiguration');
    }
    if (this.objectiveIds.isEmpty ||
        this.objectiveIds.any((id) => id.trim().isEmpty)) {
      throw ArgumentError(
          'ObjectiveIds cannot be empty or contain blank entries in SessionConfiguration');
    }
    if (questionLimit <= 0) {
      throw ArgumentError(
          'QuestionLimit must be greater than 0 (got $questionLimit)');
    }
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'objectiveIds': objectiveIds,
        'questionLimit': questionLimit,
        'selectionPolicy': selectionPolicy.name,
        'sequencerPolicy': sequencerPolicy.name,
        'allowRepeatAttempts': allowRepeatAttempts,
      };

  factory SessionConfiguration.fromJson(Map<String, dynamic> json) =>
      SessionConfiguration(
        learnerId: json['learnerId'] as String? ?? '',
        objectiveIds: (json['objectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        questionLimit: json['questionLimit'] as int? ?? 10,
        selectionPolicy: QuestionSelectionPolicy.values.firstWhere(
          (p) => p.name == json['selectionPolicy'],
          orElse: () => QuestionSelectionPolicy.allObjectiveQuestions,
        ),
        sequencerPolicy: QuestionSequencerPolicy.values.firstWhere(
          (p) => p.name == json['sequencerPolicy'],
          orElse: () => QuestionSequencerPolicy.curriculumOrder,
        ),
        allowRepeatAttempts: json['allowRepeatAttempts'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionConfiguration &&
          learnerId == other.learnerId &&
          questionLimit == other.questionLimit &&
          selectionPolicy == other.selectionPolicy &&
          sequencerPolicy == other.sequencerPolicy &&
          allowRepeatAttempts == other.allowRepeatAttempts &&
          _listEquals(objectiveIds, other.objectiveIds);

  @override
  int get hashCode => Object.hash(
        learnerId,
        questionLimit,
        selectionPolicy,
        sequencerPolicy,
        allowRepeatAttempts,
        Object.hashAll(objectiveIds),
      );

  @override
  String toString() =>
      'SessionConfiguration($learnerId, objectives: ${objectiveIds.length}, limit: $questionLimit, sel: ${selectionPolicy.name}, seq: ${sequencerPolicy.name})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
