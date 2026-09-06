/// Adaptive Continuation Feedback Domain Contract (TITAN-KO-044.0 P44).
///
/// Complete, typed pedagogical feedback bundle communicating objective progression,
/// demonstrated strengths, diagnosed weak spots, overall exam readiness, and the
/// deterministic next recommended action to the learner and engine.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'mastery_continuation_audit_trail.dart';
import 'next_learning_action.dart';
import 'objective_progression_summary.dart';
import 'objective_weakness_detail.dart';

@immutable
class AdaptiveContinuationFeedback {
  /// Unique identifier of this feedback evaluation.
  final String feedbackId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (e.g. 'upsc', 'bpsc').
  final String examId;

  /// Authoritative learner state revision at the time of evaluation.
  final int authoritativeRevision;

  /// UTC timestamp of evaluation.
  final DateTime evaluatedAt;

  /// Completed activity ID that triggered this evaluation, if applicable.
  final String? activityId;

  /// Associated session ID, if applicable.
  final String? sessionId;

  /// Aggregate exam readiness index in range [0.0, 1.0].
  final double overallReadinessScore;

  /// Statistical confidence in range [0.0, 1.0] across all evaluated evidence.
  final double overallConfidence;

  /// Map of canonical objective ID to detailed progression summary.
  final Map<String, ObjectiveProgressionSummary> objectiveProgressions;

  /// Identifiers of learning objectives where competence or mastery was demonstrated.
  final List<String> demonstratedCompetencies;

  /// Detailed diagnostics for all identified weak areas or regressions.
  final List<ObjectiveWeaknessDetail> detectedWeaknesses;

  /// The deterministic next learning action recommended by the engine.
  final NextLearningAction recommendedAction;

  /// Diagnostic audit trail of all decision steps.
  final MasteryContinuationAuditTrail auditTrail;

  /// Deterministic SHA-256 canonical fingerprint.
  final String fingerprint;

  /// Deterministic idempotency key preventing duplicate processing.
  final String idempotencyKey;

