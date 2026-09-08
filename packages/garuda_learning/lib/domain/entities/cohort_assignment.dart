/// Institutional Cohort Assignment Entities (TITAN-KO-048.0 P48).
///
/// Production domain models representing targeted learning assignments distributed
/// to institutional cohorts by faculty, with explicit deadlines, passing criteria,
/// and notification events.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle status of an assignment.
enum CohortAssignmentStatus {
  draft,
  published,
  closed,
}

/// Supported targets for cohort assignments.
enum CohortAssignmentTargetType {
  objective,
  topic,
  practiceModule,
  assessment,
  pyqSet,
  managedContent,
}

/// Criteria required to consider a cohort assignment completed by a learner.
@immutable
class CohortAssignmentPassingCriteria {
  /// Minimum number of question/drill attempts required.
  final int minAttempts;

  /// Minimum accuracy ratio required (0.0 to 1.0).
  final double minAccuracy;

  /// Required Bloom/Progression stage name (e.g. 'competent' or 'achieved').
  final String? requiredMasteryStage;

  const CohortAssignmentPassingCriteria({
    this.minAttempts = 1,
    this.minAccuracy = 0.60,
    this.requiredMasteryStage,
  })  : assert(minAttempts >= 0, 'minAttempts must be non-negative'),
        assert(minAccuracy >= 0.0 && minAccuracy <= 1.0,
            'minAccuracy must be between 0.0 and 1.0');

  Map<String, dynamic> toJson() => {
        'minAttempts': minAttempts,
        'minAccuracy': minAccuracy,
        if (requiredMasteryStage != null)
          'requiredMasteryStage': requiredMasteryStage,
      };

