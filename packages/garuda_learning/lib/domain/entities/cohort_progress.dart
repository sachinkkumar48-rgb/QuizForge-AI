/// Institutional Cohort Progress & Analytics Models (TITAN-KO-048.0 P48).
///
/// Production models representing derived learner compliance, cohort assignment
/// aggregation, weak area tracking, and performance reporting.
library;

import 'package:meta/meta.dart';

import 'cohort.dart';
import 'cohort_assignment.dart';
import 'learner_analytics_report.dart';

/// Progress status for an individual learner on a cohort assignment.
enum CohortLearnerProgressStatus {
  notStarted,
  inProgress,
  completed,
  overdue,
}

/// Derived authoritative progress for a specific learner on an assignment.
@immutable
class CohortLearnerProgress {
  final String assignmentId;
  final String cohortId;
  final String learnerId;
  final CohortLearnerProgressStatus status;
  final int attempts;
  final double accuracy;
  final bool isPassing;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
  final String targetId;
  final CohortAssignmentTargetType targetType;
  final String? masteryStage;

  const CohortLearnerProgress({
    required this.assignmentId,
    required this.cohortId,
    required this.learnerId,
    required this.status,
    this.attempts = 0,
    this.accuracy = 0.0,
    this.isPassing = false,
    this.completedAt,
    this.lastActivityAt,
    required this.targetId,
    this.targetType = CohortAssignmentTargetType.objective,
    this.masteryStage,
  });

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'cohortId': cohortId,
        'learnerId': learnerId,
        'status': status.name,
        'attempts': attempts,
        'accuracy': accuracy,
        'isPassing': isPassing,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (lastActivityAt != null)
          'lastActivityAt': lastActivityAt!.toIso8601String(),
        'targetId': targetId,
        'targetType': targetType.name,
        if (masteryStage != null) 'masteryStage': masteryStage,
      };

  factory CohortLearnerProgress.fromJson(Map<String, dynamic> json) {
    return CohortLearnerProgress(
      assignmentId: json['assignmentId'] as String? ?? '',
      cohortId: json['cohortId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      status: CohortLearnerProgressStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CohortLearnerProgressStatus.notStarted,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      isPassing: json['isPassing'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String).toUtc()
          : null,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String).toUtc()
          : null,
      targetId: json['targetId'] as String? ?? '',
      targetType: CohortAssignmentTargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => CohortAssignmentTargetType.objective,
      ),
      masteryStage: json['masteryStage'] as String?,
    );
  }

  @override
  String toString() =>
      'CohortLearnerProgress(learner: $learnerId, assignment: $assignmentId, status: ${status.name}, acc: ${(accuracy * 100).toStringAsFixed(1)}%)';
}

/// Cohort-wide summary of a single assignment.
@immutable
class CohortAssignmentSummary {
  final CohortAssignment assignment;
  final int totalAssigned;
  final int completedCount;
  final int inProgressCount;
  final int overdueCount;
  final int notStartedCount;
  final double completionRate;
  final List<CohortLearnerProgress> learnerProgressList;

  CohortAssignmentSummary({
    required this.assignment,
    required this.totalAssigned,
    required this.completedCount,
    required this.inProgressCount,
    required this.overdueCount,
    required this.notStartedCount,
    double? completionRate,
    Iterable<CohortLearnerProgress>? learnerProgressList,
  })  : completionRate = completionRate ??
            (totalAssigned == 0 ? 0.0 : (completedCount / totalAssigned)),
        learnerProgressList = List<CohortLearnerProgress>.unmodifiable(
            learnerProgressList ?? const <CohortLearnerProgress>[]);

  Map<String, dynamic> toJson() => {
        'assignment': assignment.toJson(),
        'totalAssigned': totalAssigned,
        'completedCount': completedCount,
        'inProgressCount': inProgressCount,
        'overdueCount': overdueCount,
        'notStartedCount': notStartedCount,
        'completionRate': completionRate,
        'learnerProgressList':
            learnerProgressList.map((p) => p.toJson()).toList(),
      };

  @override
  String toString() =>
      'CohortAssignmentSummary(title: "${assignment.title}", assigned: $totalAssigned, completed: $completedCount, inProgress: $inProgressCount, overdue: $overdueCount)';
}

/// Comprehensive summary of an institutional cohort.
@immutable
class CohortSummary {
  final Cohort cohort;
  final int totalLearners;
  final int activeLearners;
  final int totalAssignments;
  final int completedAssignmentsCount;
  final int overdueCount;
  final double completionRate;
  final double averageAccuracy;
  final List<String> weakAreas;
  final List<CohortAssignmentSummary> assignmentSummaries;

  CohortSummary({
    required this.cohort,
    required this.totalLearners,
    required this.activeLearners,
    required this.totalAssignments,
    required this.completedAssignmentsCount,
    required this.overdueCount,
    required this.completionRate,
    required this.averageAccuracy,
    Iterable<String>? weakAreas,
    Iterable<CohortAssignmentSummary>? assignmentSummaries,
  })  : weakAreas = List<String>.unmodifiable(weakAreas ?? const <String>[]),
        assignmentSummaries = List<CohortAssignmentSummary>.unmodifiable(
            assignmentSummaries ?? const <CohortAssignmentSummary>[]);

  Map<String, dynamic> toJson() => {
        'cohort': cohort.toJson(),
        'totalLearners': totalLearners,
        'activeLearners': activeLearners,
        'totalAssignments': totalAssignments,
        'completedAssignmentsCount': completedAssignmentsCount,
        'overdueCount': overdueCount,
        'completionRate': completionRate,
        'averageAccuracy': averageAccuracy,
        'weakAreas': weakAreas,
        'assignmentSummaries':
            assignmentSummaries.map((s) => s.toJson()).toList(),
      };

  @override
  String toString() =>
      'CohortSummary(cohort: "${cohort.name}", learners: $totalLearners, active: $activeLearners, assignments: $totalAssignments, completionRate: ${(completionRate * 100).toStringAsFixed(1)}%)';
}

/// Full analytical report for a cohort including weak spots.
@immutable
class CohortAnalyticsReport {
  final CohortSummary summary;
  final List<CohortAssignmentSummary> assignmentSummaries;
  final List<WeakAreaMetric> weakObjectiveDetails;
  final DateTime generatedAt;

  CohortAnalyticsReport({
    required this.summary,
    required Iterable<CohortAssignmentSummary> assignmentSummaries,
    Iterable<WeakAreaMetric>? weakObjectiveDetails,
    DateTime? generatedAt,
  })  : assignmentSummaries =
            List<CohortAssignmentSummary>.unmodifiable(assignmentSummaries),
        weakObjectiveDetails = List<WeakAreaMetric>.unmodifiable(
            weakObjectiveDetails ?? const <WeakAreaMetric>[]),
        generatedAt = (generatedAt ?? DateTime.now()).toUtc();

  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'assignmentSummaries':
            assignmentSummaries.map((s) => s.toJson()).toList(),
        'weakObjectiveDetails':
            weakObjectiveDetails.map((w) => w.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };
}