  AdaptiveContinuationFeedback({
    required String feedbackId,
    required String learnerId,
    required String examId,
    required this.authoritativeRevision,
    required DateTime evaluatedAt,
    this.activityId,
    this.sessionId,
    required this.overallReadinessScore,
    required this.overallConfidence,
    required Map<String, ObjectiveProgressionSummary> objectiveProgressions,
    List<String>? demonstratedCompetencies,
    List<ObjectiveWeaknessDetail>? detectedWeaknesses,
    required this.recommendedAction,
    this.auditTrail = const MasteryContinuationAuditTrail.empty(),
    String? fingerprint,
    String? idempotencyKey,
  })  : feedbackId = feedbackId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        evaluatedAt = evaluatedAt.toUtc(),
        objectiveProgressions =
            Map<String, ObjectiveProgressionSummary>.unmodifiable(
          objectiveProgressions
                  is SplayTreeMap<String, ObjectiveProgressionSummary>
              ? objectiveProgressions
              : SplayTreeMap<String, ObjectiveProgressionSummary>.from(
                  objectiveProgressions),
        ),
        demonstratedCompetencies = List<String>.unmodifiable(
            demonstratedCompetencies ?? const <String>[]),
        detectedWeaknesses = List<ObjectiveWeaknessDetail>.unmodifiable(
            detectedWeaknesses ?? const <ObjectiveWeaknessDetail>[]),
        idempotencyKey = idempotencyKey ??
            _computeIdempotencyKey(
              learnerId.trim(),
              examId.trim().toLowerCase(),
              authoritativeRevision,
              activityId,
            ),
        fingerprint = fingerprint ??
            _computeFingerprint(
              feedbackId.trim(),
              learnerId.trim(),
              examId.trim().toLowerCase(),
              authoritativeRevision,
              overallReadinessScore,
              overallConfidence,
              objectiveProgressions,
              recommendedAction,
            ) {
    if (this.feedbackId.isEmpty) {
      throw ArgumentError('feedbackId cannot be empty');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (authoritativeRevision < 1) {
      throw ArgumentError('authoritativeRevision must be >= 1');
    }
    if (overallReadinessScore < 0.0 || overallReadinessScore > 1.0) {
      throw ArgumentError('overallReadinessScore must be in [0.0, 1.0]');
    }
    if (overallConfidence < 0.0 || overallConfidence > 1.0) {
      throw ArgumentError('overallConfidence must be in [0.0, 1.0]');
    }
  }

  static String _computeIdempotencyKey(
    String learnerId,
    String examId,
    int revision,
    String? activityId,
  ) {
    final act = activityId != null && activityId.trim().isNotEmpty
        ? activityId.trim()
        : 'direct';
    return 'mcont_${learnerId}_${examId}_rev${revision}_$act';
  }

  static String _computeFingerprint(
    String feedbackId,
    String learnerId,
    String examId,
    int revision,
    double readiness,
    double confidence,
    Map<String, ObjectiveProgressionSummary> progressions,
    NextLearningAction action,
  ) {
    final sortedKeys = progressions.keys.toList()..sort();
    final canonicalMap = <String, dynamic>{
      'feedbackId': feedbackId,
      'learnerId': learnerId,
      'examId': examId,
      'revision': revision,
      'readiness': double.parse(readiness.toStringAsFixed(4)),
      'confidence': double.parse(confidence.toStringAsFixed(4)),
      'progressions': sortedKeys
          .map((k) =>
              '${progressions[k]!.objectiveId}:${progressions[k]!.newStatus.name}:${progressions[k]!.totalAttempts}')
          .toList(),
      'action':
          '${action.actionType.name}:${action.priority.name}:${action.targetObjectiveId ?? ""}',
    };
    final bytes = utf8.encode(jsonEncode(canonicalMap));
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> toJson() => {
        'feedbackId': feedbackId,
        'learnerId': learnerId,
        'examId': examId,
        'authoritativeRevision': authoritativeRevision,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        if (activityId != null) 'activityId': activityId,
        if (sessionId != null) 'sessionId': sessionId,
        'overallReadinessScore': overallReadinessScore,
        'overallConfidence': overallConfidence,
        'objectiveProgressions': objectiveProgressions.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'demonstratedCompetencies': demonstratedCompetencies,
        'detectedWeaknesses':
            detectedWeaknesses.map((w) => w.toJson()).toList(),
        'recommendedAction': recommendedAction.toJson(),
        'auditTrail': auditTrail.toJson(),
        'fingerprint': fingerprint,
        'idempotencyKey': idempotencyKey,
      };

  factory AdaptiveContinuationFeedback.fromJson(Map<String, dynamic> json) {
    final progMap = <String, ObjectiveProgressionSummary>{};
    if (json['objectiveProgressions'] != null) {
      final rawMap = json['objectiveProgressions'] as Map;
      for (final entry in rawMap.entries) {
        progMap[entry.key as String] = ObjectiveProgressionSummary.fromJson(
            Map<String, dynamic>.from(entry.value as Map));
      }
    }

    final weakList = <ObjectiveWeaknessDetail>[];
    if (json['detectedWeaknesses'] != null) {
      final rawList = json['detectedWeaknesses'] as List;
      for (final item in rawList) {
        weakList.add(ObjectiveWeaknessDetail.fromJson(
            Map<String, dynamic>.from(item as Map)));
      }
    }

    final compList = <String>[];
    if (json['demonstratedCompetencies'] != null) {
      for (final item in json['demonstratedCompetencies'] as List) {
        compList.add(item as String);
      }
    }

    return AdaptiveContinuationFeedback(
      feedbackId: json['feedbackId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      authoritativeRevision: json['authoritativeRevision'] as int? ?? 1,
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activityId: json['activityId'] as String?,
      sessionId: json['sessionId'] as String?,
      overallReadinessScore:
          (json['overallReadinessScore'] as num?)?.toDouble() ?? 0.0,
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      objectiveProgressions: progMap,
      demonstratedCompetencies: compList,
      detectedWeaknesses: weakList,
      recommendedAction: NextLearningAction.fromJson(
          Map<String, dynamic>.from(json['recommendedAction'] as Map)),
      auditTrail: json['auditTrail'] != null
          ? MasteryContinuationAuditTrail.fromJson(
              json['auditTrail'] as List<dynamic>)
          : const MasteryContinuationAuditTrail.empty(),
      fingerprint: json['fingerprint'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveContinuationFeedback &&
          runtimeType == other.runtimeType &&
          feedbackId == other.feedbackId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          authoritativeRevision == other.authoritativeRevision &&
          fingerprint == other.fingerprint;

  @override
  int get hashCode => Object.hash(
        feedbackId,
        learnerId,
        examId,
        authoritativeRevision,
        fingerprint,
      );

  @override
  String toString() =>
      'AdaptiveContinuationFeedback(id: $feedbackId, rev: $authoritativeRevision, '
      'readiness: ${(overallReadinessScore * 100).toStringAsFixed(1)}%, action: ${recommendedAction.actionType.name})';
}
