/// Learning State Update Proposal Domain Entity (TITAN-KO-037.0 P37).
///
/// Encapsulates the immutable, deterministic proposal representing justified
/// learning-state updates derived from observed practice execution evidence.
///
/// Invariants:
/// - Pure evidence-to-proposal transformation; zero persistence writes or learner mutations.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Safe zero-denominator handling (accuracy is null when attempted == 0).
/// - Deeply immutable domain models and unmodifiable collections.
/// - Strict multi-exam isolation and canonical SHA-256 fingerprinting.
library;

import 'package:meta/meta.dart';

import 'adaptive_practice_session_config.dart';
import 'learning_evidence_signal.dart';
import 'practice_execution_state.dart';

/// Immutable, deterministic proposal for downstream learning-state updates.
@immutable
class LearningStateUpdateProposal {
  /// Deterministic proposal identifier.
  final String proposalId;

  /// Source practice session identifier matching P34/P35/P36.
  final String sessionId;

  /// Target examination identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Target learner identifier, if present.
  final String? learnerId;

  /// Pedagogical practice session mode.
  final PracticeSessionMode sessionMode;

  /// Execution lifecycle status from P35/P36.
  final PracticeExecutionStatus sessionStatus;

  /// Cryptographic SHA-256 fingerprint of the source P36 ConsolidatedPracticeOutcome.
  final String sourceOutcomeFingerprint;

  /// Authoritative timestamp when this proposal was generated (caller-supplied).
  final DateTime proposedAt;

  /// Calibrated overall evidence strength across the session.
  final EvidenceStrength overallEvidenceStrength;

  /// Overall descriptive outcome trajectory across the session.
  final OutcomePattern overallPattern;

  /// Primary recommended downstream action proposal.
  final ProposedLearningAction recommendedAction;

  /// Total questions in the session.
  final int totalQuestions;

  /// Total questions answered.
  final int attemptedCount;

  /// Total questions answered correctly.
  final int correctCount;

  /// Total questions answered incorrectly.
  final int incorrectCount;

  /// Total questions skipped.
  final int skippedCount;

  /// Total questions left unanswered.
  final int unansweredCount;

  /// Ratio of processed questions in [0.0, 1.0].
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Overall session score ratio in [0.0, 1.0].
  final double scoreRatio;

  /// Ordered sequence of question-level learning evidence signals.
  final List<QuestionLearningSignal> questionSignals;

  /// Aggregated topic learning signals (keys sorted deterministically).
  final Map<String, TopicLearningSignal> topicSignals;

  /// Aggregated objective learning signals (keys sorted deterministically).
  final Map<String, ObjectiveLearningSignal> objectiveSignals;

  /// Aggregated section learning signals (keys sorted deterministically).
  final Map<String, SectionLearningSignal> sectionSignals;

  /// Aggregated difficulty band learning signals (keys sorted deterministically).
  final Map<String, DifficultyLearningSignal> difficultySignals;

  /// Deterministic SHA-256 fingerprint identifying this exact proposal.
  final String fingerprint;

  LearningStateUpdateProposal({
    required this.proposalId,
    required this.sessionId,
    required String examId,
    this.learnerId,
    required this.sessionMode,
    required this.sessionStatus,
    required this.sourceOutcomeFingerprint,
    required this.proposedAt,
    required this.overallEvidenceStrength,
    required this.overallPattern,
    required this.recommendedAction,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.scoreRatio,
    required List<QuestionLearningSignal> questionSignals,
    required Map<String, TopicLearningSignal> topicSignals,
    required Map<String, ObjectiveLearningSignal> objectiveSignals,
    required Map<String, SectionLearningSignal> sectionSignals,
    required Map<String, DifficultyLearningSignal> difficultySignals,
    required this.fingerprint,
  })  : examId = examId.trim().toLowerCase(),
        questionSignals =
            List<QuestionLearningSignal>.unmodifiable(questionSignals),
        topicSignals =
            Map<String, TopicLearningSignal>.unmodifiable(topicSignals),
        objectiveSignals =
            Map<String, ObjectiveLearningSignal>.unmodifiable(objectiveSignals),
        sectionSignals =
            Map<String, SectionLearningSignal>.unmodifiable(sectionSignals),
        difficultySignals = Map<String, DifficultyLearningSignal>.unmodifiable(
            difficultySignals) {
    if (proposalId.trim().isEmpty) {
      throw ArgumentError('proposalId cannot be empty');
    }
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (sourceOutcomeFingerprint.trim().isEmpty) {
      throw ArgumentError('sourceOutcomeFingerprint cannot be empty');
    }
    if (fingerprint.trim().isEmpty) {
      throw ArgumentError('fingerprint cannot be empty');
    }
    if (totalQuestions < 0 ||
        attemptedCount < 0 ||
        correctCount < 0 ||
        incorrectCount < 0 ||
        skippedCount < 0 ||
        unansweredCount < 0) {
      throw ArgumentError('Counts cannot be negative');
    }
    if (correctCount + incorrectCount != attemptedCount) {
      throw ArgumentError(
          'Invariant violation: correctCount ($correctCount) + incorrectCount ($incorrectCount) != attemptedCount ($attemptedCount)');
    }
    if (attemptedCount + skippedCount + unansweredCount != totalQuestions) {
      throw ArgumentError(
          'Invariant violation: attemptedCount ($attemptedCount) + skippedCount ($skippedCount) + unansweredCount ($unansweredCount) != totalQuestions ($totalQuestions)');
    }
  }

