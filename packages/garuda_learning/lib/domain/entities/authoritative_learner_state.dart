/// Authoritative Learner State Domain Entity (TITAN-KO-038.0 P38).
///
/// Encapsulates the immutable snapshot of a learner's authoritative progress state,
/// processed session history, and cryptographic fingerprint across a specific exam.
///
/// Invariants:
/// - Immutable domain models and deeply unmodifiable collections.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Strict multi-exam and learner isolation.
/// - Deterministic canonical SHA-256 state fingerprinting.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../../repository/progress_repository.dart';
import 'learner_progress.dart';

/// Immutable snapshot representing authoritative learner state for reconciliation.
@immutable
class AuthoritativeLearnerState {
  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Progress records mapped by canonical learning objective ID (keys sorted deterministically).
  final Map<String, LearnerProgress> progressMap;

  /// Set of session IDs already reconciled into this authoritative state (for idempotency).
  final Set<String> processedSessionIds;

  /// Authoritative timestamp when this state was last updated (caller-supplied).
  final DateTime lastUpdatedAt;

  /// Deterministic SHA-256 fingerprint identifying this exact authoritative state.
  final String stateFingerprint;

  AuthoritativeLearnerState({
    required String learnerId,
    required String examId,
    required Map<String, LearnerProgress> progressMap,
    Set<String>? processedSessionIds,
    required this.lastUpdatedAt,
    String? stateFingerprint,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
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
        stateFingerprint = stateFingerprint ??
            _computeFingerprint(
              learnerId.trim(),
              examId.trim().toLowerCase(),
              progressMap,
              processedSessionIds ?? const <String>{},
              lastUpdatedAt,
            ) {
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for AuthoritativeLearnerState');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for AuthoritativeLearnerState');
    }
    if (this.stateFingerprint.trim().isEmpty) {
      throw ArgumentError('stateFingerprint cannot be empty');
    }
  }

  /// Factory creating an initial empty authoritative state for a learner and exam.
  factory AuthoritativeLearnerState.empty({
    required String learnerId,
    required String examId,
    required DateTime createdAt,
  }) =>
      AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        processedSessionIds: const {},
        lastUpdatedAt: createdAt.toUtc(),
      );

  /// Factory constructing state from a list of [LearnerProgress] records.
  factory AuthoritativeLearnerState.fromProgressList({
    required String learnerId,
    required String examId,
    required List<LearnerProgress> progressList,
    Set<String>? processedSessionIds,
    required DateTime lastUpdatedAt,
  }) {
    final map = SplayTreeMap<String, LearnerProgress>();
    for (final p in progressList) {
      map[p.objectiveId] = p;
    }
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: map,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt.toUtc(),
    );
  }

  /// Factory constructing state directly from a [ProgressRepository].
  ///
  /// Reuses existing P18/P19 persistence repository representation rather than creating
  /// a competing model.
  factory AuthoritativeLearnerState.fromRepository({
    required ProgressRepository repository,
    required String learnerId,
    required String examId,
    Set<String>? processedSessionIds,
    required DateTime lastUpdatedAt,
  }) {
    final progressList = repository.getProgressForLearner(learnerId);
    return AuthoritativeLearnerState.fromProgressList(
      learnerId: learnerId,
      examId: examId,
      progressList: progressList,
      processedSessionIds: processedSessionIds,
      lastUpdatedAt: lastUpdatedAt,
    );
  }

  /// Whether this authoritative state has already incorporated the given practice session.
  bool hasProcessedSession(String sessionId) =>
      processedSessionIds.contains(sessionId.trim());

  /// Retrieves progress for a given objective ID, or null if absent.
  LearnerProgress? getProgress(String objectiveId) => progressMap[objectiveId];

  static String _computeFingerprint(
    String learnerId,
    String examId,
    Map<String, LearnerProgress> progressMap,
    Set<String> processedSessionIds,
    DateTime lastUpdatedAt,
  ) {
    final sb = StringBuffer();
    sb.write('$learnerId|$examId|${lastUpdatedAt.toUtc().toIso8601String()}|');

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

    return sha256.convert(utf8.encode(sb.toString())).toString();
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'examId': examId,
        'progressMap': progressMap.map((k, v) => MapEntry(k, v.toJson())),
        'processedSessionIds': processedSessionIds.toList(),
        'lastUpdatedAt': lastUpdatedAt.toUtc().toIso8601String(),
        'stateFingerprint': stateFingerprint,
      };

  factory AuthoritativeLearnerState.fromJson(Map<String, dynamic> json) =>
      AuthoritativeLearnerState(
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        progressMap: (json['progressMap'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(
                k, LearnerProgress.fromJson(v as Map<String, dynamic>))),
        processedSessionIds:
            Set<String>.from(json['processedSessionIds'] as List? ?? const []),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String).toUtc(),
        stateFingerprint: json['stateFingerprint'] as String?,
      );

  @override
  String toString() =>
      'AuthoritativeLearnerState(learner: $learnerId, exam: $examId, objectives: ${progressMap.length}, sessions: ${processedSessionIds.length}, fp: ${stateFingerprint.substring(0, 8)}...)';
}
