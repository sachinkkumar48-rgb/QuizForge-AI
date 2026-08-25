/// Learning Velocity Profile Entity (TITAN-KO-023.0 P23 Stage 2).
///
/// Immutable domain model capturing observed study throughput, attempt frequency,
/// and objective achievement rate over an explicit time window for ONE learner.
///
/// Educational Safety Principles:
/// - Represents strictly descriptive metrics of observed study throughput,
///   never inferring learner intelligence, innate ability, or exam readiness.
/// - Safely handles zero attempts, zero sessions, zero objectives, and zero duration
///   without producing NaN, Infinity, or unhandled exceptions.
/// - Deterministic timestamps: requires explicit [windowStart], [windowEnd], and [evaluatedAt].
/// - Zero [DateTime.now] invocations in domain logic.
library;

import 'package:meta/meta.dart';

@immutable
class LearningVelocityProfile {
  /// Default minimum count of attempts required in the time window for sufficient evidence.
  static const int defaultEvidenceThreshold = 5;

  /// Target learner identifier.
  final String learnerId;

  /// Optional curriculum scope identifier (e.g. framework ID or domain ID).
  final String? scopeId;

  /// Start timestamp of the measured time window in UTC.
  final DateTime windowStart;

  /// End timestamp of the measured time window in UTC.
  final DateTime windowEnd;

  /// Total count of learning sessions executed within the window.
  final int sessionsCount;

  /// Total count of question attempts submitted within the window.
  final int attemptsCount;

  /// Total count of correct question attempts submitted within the window.
  final int correctAttemptsCount;

  /// Total count of learning objectives that transitioned to `achieved` within the window.
  final int newlyAchievedObjectivesCount;

  /// Cumulative active study duration recorded in sessions within the window.
  final Duration activeStudyDuration;

  /// Observed raw accuracy ratio across attempts in the window in range [0.0, 1.0],
  /// or null if zero attempts were submitted.
  final double? observedAccuracy;

  /// Observed attempt throughput rate per hour of active study duration,
  /// or null if active study duration is zero or zero attempts were made.
  final double? attemptsPerHour;

  /// Observed rate of newly achieved objectives per 24 hours of elapsed window time,
  /// or null if window duration is zero.
  final double? objectivesAchievedPerDay;

  /// Whether sufficient attempt activity exists within the window to produce meaningful velocity metrics.
  final bool hasSufficientEvidence;

  /// Minimum attempt threshold required for sufficient evidence in this window.
  final int minimumEvidenceThreshold;

