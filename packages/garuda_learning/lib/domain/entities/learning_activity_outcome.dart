/// Learning Activity Outcome Domain Entity (TITAN-KO-043.0 P43).
///
/// Encapsulates normalized, activity-independent learning outcome metrics,
/// mathematically safe performance indicators, dimensional performance aggregations,
/// and cryptographic SHA-256 verification fingerprints.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';

/// Categorical completion state of an executed activity.
enum LearningActivityCompletionState {
  /// All planned questions/tasks were presented and answered/skipped.
  completed,

  /// Session/activity was concluded before all questions were answered.
  partial,

  /// Activity was explicitly abandoned without meaningful progress.
  abandoned;

  bool get isCompleted => this == LearningActivityCompletionState.completed;
  bool get isPartial => this == LearningActivityCompletionState.partial;
  bool get isAbandoned => this == LearningActivityCompletionState.abandoned;
}

/// Normalized, activity-independent learning performance outcome.
@immutable
class LearningActivityOutcome {
  /// Unique identifier of the completed activity.
  final String activityId;

  /// Pedagogical activity type executed (continuation, remediation, review, reinforcement, advancement, complete).
  final LearningDecisionType activityType;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Underlying practice session identifier, if activity was session-backed.
  final String? sessionId;

  /// Total number of questions scheduled/presented during the activity.
  final int questionsPresented;

  /// Total questions submitted with an answer.
  final int questionsAttempted;

  /// Total questions answered correctly.
  final int correctAnswers;

  /// Total questions answered incorrectly.
  final int incorrectAnswers;

  /// Total questions explicitly skipped.
  final int skippedAnswers;

  /// Questions presented but left unanswered.
  final int unansweredCount;

  /// Normalized score in [0.0, 1.0]. Guaranteed not NaN.
  final double score;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Proportion of scheduled questions processed (attempted + skipped) in [0.0, 1.0].
  final double completionRate;

  /// Categorical completion state.
  final LearningActivityCompletionState completionState;

  /// Cumulative duration spent across the activity in seconds.
  final int totalDurationSeconds;

  /// Syllabus topic performance breakdown (topic -> evidence summary).
  final Map<String, dynamic> topicEvidence;

  /// Learning objective performance breakdown (objectiveId -> evidence summary).
  final Map<String, dynamic> objectiveEvidence;

  /// Remedial lesson evidence if this was a remediation activity.
  final Map<String, dynamic>? remedialEvidence;

  /// UTC timestamp when activity execution concluded.
  final DateTime completedAt;

  /// Schema version of the normalized outcome contract.
  final int outcomeRevision;

  /// SHA-256 cryptographic verification fingerprint.
  final String fingerprint;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  const LearningActivityOutcome._({
    required this.activityId,
    required this.activityType,
    required this.learnerId,
    required this.examId,
    this.sessionId,
    required this.questionsPresented,
    required this.questionsAttempted,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.unansweredCount,
    required this.score,
    this.accuracy,
    this.accuracyPercentage,
    required this.completionRate,
    required this.completionState,
    required this.totalDurationSeconds,
    required this.topicEvidence,
    required this.objectiveEvidence,
    this.remedialEvidence,
    required this.completedAt,
    required this.outcomeRevision,
    required this.fingerprint,
    required this.metadata,
  });

