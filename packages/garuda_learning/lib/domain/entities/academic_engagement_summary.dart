/// Academic Engagement Summary Domain Entity (TITAN-KO-053.0 P53).
///
/// Production domain models representing composite academic engagement
/// aggregating attendance compliance, learning path progress, assessment participation,
/// and active intervention alerts.
library;

import 'package:meta/meta.dart';
import 'academic_intervention_signal.dart';
import 'learner_attendance_summary.dart';

/// Categorical operational engagement tier for a learner.
enum EngagementStatus {
  /// Learner meets or exceeds attendance, progress, and assessment baselines.
  active,

  /// Learner exhibits lagging attendance, overdue tasks, or poor scores requiring academic monitoring.
  atRisk,

  /// Learner has discontinued participation or has prolonged inactivity.
  inactive,
}

/// Composite academic engagement overview for institutional monitoring.
@immutable
class AcademicEngagementSummary {
  /// Target learner identifier.
  final String learnerId;

  /// Associated course offering identifier.
  final String courseId;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Underlying attendance summary.
  final LearnerAttendanceSummary attendanceSummary;

  /// Current curriculum/learning path progress percentage (0.0 to 100.0).
  final double learningProgressPercentage;

  /// Count of completed assessment attempts.
  final int assessmentAttemptsCount;

  /// Average score across completed assessments (0.0 to 100.0).
  final double averageAssessmentScore;

  /// UTC timestamp of most recent activity (attendance, session, or assessment).
  final DateTime? lastActivityAt;

  /// Evaluated categorical engagement status.
  final EngagementStatus engagementStatus;

  /// Active (open or acknowledged) intervention alerts.
  final List<AcademicInterventionSignal> activeSignals;

  /// UTC evaluation timestamp.
  final DateTime evaluatedAt;

  AcademicEngagementSummary({
    required this.learnerId,
    required this.courseId,
    this.cohortId,
    required this.attendanceSummary,
    this.learningProgressPercentage = 0.0,
    this.assessmentAttemptsCount = 0,
    this.averageAssessmentScore = 0.0,
    this.lastActivityAt,
    required this.engagementStatus,
    Iterable<AcademicInterventionSignal>? activeSignals,
    DateTime? evaluatedAt,
  })  : activeSignals = List<AcademicInterventionSignal>.unmodifiable(
          activeSignals ?? const <AcademicInterventionSignal>[],
        ),
        evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc();

  bool get isActive => engagementStatus == EngagementStatus.active;
  bool get isAtRisk => engagementStatus == EngagementStatus.atRisk;
  bool get isInactive => engagementStatus == EngagementStatus.inactive;
  bool get hasActiveSignals => activeSignals.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'attendanceSummary': attendanceSummary.toJson(),
        'learningProgressPercentage': learningProgressPercentage,
        'assessmentAttemptsCount': assessmentAttemptsCount,
        'averageAssessmentScore': averageAssessmentScore,
        if (lastActivityAt != null)
          'lastActivityAt': lastActivityAt!.toIso8601String(),
        'engagementStatus': engagementStatus.name,
        'activeSignals': activeSignals.map((s) => s.toJson()).toList(),
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory AcademicEngagementSummary.fromJson(Map<String, dynamic> json) =>
      AcademicEngagementSummary(
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        attendanceSummary: LearnerAttendanceSummary.fromJson(
            json['attendanceSummary'] as Map<String, dynamic>),
        learningProgressPercentage:
            (json['learningProgressPercentage'] as num?)?.toDouble() ?? 0.0,
        assessmentAttemptsCount:
            (json['assessmentAttemptsCount'] as num?)?.toInt() ?? 0,
        averageAssessmentScore:
            (json['averageAssessmentScore'] as num?)?.toDouble() ?? 0.0,
        lastActivityAt: json['lastActivityAt'] != null
            ? DateTime.parse(json['lastActivityAt'] as String).toUtc()
            : null,
        engagementStatus: EngagementStatus.values.firstWhere(
          (s) => s.name == json['engagementStatus'],
          orElse: () => EngagementStatus.active,
        ),
        activeSignals: (json['activeSignals'] as List<dynamic>?)
                ?.map((s) => AcademicInterventionSignal.fromJson(
                    s as Map<String, dynamic>))
                .toList() ??
            const [],
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'AcademicEngagementSummary(learner: $learnerId, course: $courseId, status: ${engagementStatus.name}, signals: ${activeSignals.length})';
}