  /// UTC timestamp when this velocity profile was evaluated.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  LearningVelocityProfile({
    required this.learnerId,
    this.scopeId,
    required DateTime windowStart,
    required DateTime windowEnd,
    required this.sessionsCount,
    required this.attemptsCount,
    required this.correctAttemptsCount,
    required this.newlyAchievedObjectivesCount,
    this.activeStudyDuration = Duration.zero,
    double? observedAccuracy,
    double? attemptsPerHour,
    double? objectivesAchievedPerDay,
    bool? hasSufficientEvidence,
    this.minimumEvidenceThreshold = defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : windowStart = windowStart.toUtc(),
        windowEnd = windowEnd.toUtc(),
        evaluatedAt = evaluatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}),
        observedAccuracy = attemptsCount == 0
            ? null
            : (observedAccuracy ??
                    (correctAttemptsCount / attemptsCount).clamp(0.0, 1.0))
                .clamp(0.0, 1.0),
        attemptsPerHour =
            (attemptsCount == 0 || activeStudyDuration.inSeconds == 0)
                ? null
                : (attemptsPerHour ??
                    (attemptsCount / (activeStudyDuration.inSeconds / 3600.0))),
        objectivesAchievedPerDay =
            (windowEnd.difference(windowStart).inSeconds <= 0)
                ? null
                : (objectivesAchievedPerDay ??
                    (newlyAchievedObjectivesCount /
                        (windowEnd.difference(windowStart).inSeconds /
                            86400.0))),
        hasSufficientEvidence = hasSufficientEvidence ??
            (attemptsCount >= minimumEvidenceThreshold &&
                activeStudyDuration.inSeconds > 0) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError(
          'LearnerId cannot be empty for LearningVelocityProfile');
    }
    if (this.windowEnd.isBefore(this.windowStart)) {
      throw ArgumentError('WindowEnd cannot be before WindowStart');
    }
    if (sessionsCount < 0) {
      throw ArgumentError('SessionsCount cannot be negative');
    }
    if (attemptsCount < 0) {
      throw ArgumentError('AttemptsCount cannot be negative');
    }
    if (correctAttemptsCount < 0 || correctAttemptsCount > attemptsCount) {
      throw ArgumentError(
          'CorrectAttemptsCount ($correctAttemptsCount) must be between 0 and attemptsCount ($attemptsCount)');
    }
    if (newlyAchievedObjectivesCount < 0) {
      throw ArgumentError('NewlyAchievedObjectivesCount cannot be negative');
    }
    if (activeStudyDuration.isNegative) {
      throw ArgumentError('ActiveStudyDuration cannot be negative');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }
  }

  /// Total elapsed duration of the measured time window.
  Duration get totalWindowDuration => windowEnd.difference(windowStart);

  /// Average active duration per completed session in the window,
  /// or [Duration.zero] if [sessionsCount] is zero.
  Duration get averageSessionDuration => sessionsCount == 0
      ? Duration.zero
      : Duration(seconds: activeStudyDuration.inSeconds ~/ sessionsCount);

  /// Serializes velocity profile to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        if (scopeId != null) 'scopeId': scopeId,
        'windowStart': windowStart.toIso8601String(),
        'windowEnd': windowEnd.toIso8601String(),
        'sessionsCount': sessionsCount,
        'attemptsCount': attemptsCount,
        'correctAttemptsCount': correctAttemptsCount,
        'newlyAchievedObjectivesCount': newlyAchievedObjectivesCount,
        'activeStudyDurationSeconds': activeStudyDuration.inSeconds,
        if (observedAccuracy != null) 'observedAccuracy': observedAccuracy,
        if (attemptsPerHour != null) 'attemptsPerHour': attemptsPerHour,
        if (objectivesAchievedPerDay != null)
          'objectivesAchievedPerDay': objectivesAchievedPerDay,
        'hasSufficientEvidence': hasSufficientEvidence,
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes velocity profile from JSON map.
  factory LearningVelocityProfile.fromJson(Map<String, dynamic> json) =>
      LearningVelocityProfile(
        learnerId: json['learnerId'] as String? ?? '',
        scopeId: json['scopeId'] as String?,
        windowStart: json['windowStart'] != null
            ? DateTime.parse(json['windowStart'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        windowEnd: json['windowEnd'] != null
            ? DateTime.parse(json['windowEnd'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        sessionsCount: json['sessionsCount'] as int? ?? 0,
        attemptsCount: json['attemptsCount'] as int? ?? 0,
        correctAttemptsCount: json['correctAttemptsCount'] as int? ?? 0,
        newlyAchievedObjectivesCount:
            json['newlyAchievedObjectivesCount'] as int? ?? 0,
        activeStudyDuration: Duration(
          seconds: json['activeStudyDurationSeconds'] as int? ?? 0,
        ),
        observedAccuracy: (json['observedAccuracy'] as num?)?.toDouble(),
        attemptsPerHour: (json['attemptsPerHour'] as num?)?.toDouble(),
        objectivesAchievedPerDay:
            (json['objectivesAchievedPerDay'] as num?)?.toDouble(),
        hasSufficientEvidence: json['hasSufficientEvidence'] as bool?,
        minimumEvidenceThreshold: json['minimumEvidenceThreshold'] as int? ??
            defaultEvidenceThreshold,
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningVelocityProfile &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          scopeId == other.scopeId &&
          windowStart == other.windowStart &&
          windowEnd == other.windowEnd &&
          sessionsCount == other.sessionsCount &&
          attemptsCount == other.attemptsCount &&
          correctAttemptsCount == other.correctAttemptsCount &&
          newlyAchievedObjectivesCount == other.newlyAchievedObjectivesCount &&
          activeStudyDuration == other.activeStudyDuration &&
          observedAccuracy == other.observedAccuracy &&
          attemptsPerHour == other.attemptsPerHour &&
          objectivesAchievedPerDay == other.objectivesAchievedPerDay &&
          hasSufficientEvidence == other.hasSufficientEvidence &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold &&
          evaluatedAt == other.evaluatedAt;

  @override
  int get hashCode => Object.hash(
        learnerId,
        scopeId,
        windowStart,
        windowEnd,
        sessionsCount,
        attemptsCount,
        correctAttemptsCount,
        newlyAchievedObjectivesCount,
        activeStudyDuration,
        observedAccuracy,
        attemptsPerHour,
        objectivesAchievedPerDay,
        hasSufficientEvidence,
        minimumEvidenceThreshold,
        evaluatedAt,
      );

  @override
  String toString() =>
      'LearningVelocityProfile(learnerId: $learnerId, attempts: $attemptsCount, '
      'sessions: $sessionsCount, achieved: $newlyAchievedObjectivesCount, '
      'accuracy: ${observedAccuracy?.toStringAsFixed(2) ?? "none"}, '
      'sufficientEvidence: $hasSufficientEvidence)';
}