  factory CohortAssignmentPassingCriteria.fromJson(Map<String, dynamic> json) {
    return CohortAssignmentPassingCriteria(
      minAttempts: (json['minAttempts'] as num?)?.toInt() ?? 1,
      minAccuracy: (json['minAccuracy'] as num?)?.toDouble() ?? 0.60,
      requiredMasteryStage: json['requiredMasteryStage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortAssignmentPassingCriteria &&
          minAttempts == other.minAttempts &&
          minAccuracy == other.minAccuracy &&
          requiredMasteryStage == other.requiredMasteryStage;

  @override
  int get hashCode =>
      Object.hash(minAttempts, minAccuracy, requiredMasteryStage);
}

/// Immutable entity representing a targeted learning assignment for a cohort.
@immutable
class CohortAssignment {
  /// Unique canonical assignment identifier.
  final String assignmentId;

  /// Target cohort ID.
  final String cohortId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Human-readable title of assignment.
  final String title;

  /// Comprehensive description / instructions.
  final String description;

  /// Category of learning target.
  final CohortAssignmentTargetType targetType;

  /// Target identifier (objective ID, topic name, or content ID).
  final String targetId;

  /// Identifier of faculty author / assigner.
  final String assignedByFacultyId;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last updated timestamp.
  final DateTime updatedAt;

  /// UTC deadline.
  final DateTime dueDate;

  /// Assignment lifecycle status.
  final CohortAssignmentStatus status;

  /// Passing criteria for completion.
  final CohortAssignmentPassingCriteria passingCriteria;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  CohortAssignment({
    required this.assignmentId,
    required this.cohortId,
    this.tenantId = 'default_tenant',
    required this.title,
    this.description = '',
    this.targetType = CohortAssignmentTargetType.objective,
    required this.targetId,
    required this.assignedByFacultyId,
    required DateTime dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = CohortAssignmentStatus.draft,
    this.passingCriteria = const CohortAssignmentPassingCriteria(),
    Map<String, dynamic>? metadata,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        dueDate = dueDate.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (assignmentId.trim().isEmpty) {
      throw ArgumentError('assignmentId cannot be empty');
    }
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('assignment title cannot be empty');
    }
    if (targetId.trim().isEmpty) {
      throw ArgumentError('targetId cannot be empty');
    }
    if (assignedByFacultyId.trim().isEmpty) {
      throw ArgumentError('assignedByFacultyId cannot be empty');
    }
  }

  /// Whether the assignment is visible to learners.
  bool get isVisibleToLearners =>
      status == CohortAssignmentStatus.published ||
      status == CohortAssignmentStatus.closed;

  /// Whether the deadline has elapsed relative to [asOfDate].
  bool isOverdue(DateTime asOfDate) {
    return asOfDate.toUtc().isAfter(dueDate);
  }

  /// Whether the deadline is approaching within [threshold] (default 48 hours).
  bool isDueSoon(DateTime asOfDate,
      {Duration threshold = const Duration(hours: 48)}) {
    final now = asOfDate.toUtc();
    return !isOverdue(now) && dueDate.difference(now) <= threshold;
  }

  CohortAssignment copyWith({
    String? assignmentId,
    String? cohortId,
    String? tenantId,
    String? title,
    String? description,
    CohortAssignmentTargetType? targetType,
    String? targetId,
    String? assignedByFacultyId,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    CohortAssignmentStatus? status,
    CohortAssignmentPassingCriteria? passingCriteria,
    Map<String, dynamic>? metadata,
  }) {
    return CohortAssignment(
      assignmentId: assignmentId ?? this.assignmentId,
      cohortId: cohortId ?? this.cohortId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      assignedByFacultyId: assignedByFacultyId ?? this.assignedByFacultyId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      passingCriteria: passingCriteria ?? this.passingCriteria,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'cohortId': cohortId,
        'tenantId': tenantId,
        'title': title,
        'description': description,
        'targetType': targetType.name,
        'targetId': targetId,
        'assignedByFacultyId': assignedByFacultyId,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'status': status.name,
        'passingCriteria': passingCriteria.toJson(),
        'metadata': metadata,
      };

  factory CohortAssignment.fromJson(Map<String, dynamic> json) {
    return CohortAssignment(
      assignmentId: json['assignmentId'] as String? ?? '',
      cohortId: json['cohortId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? 'default_tenant',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetType: CohortAssignmentTargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => CohortAssignmentTargetType.objective,
      ),
      targetId: json['targetId'] as String? ?? '',
      assignedByFacultyId: json['assignedByFacultyId'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String).toUtc()
          : DateTime.now().toUtc().add(const Duration(days: 7)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toUtc()
          : null,
      status: CohortAssignmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CohortAssignmentStatus.draft,
      ),
      passingCriteria: json['passingCriteria'] != null
          ? CohortAssignmentPassingCriteria.fromJson(
              Map<String, dynamic>.from(json['passingCriteria'] as Map))
          : const CohortAssignmentPassingCriteria(),
      metadata: Map<String, dynamic>.from(
          json['metadata'] as Map? ?? const <String, dynamic>{}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortAssignment &&
          assignmentId == other.assignmentId &&
          cohortId == other.cohortId &&
          tenantId == other.tenantId &&
          title == other.title &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          assignedByFacultyId == other.assignedByFacultyId &&
          dueDate == other.dueDate &&
          status == other.status &&
          passingCriteria == other.passingCriteria;

  @override
  int get hashCode => Object.hash(
        assignmentId,
        cohortId,
        tenantId,
        title,
        targetId,
        assignedByFacultyId,
        dueDate,
        status,
      );

  @override
  String toString() =>
      'CohortAssignment(id: $assignmentId, cohort: $cohortId, target: $targetId, status: ${status.name})';
}

/// Categories of assignment events for notifications / webhooks.
enum CohortAssignmentEventType {
  published,
  dueSoon,
  overdue,
  completed,
}

/// Notification boundary event representing an assignment status change.
@immutable
class CohortAssignmentEvent {
  final String assignmentId;
  final String cohortId;
  final CohortAssignmentEventType type;
  final DateTime timestamp;
  final String? learnerId;
  final Map<String, dynamic> metadata;

  CohortAssignmentEvent({
    required this.assignmentId,
    required this.cohortId,
    required this.type,
    DateTime? timestamp,
    this.learnerId,
    Map<String, dynamic>? metadata,
  })  : timestamp = (timestamp ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  @override
  String toString() =>
      'CohortAssignmentEvent(type: ${type.name}, assignment: $assignmentId, learner: $learnerId)';
}
