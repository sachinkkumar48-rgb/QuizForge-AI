/// Cohort Gradebook & Performance Matrix Domain Entities (TITAN-KO-050.0 P50).
///
/// Production models aggregating learner grade summaries, cohort performance
/// metrics, grade distribution, and multi-assessment matrices.
library;

import 'package:meta/meta.dart';

import 'gradebook_entry.dart';

/// Aggregated performance summary for an individual learner across all cohort assessments.
@immutable
class CohortLearnerGradeSummary {
  final String learnerId;
  final int attemptedCount;
  final int evaluatedCount;
  final int publishedCount;
  final double totalScore;
  final double totalMaxScore;
  final double averagePercentage;
  final String overallGrade;
  final bool isPassing;

  const CohortLearnerGradeSummary({
    required this.learnerId,
    this.attemptedCount = 0,
    this.evaluatedCount = 0,
    this.publishedCount = 0,
    this.totalScore = 0.0,
    this.totalMaxScore = 0.0,
    this.averagePercentage = 0.0,
    this.overallGrade = 'F',
    this.isPassing = false,
  });

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'attemptedCount': attemptedCount,
        'evaluatedCount': evaluatedCount,
        'publishedCount': publishedCount,
        'totalScore': totalScore,
        'totalMaxScore': totalMaxScore,
        'averagePercentage': averagePercentage,
        'overallGrade': overallGrade,
        'isPassing': isPassing,
      };

  factory CohortLearnerGradeSummary.fromJson(Map<String, dynamic> json) =>
      CohortLearnerGradeSummary(
        learnerId: json['learnerId'] as String? ?? '',
        attemptedCount: (json['attemptedCount'] as num?)?.toInt() ?? 0,
        evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
        publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
        totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
        totalMaxScore: (json['totalMaxScore'] as num?)?.toDouble() ?? 0.0,
        averagePercentage:
            (json['averagePercentage'] as num?)?.toDouble() ?? 0.0,
        overallGrade: json['overallGrade'] as String? ?? 'F',
        isPassing: json['isPassing'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortLearnerGradeSummary &&
          learnerId == other.learnerId &&
          totalScore == other.totalScore &&
          averagePercentage == other.averagePercentage &&
          overallGrade == other.overallGrade;

  @override
  int get hashCode =>
      Object.hash(learnerId, totalScore, averagePercentage, overallGrade);

  @override
  String toString() =>
      'CohortLearnerGradeSummary(learner: $learnerId, avg: ${averagePercentage.toStringAsFixed(1)}%, grade: $overallGrade)';
}

/// Column descriptor in a cohort grade matrix.
@immutable
class CohortAssessmentColumn {
  final String assessmentId;
  final String title;

  const CohortAssessmentColumn({
    required this.assessmentId,
    required this.title,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortAssessmentColumn && assessmentId == other.assessmentId;

  @override
  int get hashCode => assessmentId.hashCode;
}

/// Aggregated institutional performance metrics across a cohort's entire gradebook.
@immutable
class CohortGradebookSummary {
  final String cohortId;
  final int totalLearners;
  final int totalAssessments;
  final int totalEntries;
  final int evaluatedCount;
  final int publishedCount;
  final int passCount;
  final int failCount;
  final double averageScore;
  final double averagePercentage;
  final double completionRate;
  final double passRate;
  final Map<String, int> gradeDistribution;

  CohortGradebookSummary({
    required this.cohortId,
    required this.totalLearners,
    required this.totalAssessments,
    required this.totalEntries,
    required this.evaluatedCount,
    required this.publishedCount,
    required this.passCount,
    required this.failCount,
    required this.averageScore,
    required this.averagePercentage,
    required this.completionRate,
    required this.passRate,
    Map<String, int>? gradeDistribution,
  }) : gradeDistribution =
            Map<String, int>.unmodifiable(gradeDistribution ?? const {});

  int get enrolledLearnersCount => totalLearners;
  double get passRatePercentage =>
      passRate <= 1.0 && passRate > 0.0 ? passRate * 100.0 : passRate;
  double get averageScorePercentage => averagePercentage;

  Map<String, dynamic> toJson() => {
        'cohortId': cohortId,
        'totalLearners': totalLearners,
        'totalAssessments': totalAssessments,
        'totalEntries': totalEntries,
        'evaluatedCount': evaluatedCount,
        'publishedCount': publishedCount,
        'passCount': passCount,
        'failCount': failCount,
        'averageScore': averageScore,
        'averagePercentage': averagePercentage,
        'completionRate': completionRate,
        'passRate': passRate,
        'gradeDistribution': gradeDistribution,
      };

  factory CohortGradebookSummary.fromJson(Map<String, dynamic> json) =>
      CohortGradebookSummary(
        cohortId: json['cohortId'] as String? ?? '',
        totalLearners: (json['totalLearners'] as num?)?.toInt() ?? 0,
        totalAssessments: (json['totalAssessments'] as num?)?.toInt() ?? 0,
        totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
        evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
        publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
        passCount: (json['passCount'] as num?)?.toInt() ?? 0,
        failCount: (json['failCount'] as num?)?.toInt() ?? 0,
        averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
        averagePercentage:
            (json['averagePercentage'] as num?)?.toDouble() ?? 0.0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        passRate: (json['passRate'] as num?)?.toDouble() ?? 0.0,
        gradeDistribution: Map<String, int>.from(
            json['gradeDistribution'] as Map? ?? const {}),
      );

  @override
  String toString() =>
      'CohortGradebookSummary(cohort: $cohortId, learners: $totalLearners, published: $publishedCount/$evaluatedCount, avg: ${averagePercentage.toStringAsFixed(1)}%)';
}

/// Comprehensive gradebook matrix structure representing all assessments and learners for a cohort.
@immutable
class CohortGradebook {
  final String cohortId;
  final String tenantId;
  final List<String> assessmentIds;
  final List<String> learnerIds;
  final Map<String, GradebookEntry> entries;
  final CohortGradebookSummary summary;
  final Map<String, CohortLearnerGradeSummary> learnerSummaries;

  CohortGradebook({
    required this.cohortId,
    this.tenantId = 'default_tenant',
    Iterable<String>? assessmentIds,
    Iterable<String>? learnerIds,
    Map<String, GradebookEntry>? entries,
    required this.summary,
    Map<String, CohortLearnerGradeSummary>? learnerSummaries,
  })  : assessmentIds =
            List<String>.unmodifiable(assessmentIds ?? const <String>[]),
        learnerIds = List<String>.unmodifiable(learnerIds ?? const <String>[]),
        entries = Map<String, GradebookEntry>.unmodifiable(entries ?? const {}),
        learnerSummaries = Map<String, CohortLearnerGradeSummary>.unmodifiable(
            learnerSummaries ?? const {});

  List<String> get enrolledLearners => learnerIds;

  List<CohortAssessmentColumn> get assessments {
    final list = <CohortAssessmentColumn>[];
    for (final aId in assessmentIds) {
      list.add(CohortAssessmentColumn(assessmentId: aId, title: aId));
    }
    return list;
  }

  Map<String, Map<String, GradebookEntry>> get matrix {
    final map = <String, Map<String, GradebookEntry>>{};
    for (final lId in learnerIds) {
      map[lId] = {};
    }
    for (final entry in entries.values) {
      map.putIfAbsent(entry.learnerId, () => {})[entry.assessmentId] = entry;
    }
    return map;
  }

  /// Retrieves the entry for [learnerId] and [assessmentId] if present.
  GradebookEntry? getEntry(String learnerId, String assessmentId) {
    return entries['${learnerId.trim()}_${assessmentId.trim()}'] ??
        matrix[learnerId.trim()]?[assessmentId.trim()];
  }

  Map<String, dynamic> toJson() => {
        'cohortId': cohortId,
        'tenantId': tenantId,
        'assessmentIds': assessmentIds,
        'learnerIds': learnerIds,
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
        'summary': summary.toJson(),
        'learnerSummaries':
            learnerSummaries.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory CohortGradebook.fromJson(Map<String, dynamic> json) =>
      CohortGradebook(
        cohortId: json['cohortId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        assessmentIds: (json['assessmentIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        learnerIds: (json['learnerIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        entries: (json['entries'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                k,
                GradebookEntry.fromJson(Map<String, dynamic>.from(v as Map)),
              ),
            ) ??
            const {},
        summary: CohortGradebookSummary.fromJson(
          Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
        ),
        learnerSummaries:
            (json['learnerSummaries'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(
                    k,
                    CohortLearnerGradeSummary.fromJson(
                      Map<String, dynamic>.from(v as Map),
                    ),
                  ),
                ) ??
                const {},
      );
}
