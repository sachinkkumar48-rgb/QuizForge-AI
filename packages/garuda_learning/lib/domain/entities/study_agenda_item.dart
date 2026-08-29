/// Study Agenda Item Entity (TITAN-KO-024.0 P24).
///
/// Immutable domain model representing a single allocated study session slot
/// within a [DailyStudyAgenda].
///
/// Educational Safety Principles:
/// - Represents a scheduling allocation decision, NOT a learner judgment.
/// - Explanation string must be factual and transparent.
/// - All timestamps are strictly UTC. No [DateTime.now()].
library;

import 'package:meta/meta.dart';

import 'study_allocation_type.dart';

/// Immutable specification of a single scheduled study session slot.
@immutable
class StudyAgendaItem {
  /// Unique identifier for this agenda item.
  final String itemId;

  /// Target P17 [LearningObjective.id].
  final String objectiveId;

  /// Strategic allocation tier of this study slot.
  final StudyAllocationType allocationType;

  /// UTC calendar date for which this item is scheduled (normalized to midnight UTC).
  final DateTime scheduledDate;

  /// Allocated duration in minutes for this study session. Must be > 0.
  final int allocatedMinutes;

  /// Deterministic 1-based priority rank within the day's agenda.
  final int priorityRank;

  /// Transparent, evidence-based explanation for why this item was scheduled.
  final String explanation;

  /// Optional identifier linking back to the source entity (e.g. recommendationId).
  final String? sourceEntityId;

  /// Diagnostic and scheduling metadata.
  final Map<String, dynamic> metadata;

  StudyAgendaItem({
    required this.itemId,
    required this.objectiveId,
    required this.allocationType,
    required DateTime scheduledDate,
    required this.allocatedMinutes,
    required this.priorityRank,
    required this.explanation,
    this.sourceEntityId,
    Map<String, dynamic>? metadata,
  })  : scheduledDate = DateTime.utc(
          scheduledDate.toUtc().year,
          scheduledDate.toUtc().month,
          scheduledDate.toUtc().day,
        ),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('ItemId cannot be empty for StudyAgendaItem');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('ObjectiveId cannot be empty for StudyAgendaItem');
    }
    if (allocatedMinutes <= 0) {
      throw ArgumentError(
          'AllocatedMinutes ($allocatedMinutes) must be strictly positive');
    }
    if (priorityRank < 1) {
      throw ArgumentError(
          'PriorityRank ($priorityRank) must be at least 1 (1-based index)');
    }
    if (explanation.trim().isEmpty) {
      throw ArgumentError('Explanation cannot be empty for StudyAgendaItem');
    }
  }

  /// Creates a copy of this agenda item with updated fields.
  StudyAgendaItem copyWith({
    String? itemId,
    String? objectiveId,
    StudyAllocationType? allocationType,
    DateTime? scheduledDate,
    int? allocatedMinutes,
    int? priorityRank,
    String? explanation,
    String? sourceEntityId,
    Map<String, dynamic>? metadata,
  }) {
    return StudyAgendaItem(
      itemId: itemId ?? this.itemId,
      objectiveId: objectiveId ?? this.objectiveId,
      allocationType: allocationType ?? this.allocationType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      allocatedMinutes: allocatedMinutes ?? this.allocatedMinutes,
      priorityRank: priorityRank ?? this.priorityRank,
      explanation: explanation ?? this.explanation,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'objectiveId': objectiveId,
        'allocationType': allocationType.name,
        'scheduledDate': scheduledDate.toIso8601String(),
        'allocatedMinutes': allocatedMinutes,
        'priorityRank': priorityRank,
        'explanation': explanation,
        if (sourceEntityId != null) 'sourceEntityId': sourceEntityId,
        'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory StudyAgendaItem.fromJson(Map<String, dynamic> json) =>
      StudyAgendaItem(
        itemId: json['itemId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        allocationType: StudyAllocationType.values.firstWhere(
          (e) => e.name == json['allocationType'],
          orElse: () => StudyAllocationType.newCurriculum,
        ),
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.parse(json['scheduledDate'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        allocatedMinutes: (json['allocatedMinutes'] as num?)?.toInt() ?? 1,
        priorityRank: (json['priorityRank'] as num?)?.toInt() ?? 1,
        explanation: json['explanation'] as String? ?? '',
        sourceEntityId: json['sourceEntityId'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyAgendaItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          objectiveId == other.objectiveId &&
          allocationType == other.allocationType &&
          scheduledDate == other.scheduledDate &&
          allocatedMinutes == other.allocatedMinutes &&
          priorityRank == other.priorityRank &&
          explanation == other.explanation &&
          sourceEntityId == other.sourceEntityId;

  @override
  int get hashCode => Object.hash(
        itemId,
        objectiveId,
        allocationType,
        scheduledDate,
        allocatedMinutes,
        priorityRank,
        explanation,
        sourceEntityId,
      );

  @override
  String toString() =>
      'StudyAgendaItem(rank: $priorityRank, obj: $objectiveId, '
      'type: ${allocationType.name}, ${allocatedMinutes}min)';
}
