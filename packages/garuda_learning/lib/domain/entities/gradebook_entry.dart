/// Gradebook Entry Domain Entities (TITAN-KO-050.0 P50).
///
/// Production models representing cohort gradebook entries, official grades,
/// evaluation tracking, publication lifecycle, and override state.
library;

import 'package:meta/meta.dart';

/// Explicit status of a learner's progression towards a grade on an assessment.
enum GradingStatus {
  notAttempted,
  inProgress,
  submitted,
  evaluated,
  published,
}

/// Official publication state of an assessment grade.
enum GradePublicationStatus {
  unpublished,
  published,
}

/// Immutable record representing a single assessment grade entry for a learner in a cohort.
@immutable
class GradebookEntry {
  /// Canonical entry identifier (e.g. 'grade_cohort1_assess1_learner1').
  final String entryId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target institutional cohort identifier.
  final String cohortId;

  /// Associated formal assessment identifier.
  final String assessmentId;

  /// Enrolled learner identifier.
  final String learnerId;

  /// Associated attempt identifier (if attempted).
  final String? attemptId;

  /// Linked raw P49 assessment result identifier (if evaluated).
  final String? resultId;

  /// Immutable raw score originally evaluated by the assessment engine.
  final double? originalScore;

  /// Total maximum marks possible for the assessment.
  final double? originalMaxScore;

  /// Immutable raw percentage originally evaluated.
  final double? originalPercentage;

  /// Current official score (equals originalScore unless overridden).
  final double? finalScore;

  /// Total maximum marks for official score.
  final double? finalMaxScore;

  /// Current official percentage (equals originalPercentage unless overridden).
  final double? finalPercentage;

  /// Calculated or overridden letter grade symbol (e.g. 'A+', 'B', 'F').
  final String? letterGrade;

  /// Overall grading workflow status.
  final GradingStatus gradingStatus;

  /// Explicit publication status.
  final GradePublicationStatus publicationStatus;

  /// Whether faculty has applied a score/grade override.
  final bool isOverridden;

  /// UTC timestamp when an override was applied.
  final DateTime? lastOverriddenAt;

  /// Mandatory pedagogical or administrative rationale for the override.
  final String? overrideReason;

  /// Identifier of the faculty member who executed the override.
  final String? overrideFacultyId;

  /// UTC timestamp when the grade was officially published.
  final DateTime? publishedAt;

