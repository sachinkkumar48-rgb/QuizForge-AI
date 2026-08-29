/// Study Plan Entity (TITAN-KO-024.0 P24).
///
/// Immutable domain aggregate representing a complete multi-day or weekly
/// study plan generated deterministically by the study planning engine.
///
/// Educational Safety Principles:
/// - Represents scheduling decisions, NOT learner judgments or guarantees.
/// - Milestone warnings are factual statements of capacity constraints.
/// - All timestamps are strictly UTC. No [DateTime.now()].
library;

import 'package:meta/meta.dart';

import 'daily_study_agenda.dart';
import 'study_plan_request.dart';

/// Immutable complete study plan spanning a designated planning window.
@immutable
class StudyPlan {
  /// Unique identifier for this study plan instance.
  final String planId;

  /// Input request specification that generated this plan.
  final StudyPlanRequest request;

  /// Chronological sequence of daily study agendas, sorted by date ascending.
  final List<DailyStudyAgenda> dailyAgendas;

  /// Count of candidate objectives that could not be scheduled due to capacity limits.
  final int unallocatedObjectivesCount;

  /// Optional factual advisory when target milestone date cannot be fully accommodated.
  final String? milestoneWarning;

  /// UTC timestamp when this plan was deterministically generated.
  final DateTime generatedAt;

  /// Diagnostic metadata.
  final Map<String, dynamic> metadata;

  StudyPlan({
    required this.planId,
    required this.request,
    required List<DailyStudyAgenda> dailyAgendas,
    this.unallocatedObjectivesCount = 0,
    this.milestoneWarning,
    required DateTime generatedAt,
    Map<String, dynamic>? metadata,
  })  : generatedAt = generatedAt.toUtc(),
        dailyAgendas = List<DailyStudyAgenda>.unmodifiable(
          _sortAgendas(dailyAgendas),
        ),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (planId.trim().isEmpty) {
      throw ArgumentError('PlanId cannot be empty for StudyPlan');
    }
    if (unallocatedObjectivesCount < 0) {
      throw ArgumentError('UnallocatedObjectivesCount cannot be negative');
    }
  }

  /// Sorts daily agendas chronologically by UTC date.
  static List<DailyStudyAgenda> _sortAgendas(List<DailyStudyAgenda> raw) {
    final list = List<DailyStudyAgenda>.from(raw);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Target learner identifier derived from [request].
  String get learnerId => request.learnerId;

  /// Total number of days in the generated plan.
  int get totalDays => dailyAgendas.length;

  /// Total duration in minutes allocated across all daily agendas.
  int get totalAllocatedMinutes =>
      dailyAgendas.fold<int>(0, (sum, agenda) => sum + agenda.allocatedMinutes);

  /// Total number of individual study sessions scheduled across all days.
  int get totalAllocatedSessions =>
      dailyAgendas.fold<int>(0, (sum, agenda) => sum + agenda.sessionCount);

  /// Whether this plan has an active milestone capacity advisory.
  bool get hasMilestoneWarning =>
      milestoneWarning != null && milestoneWarning!.trim().isNotEmpty;

  /// Set of all unique P17 objective IDs scheduled anywhere within this plan.
  Set<String> get allScheduledObjectiveIds {
    final set = <String>{};
    for (final agenda in dailyAgendas) {
      for (final item in agenda.items) {
        set.add(item.objectiveId);
      }
    }
    return set;
  }

  /// Checks if a specific objective ID has been scheduled anywhere in this plan.
  bool isObjectiveScheduled(String objectiveId) =>
      allScheduledObjectiveIds.contains(objectiveId);

  /// Retrieves the [DailyStudyAgenda] for the specified [date], matching on calendar day.
  DailyStudyAgenda? agendaForDate(DateTime date) {
    final utc = date.toUtc();
    for (final agenda in dailyAgendas) {
      if (agenda.date.year == utc.year &&
          agenda.date.month == utc.month &&
          agenda.date.day == utc.day) {
        return agenda;
      }
    }
    return null;
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'planId': planId,
        'request': request.toJson(),
        'dailyAgendas': dailyAgendas.map((e) => e.toJson()).toList(),
        'unallocatedObjectivesCount': unallocatedObjectivesCount,
        if (milestoneWarning != null) 'milestoneWarning': milestoneWarning,
        'generatedAt': generatedAt.toIso8601String(),
        'totalAllocatedMinutes': totalAllocatedMinutes,
        'totalAllocatedSessions': totalAllocatedSessions,
        'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        planId: json['planId'] as String? ?? '',
        request: StudyPlanRequest.fromJson(
          Map<String, dynamic>.from(json['request'] as Map? ?? const {}),
        ),
        dailyAgendas: (json['dailyAgendas'] as List<dynamic>?)
                ?.map(
                    (e) => DailyStudyAgenda.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <DailyStudyAgenda>[],
        unallocatedObjectivesCount:
            (json['unallocatedObjectivesCount'] as num?)?.toInt() ?? 0,
        milestoneWarning: json['milestoneWarning'] as String?,
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyPlan &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          request == other.request &&
          unallocatedObjectivesCount == other.unallocatedObjectivesCount &&
          milestoneWarning == other.milestoneWarning &&
          generatedAt == other.generatedAt &&
          _listEquals(dailyAgendas, other.dailyAgendas);

  static bool _listEquals(List<DailyStudyAgenda> a, List<DailyStudyAgenda> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        planId,
        request,
        unallocatedObjectivesCount,
        milestoneWarning,
        generatedAt,
        Object.hashAll(dailyAgendas),
      );

  @override
  String toString() =>
      'StudyPlan(id: $planId, learner: $learnerId, days: $totalDays, '
      'sessions: $totalAllocatedSessions, totalMinutes: ${totalAllocatedMinutes}min)';
}
