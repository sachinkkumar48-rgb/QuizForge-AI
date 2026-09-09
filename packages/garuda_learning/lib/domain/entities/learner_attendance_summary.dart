/// Learner Attendance Summary & Calculation Policy Domain Entities (TITAN-KO-053.0 P53).
///
/// Production domain models representing deterministic institutional attendance
/// aggregation, configurable weighting policies (late weighting, excused handling),
/// and threshold compliance evaluation.
library;

import 'package:meta/meta.dart';
import 'attendance_record.dart';

/// Configurable, testable institutional calculation rules for attendance percentages.
@immutable
class AttendancePolicy {
  /// Credit assigned to a 'late' attendance status (0.0 to 1.0, standard default 0.5).
  final double lateWeight;

  /// Minimum attendance percentage required for academic eligibility (standard default 75.0%).
  final double minimumAttendanceThreshold;

  /// Whether excused absences are treated as attended (true) or excluded from denominator (false, standard).
  final bool excusedCountsAsAttended;

  const AttendancePolicy({
    this.lateWeight = 0.5,
    this.minimumAttendanceThreshold = 75.0,
    this.excusedCountsAsAttended = false,
  });

  const AttendancePolicy.standard()
      : lateWeight = 0.5,
        minimumAttendanceThreshold = 75.0,
        excusedCountsAsAttended = false;

  /// Strict academic calculation:
  /// - If excusedCountsAsAttended = false:
  ///   applicableSessions = totalFinalized - excused
  ///   attendedUnits = present * 1.0 + late * lateWeight
  ///   percentage = (attendedUnits / max(1, applicableSessions)) * 100
  /// - If all sessions are excused, returns 100.0%.
  /// - Returns 100.0% if 0 finalized sessions.
  double calculateAttendancePercentage({
    required int present,
    required int late,
    required int absent,
    required int excused,
  }) {
    final total = present + late + absent + excused;
    if (total == 0) return 100.0;

    if (excusedCountsAsAttended) {
      final attendedUnits =
          (present * 1.0) + (late * lateWeight) + (excused * 1.0);
      final pct = (attendedUnits / total) * 100.0;
      return pct.clamp(0.0, 100.0);
    } else {
      final applicable = total - excused;
      if (applicable <= 0) return 100.0; // All excused
      final attendedUnits = (present * 1.0) + (late * lateWeight);
      final pct = (attendedUnits / applicable) * 100.0;
      return pct.clamp(0.0, 100.0);
    }
  }

  Map<String, dynamic> toJson() => {
        'lateWeight': lateWeight,
        'minimumAttendanceThreshold': minimumAttendanceThreshold,
        'excusedCountsAsAttended': excusedCountsAsAttended,
      };

  factory AttendancePolicy.fromJson(Map<String, dynamic> json) =>
      AttendancePolicy(
        lateWeight: (json['lateWeight'] as num?)?.toDouble() ?? 0.5,
        minimumAttendanceThreshold:
            (json['minimumAttendanceThreshold'] as num?)?.toDouble() ?? 75.0,
        excusedCountsAsAttended:
            json['excusedCountsAsAttended'] as bool? ?? false,
      );
}

/// Aggregated authoritative attendance metric for a learner in a course offering.
@immutable
class LearnerAttendanceSummary {
  /// Target learner identifier.
  final String learnerId;

  /// Associated course identifier.
  final String courseId;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Total sessions scheduled for this course/cohort.
  final int totalSessionsScheduled;

  /// Total finalized/closed sessions evaluated.
  final int totalSessionsFinalized;

  /// Count of finalized sessions marked PRESENT.
  final int presentCount;

  /// Count of finalized sessions marked LATE.
  final int lateCount;

  /// Count of finalized sessions marked ABSENT.
  final int absentCount;

  /// Count of finalized sessions marked EXCUSED.
  final int excusedCount;

  /// Deterministically computed attendance percentage.
  final double attendancePercentage;

  /// Whether attendance percentage meets or exceeds the institutional policy threshold.
  final bool meetsAttendanceThreshold;

  /// Recent finalized attendance records (most recent first).
  final List<AttendanceRecord> recentRecords;

  /// UTC calculation timestamp.
  final DateTime calculatedAt;

  LearnerAttendanceSummary({
    required this.learnerId,
    required this.courseId,
    this.cohortId,
    required this.totalSessionsScheduled,
    required this.totalSessionsFinalized,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.excusedCount,
    required this.attendancePercentage,
    required this.meetsAttendanceThreshold,
    Iterable<AttendanceRecord>? recentRecords,
    DateTime? calculatedAt,
  })  : recentRecords = List<AttendanceRecord>.unmodifiable(
          recentRecords ?? const <AttendanceRecord>[],
        ),
        calculatedAt = (calculatedAt ?? DateTime.now()).toUtc();

  /// Factory constructing summary from raw finalized attendance records using given policy.
  factory LearnerAttendanceSummary.fromRecords({
    required String learnerId,
    required String courseId,
    String? cohortId,
    required int totalSessionsScheduled,
    required List<AttendanceRecord> finalizedRecords,
    AttendancePolicy policy = const AttendancePolicy.standard(),
    DateTime? calculatedAt,
  }) {
    int present = 0;
    int late = 0;
    int absent = 0;
    int excused = 0;

    for (final rec in finalizedRecords) {
      switch (rec.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
      }
    }

    final pct = policy.calculateAttendancePercentage(
      present: present,
      late: late,
      absent: absent,
      excused: excused,
    );

    final meetsThreshold = pct >= policy.minimumAttendanceThreshold;

    final sortedRecords = List<AttendanceRecord>.from(finalizedRecords)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return LearnerAttendanceSummary(
      learnerId: learnerId,
      courseId: courseId,
      cohortId: cohortId,
      totalSessionsScheduled: totalSessionsScheduled,
      totalSessionsFinalized: finalizedRecords.length,
      presentCount: present,
      lateCount: late,
      absentCount: absent,
      excusedCount: excused,
      attendancePercentage: double.parse(pct.toStringAsFixed(2)),
      meetsAttendanceThreshold: meetsThreshold,
      recentRecords: sortedRecords.take(10).toList(),
      calculatedAt: calculatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'totalSessionsScheduled': totalSessionsScheduled,
        'totalSessionsFinalized': totalSessionsFinalized,
        'presentCount': presentCount,
        'lateCount': lateCount,
        'absentCount': absentCount,
        'excusedCount': excusedCount,
        'attendancePercentage': attendancePercentage,
        'meetsAttendanceThreshold': meetsAttendanceThreshold,
        'recentRecords': recentRecords.map((r) => r.toJson()).toList(),
        'calculatedAt': calculatedAt.toIso8601String(),
      };

  factory LearnerAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      LearnerAttendanceSummary(
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        totalSessionsScheduled:
            (json['totalSessionsScheduled'] as num?)?.toInt() ?? 0,
        totalSessionsFinalized:
            (json['totalSessionsFinalized'] as num?)?.toInt() ?? 0,
        presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
        lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
        absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
        excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
        attendancePercentage:
            (json['attendancePercentage'] as num?)?.toDouble() ?? 100.0,
        meetsAttendanceThreshold:
            json['meetsAttendanceThreshold'] as bool? ?? true,
        recentRecords: (json['recentRecords'] as List<dynamic>?)
                ?.map(
                    (r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        calculatedAt: json['calculatedAt'] != null
            ? DateTime.parse(json['calculatedAt'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'LearnerAttendanceSummary(learner: $learnerId, course: $courseId, attendance: $attendancePercentage%, threshold: $meetsAttendanceThreshold)';
}
