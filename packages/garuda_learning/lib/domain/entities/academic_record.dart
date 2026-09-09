/// Academic Record Domain Entities (TITAN-KO-051.0 P51).
///
/// Production domain models representing a learner's official academic record,
/// aggregating authoritative published grades, deterministic outcomes,
/// and distinction between calculated, published, and official results.
library;

import 'package:meta/meta.dart';

/// Single academic outcome entry in an academic record.
@immutable
class AcademicRecordEntry {
  /// Associated formal assessment identifier.
  final String assessmentId;

  /// Human-readable title of the assessment.
  final String assessmentTitle;

  /// Original score before any faculty overrides.
  final double? originalScore;

  /// Final authoritative score evaluated or overridden.
  final double finalScore;

  /// Total maximum possible marks for the assessment.
  final double maxScore;

  /// Final authoritative percentage.
  final double percentage;

  /// Official assigned letter grade symbol (e.g. 'A+', 'B', 'F').
  final String letterGrade;

  /// Whether this entry constitutes a passing grade according to policy.
  final bool isPassed;

  /// Whether this grade was officially published by authorized faculty.
  final bool isPublished;

  /// Whether this grade was modified via faculty override.
  final bool isOverridden;

  /// UTC timestamp when this grade was officially published.
  final DateTime? publishedAt;

  /// Faculty identifier who published the grade.
  final String? publishedBy;

  const AcademicRecordEntry({
    required this.assessmentId,
    required this.assessmentTitle,
    this.originalScore,
    required this.finalScore,
    required this.maxScore,
    required this.percentage,
    required this.letterGrade,
    required this.isPassed,
    required this.isPublished,
    this.isOverridden = false,
    this.publishedAt,
    this.publishedBy,
  });

  Map<String, dynamic> toJson() => {
        'assessmentId': assessmentId,
        'assessmentTitle': assessmentTitle,
        if (originalScore != null) 'originalScore': originalScore,
        'finalScore': finalScore,
        'maxScore': maxScore,
        'percentage': percentage,
        'letterGrade': letterGrade,
        'isPassed': isPassed,
        'isPublished': isPublished,
        'isOverridden': isOverridden,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        if (publishedBy != null) 'publishedBy': publishedBy,
      };

  factory AcademicRecordEntry.fromJson(Map<String, dynamic> json) =>
      AcademicRecordEntry(
        assessmentId: json['assessmentId'] as String? ?? '',
        assessmentTitle: json['assessmentTitle'] as String? ?? '',
        originalScore: (json['originalScore'] as num?)?.toDouble(),
        finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0.0,
        maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        letterGrade: json['letterGrade'] as String? ?? 'F',
        isPassed: json['isPassed'] as bool? ?? false,
        isPublished: json['isPublished'] as bool? ?? false,
        isOverridden: json['isOverridden'] as bool? ?? false,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String).toUtc()
            : null,
        publishedBy: json['publishedBy'] as String?,
      );
}

/// Official academic record aggregating authoritative published academic outcomes for a learner.
@immutable
class AcademicRecord {
  /// Unique canonical record identifier.
  final String recordId;

  /// Associated learner identifier.
  final String learnerId;

  /// Associated institutional tenant identifier.
  final String tenantId;

  /// Formal institution name.
  final String institutionName;

  /// Optional academic program or curriculum title.
  final String? programName;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Associated academic term or period (e.g. 'Term 1 2026').
  final String? academicPeriod;

  /// Stably sorted published entries.
  final List<AcademicRecordEntry> entries;

  /// Overall aggregated percentage across published assessments.
  final double overallPercentage;

  /// Overall aggregated letter grade symbol.
  final String overallGrade;

  /// Whether the learner has completed all requirements for this record.
  final bool isCompleted;

  /// Total count of published assessments included.
  final int totalAssessments;

  /// Total count of assessments passed.
  final int passedAssessments;

  /// UTC generation timestamp.
  final DateTime generatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AcademicRecord({
    required this.recordId,
    required this.learnerId,
    this.tenantId = 'default_tenant',
    this.institutionName = 'QuizForge Institute of Technology',
    this.programName,
    this.cohortId,
    this.academicPeriod,
    required List<AcademicRecordEntry> entries,
    required this.overallPercentage,
    required this.overallGrade,
    this.isCompleted = false,
    required this.totalAssessments,
    required this.passedAssessments,
    DateTime? generatedAt,
    Map<String, dynamic>? metadata,
  })  : generatedAt = (generatedAt ?? DateTime.now()).toUtc(),
        entries = List<AcademicRecordEntry>.unmodifiable(
          // Ensure deterministic stable sorting by assessmentId
          List<AcademicRecordEntry>.from(entries)
            ..sort((a, b) => a.assessmentId.compareTo(b.assessmentId)),
        ),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (recordId.trim().isEmpty) {
      throw ArgumentError('recordId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'learnerId': learnerId,
        'tenantId': tenantId,
        'institutionName': institutionName,
        if (programName != null) 'programName': programName,
        if (cohortId != null) 'cohortId': cohortId,
        if (academicPeriod != null) 'academicPeriod': academicPeriod,
        'entries': entries.map((e) => e.toJson()).toList(),
        'overallPercentage': overallPercentage,
        'overallGrade': overallGrade,
        'isCompleted': isCompleted,
        'totalAssessments': totalAssessments,
        'passedAssessments': passedAssessments,
        'generatedAt': generatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AcademicRecord.fromJson(Map<String, dynamic> json) => AcademicRecord(
        recordId: json['recordId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        institutionName: json['institutionName'] as String? ??
            'QuizForge Institute of Technology',
        programName: json['programName'] as String?,
        cohortId: json['cohortId'] as String?,
        academicPeriod: json['academicPeriod'] as String?,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) =>
                    AcademicRecordEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        overallPercentage:
            (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
        overallGrade: json['overallGrade'] as String? ?? 'F',
        isCompleted: json['isCompleted'] as bool? ?? false,
        totalAssessments: (json['totalAssessments'] as num?)?.toInt() ?? 0,
        passedAssessments: (json['passedAssessments'] as num?)?.toInt() ?? 0,
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );
}