  /// Identifier of the faculty member who published the grade.
  final String? publishedByFacultyId;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last updated timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  GradebookEntry({
    required this.entryId,
    this.tenantId = 'default_tenant',
    required this.cohortId,
    required this.assessmentId,
    required this.learnerId,
    this.attemptId,
    this.resultId,
    this.originalScore,
    this.originalMaxScore,
    this.originalPercentage,
    this.finalScore,
    this.finalMaxScore,
    this.finalPercentage,
    this.letterGrade,
    this.gradingStatus = GradingStatus.notAttempted,
    this.publicationStatus = GradePublicationStatus.unpublished,
    this.isOverridden = false,
    this.lastOverriddenAt,
    this.overrideReason,
    this.overrideFacultyId,
    this.publishedAt,
    this.publishedByFacultyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (entryId.trim().isEmpty) {
      throw ArgumentError('entryId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
  }

  /// Whether this grade is officially published and visible to the learner.
  bool get isPublished => publicationStatus == GradePublicationStatus.published;
  bool get isPassed => letterGrade != null && letterGrade != 'F';
  String? get publishedBy => publishedByFacultyId;
  double get maxScore => finalMaxScore ?? originalMaxScore ?? 100.0;
  double get score => finalScore ?? originalScore ?? 0.0;
  double get percentage => finalPercentage ?? originalPercentage ?? 0.0;
  String get grade => letterGrade ?? 'F';

  /// Generates a standard canonical entry ID from coordinates.
  static String generateId({
    required String cohortId,
    required String assessmentId,
    required String learnerId,
  }) =>
      'grade_${cohortId.trim()}_${assessmentId.trim()}_${learnerId.trim()}';

  /// Returns a published copy of this entry.
  GradebookEntry publish({
    required String facultyId,
    DateTime? publishedAt,
  }) {
    final now = (publishedAt ?? DateTime.now()).toUtc();
    return copyWith(
      gradingStatus: GradingStatus.published,
      publicationStatus: GradePublicationStatus.published,
      publishedAt: now,
      publishedByFacultyId: facultyId.trim(),
      updatedAt: now,
    );
  }

  /// Returns an un-published copy of this entry.
  GradebookEntry unpublish({DateTime? updatedAt}) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return copyWith(
      gradingStatus: GradingStatus.evaluated,
      publicationStatus: GradePublicationStatus.unpublished,
      publishedAt: null,
      publishedByFacultyId: null,
      updatedAt: now,
    );
  }

  /// Returns a copy with faculty grade override applied while preserving original scores.
  GradebookEntry applyOverride({
    required double newScore,
    required double newPercentage,
    required String newGrade,
    required String reason,
    required String facultyId,
    String? disputeId,
    DateTime? overriddenAt,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Override reason cannot be empty');
    }
    final now = (overriddenAt ?? DateTime.now()).toUtc();

    return copyWith(
      finalScore: newScore,
      finalPercentage: newPercentage,
      letterGrade: newGrade,
      isOverridden: true,
      lastOverriddenAt: now,
      overrideReason: cleanReason,
      overrideFacultyId: facultyId.trim(),
      updatedAt: now,
    );
  }

  GradebookEntry copyWith({
    String? entryId,
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    String? attemptId,
    String? resultId,
    double? originalScore,
    double? originalMaxScore,
    double? originalPercentage,
    double? finalScore,
    double? finalMaxScore,
    double? finalPercentage,
    String? letterGrade,
    GradingStatus? gradingStatus,
    GradePublicationStatus? publicationStatus,
    bool? isOverridden,
    DateTime? lastOverriddenAt,
    String? overrideReason,
    String? overrideFacultyId,
    DateTime? publishedAt,
    String? publishedByFacultyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return GradebookEntry(
      entryId: entryId ?? this.entryId,
      tenantId: tenantId ?? this.tenantId,
      cohortId: cohortId ?? this.cohortId,
      assessmentId: assessmentId ?? this.assessmentId,
      learnerId: learnerId ?? this.learnerId,
      attemptId: attemptId ?? this.attemptId,
      resultId: resultId ?? this.resultId,
      originalScore: originalScore ?? this.originalScore,
      originalMaxScore: originalMaxScore ?? this.originalMaxScore,
      originalPercentage: originalPercentage ?? this.originalPercentage,
      finalScore: finalScore ?? this.finalScore,
      finalMaxScore: finalMaxScore ?? this.finalMaxScore,
      finalPercentage: finalPercentage ?? this.finalPercentage,
      letterGrade: letterGrade ?? this.letterGrade,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      isOverridden: isOverridden ?? this.isOverridden,
      lastOverriddenAt: lastOverriddenAt ?? this.lastOverriddenAt,
      overrideReason: overrideReason ?? this.overrideReason,
      overrideFacultyId: overrideFacultyId ?? this.overrideFacultyId,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedByFacultyId: publishedByFacultyId ?? this.publishedByFacultyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'tenantId': tenantId,
        'cohortId': cohortId,
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        if (attemptId != null) 'attemptId': attemptId,
        if (resultId != null) 'resultId': resultId,
        if (originalScore != null) 'originalScore': originalScore,
        if (originalMaxScore != null) 'originalMaxScore': originalMaxScore,
        if (originalPercentage != null)
          'originalPercentage': originalPercentage,
        if (finalScore != null) 'finalScore': finalScore,
        if (finalMaxScore != null) 'finalMaxScore': finalMaxScore,
        if (finalPercentage != null) 'finalPercentage': finalPercentage,
        if (letterGrade != null) 'letterGrade': letterGrade,
        'gradingStatus': gradingStatus.name,
        'publicationStatus': publicationStatus.name,
        'isOverridden': isOverridden,
        if (lastOverriddenAt != null)
          'lastOverriddenAt': lastOverriddenAt!.toIso8601String(),
        if (overrideReason != null) 'overrideReason': overrideReason,
        if (overrideFacultyId != null) 'overrideFacultyId': overrideFacultyId,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        if (publishedByFacultyId != null)
          'publishedByFacultyId': publishedByFacultyId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory GradebookEntry.fromJson(Map<String, dynamic> json) => GradebookEntry(
        entryId: json['entryId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        cohortId: json['cohortId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        attemptId: json['attemptId'] as String?,
        resultId: json['resultId'] as String?,
        originalScore: (json['originalScore'] as num?)?.toDouble(),
        originalMaxScore: (json['originalMaxScore'] as num?)?.toDouble(),
        originalPercentage: (json['originalPercentage'] as num?)?.toDouble(),
        finalScore: (json['finalScore'] as num?)?.toDouble(),
        finalMaxScore: (json['finalMaxScore'] as num?)?.toDouble(),
        finalPercentage: (json['finalPercentage'] as num?)?.toDouble(),
        letterGrade: json['letterGrade'] as String?,
        gradingStatus: GradingStatus.values.firstWhere(
          (e) => e.name == json['gradingStatus'],
          orElse: () => GradingStatus.notAttempted,
        ),
        publicationStatus: GradePublicationStatus.values.firstWhere(
          (e) => e.name == json['publicationStatus'],
          orElse: () => GradePublicationStatus.unpublished,
        ),
        isOverridden: json['isOverridden'] as bool? ?? false,
        lastOverriddenAt: json['lastOverriddenAt'] != null
            ? DateTime.parse(json['lastOverriddenAt'] as String).toUtc()
            : null,
        overrideReason: json['overrideReason'] as String?,
        overrideFacultyId: json['overrideFacultyId'] as String?,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String).toUtc()
            : null,
        publishedByFacultyId: json['publishedByFacultyId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookEntry &&
          entryId == other.entryId &&
          tenantId == other.tenantId &&
          cohortId == other.cohortId &&
          assessmentId == other.assessmentId &&
          learnerId == other.learnerId &&
          finalScore == other.finalScore &&
          letterGrade == other.letterGrade &&
          gradingStatus == other.gradingStatus &&
          publicationStatus == other.publicationStatus &&
          isOverridden == other.isOverridden;

  @override
  int get hashCode => Object.hash(
        entryId,
        tenantId,
        cohortId,
        assessmentId,
        learnerId,
        finalScore,
        letterGrade,
        gradingStatus,
        publicationStatus,
        isOverridden,
      );

  @override
  String toString() =>
      'GradebookEntry(id: $entryId, learner: $learnerId, assessment: $assessmentId, score: $finalScore, grade: $letterGrade, status: ${gradingStatus.name}, published: $isPublished)';
}
