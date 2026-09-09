/// Academic Intervention Signal Domain Entity (TITAN-KO-053.0 P53).
///
/// Production domain models representing non-punitive academic early-warning
/// intervention signals, tracking trigger causes, severity tiers, and faculty review lifecycle.
library;

import 'package:meta/meta.dart';

/// Categories of academic early-warning intervention signals.
enum AcademicSignalType {
  /// Learner attendance dropped below institutional threshold (e.g. < 75%).
  lowAttendance,

  /// Overall learning engagement score/composite dropped below active baseline.
  lowEngagement,

  /// Learner has not engaged in learning activities for a prolonged duration.
  noRecentActivity,

  /// Assessment or diagnostic performance indicates severe risk of failure.
  academicPerformanceRisk,
}

/// Severity grading for intervention signals.
enum SignalSeverity {
  low,
  medium,
  high,
  critical,
}

/// Lifecycle review status of an intervention signal.
enum SignalStatus {
  /// Signal generated, awaiting faculty/advisor review.
  open,

  /// Faculty reviewed the alert and initiated support contact.
  acknowledged,

  /// Support action completed, academic concern mitigated.
  resolved,
}

/// Immutable record capturing an early-warning signal for academic faculty review.
///
/// NOTE: Intervention signals are purely advisory and non-disciplinary.
/// They do NOT automatically penalize, fail, or suspend a learner.
@immutable
class AcademicInterventionSignal {
  /// Unique canonical signal identifier (e.g. 'sig_low_att_learner1_course1').
  final String signalId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target learner identifier.
  final String learnerId;

  /// Associated course offering identifier.
  final String courseId;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Type of academic concern identified.
  final AcademicSignalType signalType;

  /// Severity tier of the signal.
  final SignalSeverity severity;

  /// Current lifecycle status.
  final SignalStatus status;

  /// Identifier or name of the metric that breached threshold.
  final String triggerMetric;

  /// Numerical or text value that triggered the alert.
  final double triggerValue;

  /// Minimum threshold expected by policy.
  final double thresholdValue;

  /// Human-readable explanation and context for faculty advisors.
  final String description;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC timestamp when acknowledged by faculty.
  final DateTime? acknowledgedAt;

  /// Actor ID who acknowledged the alert.
  final String? acknowledgedBy;

  /// UTC timestamp when resolved.
  final DateTime? resolvedAt;

  /// Actor ID who resolved the alert.
  final String? resolvedBy;

  /// Documented intervention notes / faculty follow-up outcome.
  final String? resolutionNotes;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AcademicInterventionSignal({
    required this.signalId,
    this.tenantId = 'default_tenant',
    required this.learnerId,
    required this.courseId,
    this.cohortId,
    required this.signalType,
    this.severity = SignalSeverity.medium,
    this.status = SignalStatus.open,
    required this.triggerMetric,
    required this.triggerValue,
    required this.thresholdValue,
    required this.description,
    DateTime? createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    Map<String, dynamic>? metadata,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (signalId.trim().isEmpty) {
      throw ArgumentError('signalId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
    if (triggerMetric.trim().isEmpty) {
      throw ArgumentError('triggerMetric cannot be empty');
    }
  }

  bool get isOpen => status == SignalStatus.open;
  bool get isAcknowledged => status == SignalStatus.acknowledged;
  bool get isResolved => status == SignalStatus.resolved;

  /// Canonical ID generator from coordinates.
  static String generateId({
    required String learnerId,
    required String courseId,
    required AcademicSignalType type,
  }) {
    return 'sig_${type.name}_${courseId.trim()}_${learnerId.trim()}';
  }

  /// Transitions signal to ACKNOWLEDGED by faculty.
  AcademicInterventionSignal acknowledge({
    required String actorId,
    DateTime? at,
  }) {
    if (status != SignalStatus.open) {
      throw StateError(
          'Only open signals can be acknowledged (current: ${status.name}).');
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: SignalStatus.acknowledged,
      acknowledgedAt: now,
      acknowledgedBy: actorId.trim(),
    );
  }

  /// Transitions signal to RESOLVED with mandatory action notes.
  AcademicInterventionSignal resolve({
    required String actorId,
    required String notes,
    DateTime? at,
  }) {
    final cleanNotes = notes.trim();
    if (cleanNotes.isEmpty) {
      throw ArgumentError('Resolution notes cannot be empty');
    }
    if (status == SignalStatus.resolved) {
      throw StateError('Signal is already resolved.');
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: SignalStatus.resolved,
      resolvedAt: now,
      resolvedBy: actorId.trim(),
      resolutionNotes: cleanNotes,
    );
  }

  AcademicInterventionSignal copyWith({
    String? signalId,
    String? tenantId,
    String? learnerId,
    String? courseId,
    String? cohortId,
    AcademicSignalType? signalType,
    SignalSeverity? severity,
    SignalStatus? status,
    String? triggerMetric,
    double? triggerValue,
    double? thresholdValue,
    String? description,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolutionNotes,
    Map<String, dynamic>? metadata,
  }) {
    return AcademicInterventionSignal(
      signalId: signalId ?? this.signalId,
      tenantId: tenantId ?? this.tenantId,
      learnerId: learnerId ?? this.learnerId,
      courseId: courseId ?? this.courseId,
      cohortId: cohortId ?? this.cohortId,
      signalType: signalType ?? this.signalType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      triggerMetric: triggerMetric ?? this.triggerMetric,
      triggerValue: triggerValue ?? this.triggerValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'signalId': signalId,
        'tenantId': tenantId,
        'learnerId': learnerId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'signalType': signalType.name,
        'severity': severity.name,
        'status': status.name,
        'triggerMetric': triggerMetric,
        'triggerValue': triggerValue,
        'thresholdValue': thresholdValue,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        if (acknowledgedAt != null)
          'acknowledgedAt': acknowledgedAt!.toIso8601String(),
        if (acknowledgedBy != null) 'acknowledgedBy': acknowledgedBy,
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
        if (resolvedBy != null) 'resolvedBy': resolvedBy,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
        'metadata': metadata,
      };

  factory AcademicInterventionSignal.fromJson(Map<String, dynamic> json) =>
      AcademicInterventionSignal(
        signalId: json['signalId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        signalType: AcademicSignalType.values.firstWhere(
          (t) => t.name == json['signalType'],
          orElse: () => AcademicSignalType.lowAttendance,
        ),
        severity: SignalSeverity.values.firstWhere(
          (s) => s.name == json['severity'],
          orElse: () => SignalSeverity.medium,
        ),
        status: SignalStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SignalStatus.open,
        ),
        triggerMetric: json['triggerMetric'] as String? ?? '',
        triggerValue: (json['triggerValue'] as num?)?.toDouble() ?? 0.0,
        thresholdValue: (json['thresholdValue'] as num?)?.toDouble() ?? 75.0,
        description: json['description'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : null,
        acknowledgedAt: json['acknowledgedAt'] != null
            ? DateTime.parse(json['acknowledgedAt'] as String).toUtc()
            : null,
        acknowledgedBy: json['acknowledgedBy'] as String?,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String).toUtc()
            : null,
        resolvedBy: json['resolvedBy'] as String?,
        resolutionNotes: json['resolutionNotes'] as String?,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicInterventionSignal &&
          signalId == other.signalId &&
          tenantId == other.tenantId;

  @override
  int get hashCode => Object.hash(signalId, tenantId);

  @override
  String toString() =>
      'AcademicInterventionSignal(id: $signalId, type: ${signalType.name}, severity: ${severity.name}, status: ${status.name})';
}
