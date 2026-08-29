/// Study Time Budget Entity (TITAN-KO-024.0 P24).
///
/// Immutable value object capturing the learner's daily available study time
/// and session capacity constraints for use by the [StudyPlannerService].
///
/// Educational Safety Principles:
/// - Budget constraints are scheduling decisions, not learner-ability judgments.
/// - Bounds are validated to prevent degenerate plans (0-minute budgets, etc.).
/// - No [DateTime.now()]. All timestamps are explicit.
library;

import 'package:meta/meta.dart';

/// Immutable daily study capacity budget for one learner.
@immutable
class StudyTimeBudget {
  /// Minimum valid daily available minutes.
  static const int minDailyMinutes = 1;

  /// Maximum valid daily available minutes (8 hours).
  static const int maxDailyMinutes = 480;

  /// Minimum valid preferred session duration in minutes.
  static const int minSessionMinutes = 5;

  /// Target learner identifier.
  final String learnerId;

  /// Total study time available to the learner per day, in minutes.
  /// Validated range: [1, 480].
  final int dailyAvailableMinutes;

  /// Preferred duration of each study session block, in minutes.
  /// Validated: >= [minSessionMinutes] and <= [dailyAvailableMinutes].
  final int preferredSessionDurationMinutes;

  /// Maximum number of study sessions the learner accepts per day.
  /// Validated: >= 1.
  final int maxSessionsPerDay;

  /// UTC timestamp from which this budget is effective.
  final DateTime effectiveFrom;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  StudyTimeBudget({
    required this.learnerId,
    required this.dailyAvailableMinutes,
    required this.preferredSessionDurationMinutes,
    required this.maxSessionsPerDay,
    required DateTime effectiveFrom,
    Map<String, dynamic>? metadata,
  })  : effectiveFrom = effectiveFrom.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for StudyTimeBudget');
    }
    if (dailyAvailableMinutes < minDailyMinutes ||
        dailyAvailableMinutes > maxDailyMinutes) {
      throw ArgumentError(
          'DailyAvailableMinutes ($dailyAvailableMinutes) must be between '
          '$minDailyMinutes and $maxDailyMinutes');
    }
    if (preferredSessionDurationMinutes < minSessionMinutes) {
      throw ArgumentError(
          'PreferredSessionDurationMinutes ($preferredSessionDurationMinutes) '
          'must be at least $minSessionMinutes');
    }
    if (preferredSessionDurationMinutes > dailyAvailableMinutes) {
      throw ArgumentError(
          'PreferredSessionDurationMinutes ($preferredSessionDurationMinutes) '
          'cannot exceed dailyAvailableMinutes ($dailyAvailableMinutes)');
    }
    if (maxSessionsPerDay < 1) {
      throw ArgumentError(
          'MaxSessionsPerDay ($maxSessionsPerDay) must be at least 1');
    }
  }

  /// Effective daily capacity in minutes considering session count ceiling.
  /// = min(dailyAvailableMinutes, maxSessionsPerDay * preferredSessionDurationMinutes)
  int get effectiveDailyCapacityMinutes =>
      (maxSessionsPerDay * preferredSessionDurationMinutes)
          .clamp(0, dailyAvailableMinutes);

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'dailyAvailableMinutes': dailyAvailableMinutes,
        'preferredSessionDurationMinutes': preferredSessionDurationMinutes,
        'maxSessionsPerDay': maxSessionsPerDay,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory StudyTimeBudget.fromJson(Map<String, dynamic> json) =>
      StudyTimeBudget(
        learnerId: json['learnerId'] as String? ?? '',
        dailyAvailableMinutes:
            json['dailyAvailableMinutes'] as int? ?? minDailyMinutes,
        preferredSessionDurationMinutes:
            json['preferredSessionDurationMinutes'] as int? ??
                minSessionMinutes,
        maxSessionsPerDay: json['maxSessionsPerDay'] as int? ?? 1,
        effectiveFrom: json['effectiveFrom'] != null
            ? DateTime.parse(json['effectiveFrom'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTimeBudget &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          dailyAvailableMinutes == other.dailyAvailableMinutes &&
          preferredSessionDurationMinutes ==
              other.preferredSessionDurationMinutes &&
          maxSessionsPerDay == other.maxSessionsPerDay &&
          effectiveFrom == other.effectiveFrom;

  @override
  int get hashCode => Object.hash(
        learnerId,
        dailyAvailableMinutes,
        preferredSessionDurationMinutes,
        maxSessionsPerDay,
        effectiveFrom,
      );

  @override
  String toString() => 'StudyTimeBudget(learnerId: $learnerId, '
      'daily: ${dailyAvailableMinutes}min, '
      'session: ${preferredSessionDurationMinutes}min, '
      'maxSessions: $maxSessionsPerDay)';
}
