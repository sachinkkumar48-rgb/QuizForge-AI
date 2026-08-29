/// Study Plan Request Entity (TITAN-KO-024.0 P24).
///
/// Immutable input value object capturing all decision inputs required for
/// deterministic study agenda generation by the [StudyPlannerService].
///
/// Educational Safety Principles:
/// - All timestamps must be explicit — no [DateTime.now()].
/// - Reversed planning windows are rejected at construction time.
/// - Milestone dates before the planning window are rejected.
/// - This entity does NOT invoke any evaluator, service, or scheduler.
library;

import 'package:meta/meta.dart';

import 'study_time_budget.dart';

/// Immutable input specification for one study plan generation request.
@immutable
class StudyPlanRequest {
  /// Target learner identifier.
  final String learnerId;

  /// UTC start date of the planning window (inclusive).
  final DateTime planningWindowStart;

  /// UTC end date of the planning window (inclusive).
  /// Must be >= [planningWindowStart].
  final DateTime planningWindowEnd;

  /// Optional target milestone or exam date in UTC.
  /// When provided, must be >= [planningWindowStart].
  final DateTime? targetMilestoneDate;

  /// Learner's daily study capacity constraints.
  final StudyTimeBudget timeBudget;

  /// Optional explicit set of objective IDs to scope the plan to.
  /// When null, the planner considers all available objectives.
  final List<String>? scopedObjectiveIds;

  /// Explicit UTC timestamp when this plan request was created.
  /// Must be provided by the caller — no [DateTime.now()].
  final DateTime requestedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  StudyPlanRequest({
    required this.learnerId,
    required DateTime planningWindowStart,
    required DateTime planningWindowEnd,
    DateTime? targetMilestoneDate,
    required this.timeBudget,
    List<String>? scopedObjectiveIds,
    required DateTime requestedAt,
    Map<String, dynamic>? metadata,
  })  : planningWindowStart = planningWindowStart.toUtc(),
        planningWindowEnd = planningWindowEnd.toUtc(),
        targetMilestoneDate = targetMilestoneDate?.toUtc(),
        requestedAt = requestedAt.toUtc(),
        scopedObjectiveIds = scopedObjectiveIds != null
            ? List<String>.unmodifiable(scopedObjectiveIds)
            : null,
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for StudyPlanRequest');
    }
    final utcStart = planningWindowStart.toUtc();
    final utcEnd = planningWindowEnd.toUtc();
    if (utcEnd.isBefore(utcStart)) {
      throw ArgumentError(
          'PlanningWindowEnd cannot be before PlanningWindowStart');
    }
    final utcMilestone = targetMilestoneDate?.toUtc();
    if (utcMilestone != null && utcMilestone.isBefore(utcStart)) {
      throw ArgumentError(
          'TargetMilestoneDate cannot be before PlanningWindowStart');
    }
  }

  /// Total duration of the planning window.
  Duration get windowDuration =>
      planningWindowEnd.difference(planningWindowStart);

  /// Number of whole days in the planning window.
  int get windowDays => windowDuration.inDays + 1;

  /// Whether a milestone target has been set.
  bool get hasMilestoneTarget => targetMilestoneDate != null;

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'planningWindowStart': planningWindowStart.toIso8601String(),
        'planningWindowEnd': planningWindowEnd.toIso8601String(),
        if (targetMilestoneDate != null)
          'targetMilestoneDate': targetMilestoneDate!.toIso8601String(),
        'timeBudget': timeBudget.toJson(),
        if (scopedObjectiveIds != null)
          'scopedObjectiveIds': scopedObjectiveIds,
        'requestedAt': requestedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory StudyPlanRequest.fromJson(Map<String, dynamic> json) =>
      StudyPlanRequest(
        learnerId: json['learnerId'] as String? ?? '',
        planningWindowStart: json['planningWindowStart'] != null
            ? DateTime.parse(json['planningWindowStart'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        planningWindowEnd: json['planningWindowEnd'] != null
            ? DateTime.parse(json['planningWindowEnd'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        targetMilestoneDate: json['targetMilestoneDate'] != null
            ? DateTime.parse(json['targetMilestoneDate'] as String).toUtc()
            : null,
        timeBudget: StudyTimeBudget.fromJson(
          json['timeBudget'] as Map<String, dynamic>? ??
              const <String, dynamic>{},
        ),
        scopedObjectiveIds:
            (json['scopedObjectiveIds'] as List<dynamic>?)?.cast<String>(),
        requestedAt: json['requestedAt'] != null
            ? DateTime.parse(json['requestedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyPlanRequest &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          planningWindowStart == other.planningWindowStart &&
          planningWindowEnd == other.planningWindowEnd &&
          targetMilestoneDate == other.targetMilestoneDate &&
          timeBudget == other.timeBudget &&
          _listEquals(scopedObjectiveIds, other.scopedObjectiveIds) &&
          requestedAt == other.requestedAt;

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        learnerId,
        planningWindowStart,
        planningWindowEnd,
        targetMilestoneDate,
        timeBudget,
        requestedAt,
      );

  @override
  String toString() => 'StudyPlanRequest(learnerId: $learnerId, '
      'window: ${planningWindowStart.toIso8601String()} → '
      '${planningWindowEnd.toIso8601String()}, '
      'budget: ${timeBudget.dailyAvailableMinutes}min/day)';
}
