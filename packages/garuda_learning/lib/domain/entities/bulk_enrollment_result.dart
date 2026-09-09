/// Bulk Enrollment Result Domain Entity (TITAN-KO-052.0 P52).
///
/// Production domain models representing outcomes of institutional bulk/cohort
/// course enrollments, capturing granular successes and failure reasons.
library;

import 'package:meta/meta.dart';
import 'enrollment.dart';

/// Structured outcome of a batch enrollment operation.
@immutable
class BulkEnrollmentResult {
  /// Target course identifier.
  final String courseId;

  /// Target cohort identifier where applicable.
  final String? cohortId;

  /// Total count of learners requested for enrollment.
  final int totalAttempted;

  /// Enrollments that were successfully established or updated.
  final List<Enrollment> successfulEnrollments;

  /// Map of learnerId to failure reason for those who could not be enrolled.
  final Map<String, String> failedLearnerIds;

  /// UTC execution timestamp.
  final DateTime timestamp;

  BulkEnrollmentResult({
    required this.courseId,
    this.cohortId,
    required this.totalAttempted,
    Iterable<Enrollment>? successfulEnrollments,
    Map<String, String>? failedLearnerIds,
    DateTime? timestamp,
  })  : successfulEnrollments = List<Enrollment>.unmodifiable(
          successfulEnrollments ?? const <Enrollment>[],
        ),
        failedLearnerIds = Map<String, String>.unmodifiable(
          failedLearnerIds ?? const <String, String>{},
        ),
        timestamp = (timestamp ?? DateTime.now()).toUtc();

  int get successCount => successfulEnrollments.length;
  int get failureCount => failedLearnerIds.length;
  bool get isFullSuccess => failedLearnerIds.isEmpty && totalAttempted > 0;
  bool get isPartialSuccess =>
      successfulEnrollments.isNotEmpty && failedLearnerIds.isNotEmpty;
  bool get hasFailures => failedLearnerIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'totalAttempted': totalAttempted,
        'successfulEnrollments':
            successfulEnrollments.map((e) => e.toJson()).toList(),
        'failedLearnerIds': failedLearnerIds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BulkEnrollmentResult.fromJson(Map<String, dynamic> json) =>
      BulkEnrollmentResult(
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        totalAttempted: (json['totalAttempted'] as num?)?.toInt() ?? 0,
        successfulEnrollments: (json['successfulEnrollments'] as List<dynamic>?)
                ?.map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        failedLearnerIds: Map<String, String>.from(
            json['failedLearnerIds'] as Map? ?? const <String, String>{}),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'BulkEnrollmentResult(course: $courseId, attempted: $totalAttempted, success: $successCount, failed: $failureCount)';
}
