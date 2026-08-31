/// Adaptive Practice Session Configuration Domain Entity (TITAN-KO-034.0 P34).
///
/// Immutable configuration model driving the orchestration of P33-selected questions
/// into structured, evidence-ready practice sessions.
///
/// Invariants:
/// - Pure declarative parameters; does not perform selection or mutate state.
/// - Validated numerical bounds and non-empty examination identifiers.
library;

import 'package:meta/meta.dart';

/// Deterministic practice session orchestration modes.
enum PracticeSessionMode {
  /// Pedagogical balanced flow (Warm-up -> Core Practice -> High-Priority -> Reinforcement).
  standard,

  /// Focuses primarily on remediating identified learner weak areas first.
  weaknessFocused,

  /// Focuses primarily on high-recurrence and high-yield historical examination PYQs.
  pyqFocused,

  /// Equalized distribution across learning objectives and syllabus topics.
  balanced,

  /// Targeted diagnostic/remedial practice session on specific flagged objectives.
  remedialPractice,

  /// Interleaved revision across multiple topics and difficulty tiers.
  mixedRevision,
}

/// Completion semantics and requirements for the orchestrated session.
enum PracticeCompletionPolicy {
  /// All scheduled questions must be attempted before the session is deemed complete.
  allRequired,

  /// Session accepts partial completion while recording attempted evidence.
  allowPartial,

  /// Learner may gracefully conclude the session at any time or section boundary.
  allowEarlyExit,
}

/// Objective representation and balancing policy within the session.
enum ObjectiveBalancingPolicy {
  /// Follows raw scoring priority ranking without quota balancing.
  none,

  /// Round-robin or equal allocation across available learning objectives.
  balanced,

  /// Objective allocation weighted by P32 learning priority score.
  priorityWeighted,

  /// Enforces a strict maximum question quota per learning objective.
  strictCap,
}

/// Topic representation and balancing policy within the session.
enum TopicBalancingPolicy {
  /// Follows raw scoring priority ranking without topic quota balancing.
  none,

  /// Equal allocation / round-robin across syllabus topics.
  balanced,

  /// Enforces a strict maximum question quota per syllabus topic.
  strictCap,
}

/// Difficulty progression strategy where difficulty metadata is reliably present.
enum PracticeDifficultyProgression {
  /// Preserves the mode/score-determined sequence without forcing difficulty reordering.
  none,

  /// Sequences questions from easier to harder (Easy -> Medium -> Hard).
  easyToHard,

  /// Sequences medium difficulty questions before harder questions (Medium -> Hard).
  mediumToHard,

  /// Interleaves difficulty levels across session sections.
  balanced,
}

/// Immutable configuration model for practice session orchestration.
@immutable
class AdaptivePracticeSessionConfig {
  /// Target examination identifier (e.g., 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Optional target learner identifier for session association.
  final String? learnerId;

  /// Orchestration mode governing question sequencing and section composition.
  final PracticeSessionMode sessionMode;

  /// Completion requirements for the session.
  final PracticeCompletionPolicy completionPolicy;

  /// Objective balancing policy.
  final ObjectiveBalancingPolicy objectiveBalancing;

  /// Topic balancing policy.
  final TopicBalancingPolicy topicBalancing;

  /// Difficulty progression policy.
  final PracticeDifficultyProgression difficultyProgression;

  /// Maximum questions to include in the session (if fewer than selected, truncates deterministically).
  final int? maxQuestions;

  /// Target question count per section/block (default: 5).
  final int sectionSize;

  /// Estimated seconds expected per question for workload calculations (default: 60s).
  final int estimatedSecondsPerQuestion;

  /// Whether an incomplete session is allowed when available questions are fewer than requested.
  final bool allowIncompleteSession;

  /// Additional arbitrary metadata (e.g. source curriculum version).
  final Map<String, dynamic> metadata;

