/// Daily Study Agenda Entity (TITAN-KO-024.0 P24).
///
/// Immutable aggregate root representing the prioritized study schedule
/// for ONE learner on ONE specific calendar day.
///
/// Educational Safety Principles:
/// - Represents a scheduling allocation decision, NOT a learner judgment.
/// - Capacity limits are strictly enforced; remaining capacity cannot be negative.
/// - Items are deterministically sorted by [StudyAgendaItem.priorityRank].
/// - All timestamps are strictly UTC. No [DateTime.now()].
library;

import 'package:meta/meta.dart';

import 'study_agenda_item.dart';
import 'study_allocation_type.dart';

/// Immutable daily agenda containing scheduled study session slots for one day.
@immutable
class DailyStudyAgenda {
  /// Target learner identifier.
  final String learnerId;

  /// UTC calendar date of this agenda (normalized to midnight UTC).
  final DateTime date;

  /// Ordered list of study slots allocated for this day, sorted by priority rank.
  final List<StudyAgendaItem> items;

  /// Total available study time in minutes for this day.
  final int availableMinutes;

  /// Diagnostic metadata.
  final Map<String, dynamic> metadata;

  DailyStudyAgenda({
    required this.learnerId,
    required DateTime date,
    required List<StudyAgendaItem> items,
    required this.availableMinutes,
    Map<String, dynamic>? metadata,
  })  : date = DateTime.utc(
          date.toUtc().year,
          date.toUtc().month,
          date.toUtc().day,
        ),
        items = List<StudyAgendaItem>.unmodifiable(
          _sortItems(items),
        ),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for DailyStudyAgenda');
    }
    if (availableMinutes < 0) {
      throw ArgumentError('AvailableMinutes cannot be negative');
    }
  }

  /// Sorts items deterministically by priorityRank ascending, then objectiveId ascending.
  static List<StudyAgendaItem> _sortItems(List<StudyAgendaItem> raw) {
    final list = List<StudyAgendaItem>.from(raw);
    list.sort((a, b) {
      final rankCmp = a.priorityRank.compareTo(b.priorityRank);
      if (rankCmp != 0) return rankCmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });
    return list;
  }

  /// Total duration in minutes allocated across all agenda items.
  int get allocatedMinutes =>
      items.fold<int>(0, (sum, item) => sum + item.allocatedMinutes);

  /// Remaining study capacity in minutes for this day (bounded to >= 0).
  int get remainingCapacityMinutes =>
      (availableMinutes - allocatedMinutes).clamp(0, availableMinutes);

  /// Whether the daily available time has been completely exhausted.
  bool get isFull => allocatedMinutes >= availableMinutes;

  /// Total number of scheduled study sessions in this agenda.
  int get sessionCount => items.length;

  /// True if zero items are scheduled for this day.
  bool get isEmpty => items.isEmpty;

  /// True if at least one item is scheduled for this day.
  bool get isNotEmpty => items.isNotEmpty;

  /// Checks if [objectiveId] is scheduled in this day's agenda.
  bool containsObjective(String objectiveId) =>
      items.any((item) => item.objectiveId == objectiveId);

  /// Retrieves the scheduled item for [objectiveId], if present.
  StudyAgendaItem? itemForObjective(String objectiveId) {
    for (final item in items) {
      if (item.objectiveId == objectiveId) return item;
    }
    return null;
  }

  /// Returns all items belonging to the given [allocationType].
  List<StudyAgendaItem> itemsForType(StudyAllocationType allocationType) =>
      items.where((item) => item.allocationType == allocationType).toList();

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'availableMinutes': availableMinutes,
        'allocatedMinutes': allocatedMinutes,
        'remainingCapacityMinutes': remainingCapacityMinutes,
        'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory DailyStudyAgenda.fromJson(Map<String, dynamic> json) =>
      DailyStudyAgenda(
        learnerId: json['learnerId'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        items: (json['items'] as List<dynamic>?)
                ?.map(
                    (e) => StudyAgendaItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <StudyAgendaItem>[],
        availableMinutes: (json['availableMinutes'] as num?)?.toInt() ?? 0,
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStudyAgenda &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          date == other.date &&
          availableMinutes == other.availableMinutes &&
          _listEquals(items, other.items);

  static bool _listEquals(List<StudyAgendaItem> a, List<StudyAgendaItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        learnerId,
        date,
        availableMinutes,
        Object.hashAll(items),
      );

  @override
  String toString() =>
      'DailyStudyAgenda(learnerId: $learnerId, date: ${date.toIso8601String()}, '
      'sessions: $sessionCount, $allocatedMinutes/${availableMinutes}min)';
}