  Map<String, dynamic> toJson() => {
        'proposalId': proposalId,
        'sessionId': sessionId,
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'sessionMode': sessionMode.name,
        'sessionStatus': sessionStatus.name,
        'sourceOutcomeFingerprint': sourceOutcomeFingerprint,
        'proposedAt': proposedAt.toIso8601String(),
        'overallEvidenceStrength': overallEvidenceStrength.name,
        'overallPattern': overallPattern.name,
        'recommendedAction': recommendedAction.name,
        'totalQuestions': totalQuestions,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'unansweredCount': unansweredCount,
        'completionRate': completionRate,
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'scoreRatio': scoreRatio,
        'questionSignals': questionSignals.map((q) => q.toJson()).toList(),
        'topicSignals': topicSignals.map((k, v) => MapEntry(k, v.toJson())),
        'objectiveSignals':
            objectiveSignals.map((k, v) => MapEntry(k, v.toJson())),
        'sectionSignals': sectionSignals.map((k, v) => MapEntry(k, v.toJson())),
        'difficultySignals':
            difficultySignals.map((k, v) => MapEntry(k, v.toJson())),
        'fingerprint': fingerprint,
      };

  factory LearningStateUpdateProposal.fromJson(Map<String, dynamic> json) =>
      LearningStateUpdateProposal(
        proposalId: json['proposalId'] as String,
        sessionId: json['sessionId'] as String,
        examId: json['examId'] as String,
        learnerId: json['learnerId'] as String?,
        sessionMode: PracticeSessionMode.values.firstWhere(
          (e) => e.name == json['sessionMode'],
          orElse: () => PracticeSessionMode.standard,
        ),
        sessionStatus: PracticeExecutionStatus.values.firstWhere(
          (e) => e.name == json['sessionStatus'],
          orElse: () => PracticeExecutionStatus.completed,
        ),
        sourceOutcomeFingerprint: json['sourceOutcomeFingerprint'] as String,
        proposedAt: DateTime.parse(json['proposedAt'] as String).toUtc(),
        overallEvidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['overallEvidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        overallPattern: OutcomePattern.values.firstWhere(
          (e) => e.name == json['overallPattern'],
          orElse: () => OutcomePattern.insufficientEvidence,
        ),
        recommendedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['recommendedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
        totalQuestions: json['totalQuestions'] as int,
        attemptedCount: json['attemptedCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        skippedCount: json['skippedCount'] as int,
        unansweredCount: json['unansweredCount'] as int,
        completionRate: (json['completionRate'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        scoreRatio: (json['scoreRatio'] as num).toDouble(),
        questionSignals: (json['questionSignals'] as List? ?? const [])
            .map((e) =>
                QuestionLearningSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        topicSignals: (json['topicSignals'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(
                k, TopicLearningSignal.fromJson(v as Map<String, dynamic>))),
        objectiveSignals: (json['objectiveSignals'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k,
                ObjectiveLearningSignal.fromJson(v as Map<String, dynamic>))),
        sectionSignals: (json['sectionSignals'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(
                k, SectionLearningSignal.fromJson(v as Map<String, dynamic>))),
        difficultySignals: (json['difficultySignals']
                    as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k,
                DifficultyLearningSignal.fromJson(v as Map<String, dynamic>))),
        fingerprint: json['fingerprint'] as String,
      );

  @override
  String toString() =>
      'LearningStateUpdateProposal(id: $proposalId, exam: $examId, action: ${recommendedAction.name}, strength: ${overallEvidenceStrength.name}, pattern: ${overallPattern.name}, accuracy: ${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%)';
}