  AdaptivePracticeSessionConfig({
    required String examId,
    this.learnerId,
    this.sessionMode = PracticeSessionMode.standard,
    this.completionPolicy = PracticeCompletionPolicy.allRequired,
    this.objectiveBalancing = ObjectiveBalancingPolicy.none,
    this.topicBalancing = TopicBalancingPolicy.none,
    this.difficultyProgression = PracticeDifficultyProgression.none,
    this.maxQuestions,
    this.sectionSize = 5,
    this.estimatedSecondsPerQuestion = 60,
    this.allowIncompleteSession = true,
    Map<String, dynamic>? metadata,
  })  : examId = examId.trim().toLowerCase(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty in AdaptivePracticeSessionConfig');
    }
    if (maxQuestions != null && maxQuestions! < 1) {
      throw ArgumentError(
          'maxQuestions must be at least 1 (got $maxQuestions)');
    }
    if (sectionSize < 1) {
      throw ArgumentError('sectionSize must be at least 1 (got $sectionSize)');
    }
    if (estimatedSecondsPerQuestion < 1) {
      throw ArgumentError(
          'estimatedSecondsPerQuestion must be at least 1 (got $estimatedSecondsPerQuestion)');
    }
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'sessionMode': sessionMode.name,
        'completionPolicy': completionPolicy.name,
        'objectiveBalancing': objectiveBalancing.name,
        'topicBalancing': topicBalancing.name,
        'difficultyProgression': difficultyProgression.name,
        if (maxQuestions != null) 'maxQuestions': maxQuestions,
        'sectionSize': sectionSize,
        'estimatedSecondsPerQuestion': estimatedSecondsPerQuestion,
        'allowIncompleteSession': allowIncompleteSession,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory AdaptivePracticeSessionConfig.fromJson(Map<String, dynamic> json) =>
      AdaptivePracticeSessionConfig(
        examId: json['examId'] as String? ?? '',
        learnerId: json['learnerId'] as String?,
        sessionMode: PracticeSessionMode.values.firstWhere(
          (m) => m.name == json['sessionMode'],
          orElse: () => PracticeSessionMode.standard,
        ),
        completionPolicy: PracticeCompletionPolicy.values.firstWhere(
          (c) => c.name == json['completionPolicy'],
          orElse: () => PracticeCompletionPolicy.allRequired,
        ),
        objectiveBalancing: ObjectiveBalancingPolicy.values.firstWhere(
          (b) => b.name == json['objectiveBalancing'],
          orElse: () => ObjectiveBalancingPolicy.none,
        ),
        topicBalancing: TopicBalancingPolicy.values.firstWhere(
          (t) => t.name == json['topicBalancing'],
          orElse: () => TopicBalancingPolicy.none,
        ),
        difficultyProgression: PracticeDifficultyProgression.values.firstWhere(
          (d) => d.name == json['difficultyProgression'],
          orElse: () => PracticeDifficultyProgression.none,
        ),
        maxQuestions: json['maxQuestions'] as int?,
        sectionSize: json['sectionSize'] as int? ?? 5,
        estimatedSecondsPerQuestion:
            json['estimatedSecondsPerQuestion'] as int? ?? 60,
        allowIncompleteSession: json['allowIncompleteSession'] as bool? ?? true,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptivePracticeSessionConfig &&
          runtimeType == other.runtimeType &&
          examId == other.examId &&
          learnerId == other.learnerId &&
          sessionMode == other.sessionMode &&
          completionPolicy == other.completionPolicy &&
          objectiveBalancing == other.objectiveBalancing &&
          topicBalancing == other.topicBalancing &&
          difficultyProgression == other.difficultyProgression &&
          maxQuestions == other.maxQuestions &&
          sectionSize == other.sectionSize &&
          estimatedSecondsPerQuestion == other.estimatedSecondsPerQuestion &&
          allowIncompleteSession == other.allowIncompleteSession;

  @override
  int get hashCode => Object.hash(
        examId,
        learnerId,
        sessionMode,
        completionPolicy,
        objectiveBalancing,
        topicBalancing,
        difficultyProgression,
        maxQuestions,
        sectionSize,
        estimatedSecondsPerQuestion,
        allowIncompleteSession,
      );

  @override
  String toString() =>
      'AdaptivePracticeSessionConfig($examId, mode: ${sessionMode.name}, maxQ: $maxQuestions, secSize: $sectionSize)';
}