  /// Factory constructor computing mathematically safe metrics and deterministic fingerprint.
  factory LearningActivityOutcome.calculate({
    required String activityId,
    required LearningDecisionType activityType,
    required String learnerId,
    required String examId,
    String? sessionId,
    required int questionsPresented,
    required int questionsAttempted,
    required int correctAnswers,
    required int incorrectAnswers,
    required int skippedAnswers,
    int? unansweredCount,
    LearningActivityCompletionState? completionState,
    int totalDurationSeconds = 0,
    Map<String, dynamic>? topicEvidence,
    Map<String, dynamic>? objectiveEvidence,
    Map<String, dynamic>? remedialEvidence,
    DateTime? completedAt,
    int outcomeRevision = 1,
    Map<String, dynamic>? metadata,
  }) {
    if (activityId.trim().isEmpty) {
      throw ArgumentError('activityId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (questionsPresented < 0) {
      throw ArgumentError('questionsPresented cannot be negative');
    }
    if (questionsAttempted < 0) {
      throw ArgumentError('questionsAttempted cannot be negative');
    }
    if (correctAnswers < 0) {
      throw ArgumentError('correctAnswers cannot be negative');
    }
    if (incorrectAnswers < 0) {
      throw ArgumentError('incorrectAnswers cannot be negative');
    }
    if (skippedAnswers < 0) {
      throw ArgumentError('skippedAnswers cannot be negative');
    }

    final effectiveUnanswered = unansweredCount ??
        (questionsPresented - (questionsAttempted + skippedAnswers))
            .clamp(0, questionsPresented);

    // Mathematically safe metrics
    final double safeScore;
    if (questionsPresented == 0) {
      safeScore = (activityType == LearningDecisionType.complete) ? 1.0 : 0.0;
    } else {
      safeScore = (correctAnswers / questionsPresented).clamp(0.0, 1.0);
    }

    final double? safeAccuracy;
    final double? safeAccuracyPct;
    if (questionsAttempted == 0) {
      safeAccuracy = null;
      safeAccuracyPct = null;
    } else {
      final acc = (correctAnswers / questionsAttempted).clamp(0.0, 1.0);
      safeAccuracy = acc;
      safeAccuracyPct = (acc * 100.0).clamp(0.0, 100.0);
    }

    final double safeCompletionRate;
    if (questionsPresented == 0) {
      safeCompletionRate = 1.0;
    } else {
      safeCompletionRate =
          ((questionsAttempted + skippedAnswers) / questionsPresented)
              .clamp(0.0, 1.0);
    }

    final effectiveState = completionState ??
        (safeCompletionRate >= 1.0
            ? LearningActivityCompletionState.completed
            : LearningActivityCompletionState.partial);

    final effectiveDate = (completedAt ?? DateTime.now()).toUtc();
    final effectiveTopic =
        Map<String, dynamic>.unmodifiable(topicEvidence ?? {});
    final effectiveObjective =
        Map<String, dynamic>.unmodifiable(objectiveEvidence ?? {});
    final effectiveRemedial = remedialEvidence != null
        ? Map<String, dynamic>.unmodifiable(remedialEvidence)
        : null;
    final effectiveMetadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

    // Compute deterministic SHA-256 fingerprint
    final payload = jsonEncode({
      'activityId': activityId.trim(),
      'activityType': activityType.name,
      'learnerId': learnerId.trim(),
      'examId': examId.trim().toLowerCase(),
      'sessionId': sessionId?.trim(),
      'questionsPresented': questionsPresented,
      'questionsAttempted': questionsAttempted,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'skippedAnswers': skippedAnswers,
      'unansweredCount': effectiveUnanswered,
      'score': safeScore,
      'accuracy': safeAccuracy,
      'completionRate': safeCompletionRate,
      'completionState': effectiveState.name,
      'totalDurationSeconds': totalDurationSeconds,
      'completedAt': effectiveDate.toIso8601String(),
      'outcomeRevision': outcomeRevision,
    });
    final computedFingerprint = sha256.convert(utf8.encode(payload)).toString();

    return LearningActivityOutcome._(
      activityId: activityId.trim(),
      activityType: activityType,
      learnerId: learnerId.trim(),
      examId: examId.trim().toLowerCase(),
      sessionId: sessionId?.trim(),
      questionsPresented: questionsPresented,
      questionsAttempted: questionsAttempted,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      skippedAnswers: skippedAnswers,
      unansweredCount: effectiveUnanswered,
      score: safeScore,
      accuracy: safeAccuracy,
      accuracyPercentage: safeAccuracyPct,
      completionRate: safeCompletionRate,
      completionState: effectiveState,
      totalDurationSeconds: totalDurationSeconds.clamp(0, 86400 * 7),
      topicEvidence: effectiveTopic,
      objectiveEvidence: effectiveObjective,
      remedialEvidence: effectiveRemedial,
      completedAt: effectiveDate,
      outcomeRevision: outcomeRevision,
      fingerprint: computedFingerprint,
      metadata: effectiveMetadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'activityType': activityType.name,
        'learnerId': learnerId,
        'examId': examId,
        if (sessionId != null) 'sessionId': sessionId,
        'questionsPresented': questionsPresented,
        'questionsAttempted': questionsAttempted,
        'correctAnswers': correctAnswers,
        'incorrectAnswers': incorrectAnswers,
        'skippedAnswers': skippedAnswers,
        'unansweredCount': unansweredCount,
        'score': score,
        'accuracy': accuracy,
        'accuracyPercentage': accuracyPercentage,
        'completionRate': completionRate,
        'completionState': completionState.name,
        'totalDurationSeconds': totalDurationSeconds,
        'topicEvidence': topicEvidence,
        'objectiveEvidence': objectiveEvidence,
        if (remedialEvidence != null) 'remedialEvidence': remedialEvidence,
        'completedAt': completedAt.toIso8601String(),
        'outcomeRevision': outcomeRevision,
        'fingerprint': fingerprint,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory LearningActivityOutcome.fromJson(Map<String, dynamic> json) =>
      LearningActivityOutcome._(
        activityId: json['activityId'] as String? ?? '',
        activityType: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['activityType'],
          orElse: () => LearningDecisionType.advancement,
        ),
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        sessionId: json['sessionId'] as String?,
        questionsPresented: (json['questionsPresented'] as num?)?.toInt() ?? 0,
        questionsAttempted: (json['questionsAttempted'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
        incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt() ?? 0,
        skippedAnswers: (json['skippedAnswers'] as num?)?.toInt() ?? 0,
        unansweredCount: (json['unansweredCount'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        completionState: LearningActivityCompletionState.values.firstWhere(
          (s) => s.name == json['completionState'],
          orElse: () => LearningActivityCompletionState.completed,
        ),
        totalDurationSeconds:
            (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
        topicEvidence: Map<String, dynamic>.unmodifiable(
            json['topicEvidence'] as Map<String, dynamic>? ?? const {}),
        objectiveEvidence: Map<String, dynamic>.unmodifiable(
            json['objectiveEvidence'] as Map<String, dynamic>? ?? const {}),
        remedialEvidence: json['remedialEvidence'] != null
            ? Map<String, dynamic>.unmodifiable(
                json['remedialEvidence'] as Map<String, dynamic>)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : DateTime.now().toUtc(),
        outcomeRevision: (json['outcomeRevision'] as num?)?.toInt() ?? 1,
        fingerprint: json['fingerprint'] as String? ?? '',
        metadata: Map<String, dynamic>.unmodifiable(
            json['metadata'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  String toString() =>
      'LearningActivityOutcome($activityId, type=${activityType.name}, score=$score, accuracy=$accuracy, status=${completionState.name})';
}
