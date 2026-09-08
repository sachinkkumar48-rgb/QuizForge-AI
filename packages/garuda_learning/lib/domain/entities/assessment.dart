/// Assessment Domain Entities (TITAN-KO-049.0 P49).
///
/// Production models representing formal examinations, summative tests,
/// scoring rules, scheduling windows, and cohort distribution.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle states of an assessment.
enum AssessmentStatus {
  draft,
  published,
  open,
  closed,
}

/// Scoring and penalty configuration for an assessment.
@immutable
class AssessmentMarksConfig {
  /// Base marks awarded for a correct answer.
  final double marksPerQuestion;

  /// Ratio of penalty subtracted for an incorrect answer (e.g. 0.333 for 1/3 penalty).
  final double negativeMarkRatio;

  /// Passing percentage threshold (e.g. 40.0 for 40%).
  final double passingPercentage;

  const AssessmentMarksConfig({
    this.marksPerQuestion = 2.0,
    this.negativeMarkRatio = 0.333,
    this.passingPercentage = 40.0,
  })  : assert(
            marksPerQuestion >= 0.0, 'marksPerQuestion must be non-negative'),
        assert(negativeMarkRatio >= 0.0 && negativeMarkRatio <= 1.0,
            'negativeMarkRatio must be in range [0.0, 1.0]'),
        assert(passingPercentage >= 0.0 && passingPercentage <= 100.0,
            'passingPercentage must be in range [0.0, 100.0]');

  /// Penalty deducted per incorrect question.
  double get negativePenaltyPerQuestion => marksPerQuestion * negativeMarkRatio;

  Map<String, dynamic> toJson() => {
        'marksPerQuestion': marksPerQuestion,
        'negativeMarkRatio': negativeMarkRatio,
        'passingPercentage': passingPercentage,
      };

  factory AssessmentMarksConfig.fromJson(Map<String, dynamic> json) =>
      AssessmentMarksConfig(
        marksPerQuestion: (json['marksPerQuestion'] as num?)?.toDouble() ?? 2.0,
        negativeMarkRatio:
            (json['negativeMarkRatio'] as num?)?.toDouble() ?? 0.333,
        passingPercentage:
            (json['passingPercentage'] as num?)?.toDouble() ?? 40.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentMarksConfig &&
          marksPerQuestion == other.marksPerQuestion &&
          negativeMarkRatio == other.negativeMarkRatio &&
          passingPercentage == other.passingPercentage;

  @override
  int get hashCode =>
      Object.hash(marksPerQuestion, negativeMarkRatio, passingPercentage);
}

/// Timing and availability configuration for an assessment.
@immutable
class AssessmentTimingConfig {
  /// Test duration in minutes (null for untimed assessments).
  final int? durationMinutes;

  /// Optional scheduled UTC start window.
  final DateTime? startsAt;

  /// Optional scheduled UTC close window.
  final DateTime? endsAt;

  const AssessmentTimingConfig({
    this.durationMinutes,
    this.startsAt,
    this.endsAt,
  }) : assert(durationMinutes == null || durationMinutes > 0,
            'durationMinutes must be strictly positive');

  /// Whether the assessment is currently open relative to [asOfDate].
  bool isOpen(DateTime asOfDate) {
    final now = asOfDate.toUtc();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  /// Whether an ongoing attempt started at [startedAt] has exceeded the permitted duration.
  bool isExpired(DateTime startedAt, DateTime asOfDate) {
    if (durationMinutes == null) return false;
    final limit = startedAt.toUtc().add(Duration(minutes: durationMinutes!));
    return asOfDate.toUtc().isAfter(limit);
  }

  Map<String, dynamic> toJson() => {
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (startsAt != null) 'startsAt': startsAt!.toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt!.toIso8601String(),
      };

  factory AssessmentTimingConfig.fromJson(Map<String, dynamic> json) =>
      AssessmentTimingConfig(
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        startsAt: json['startsAt'] != null
            ? DateTime.parse(json['startsAt'] as String).toUtc()
            : null,
        endsAt: json['endsAt'] != null
            ? DateTime.parse(json['endsAt'] as String).toUtc()
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentTimingConfig &&
          durationMinutes == other.durationMinutes &&
          startsAt == other.startsAt &&
          endsAt == other.endsAt;

  @override
  int get hashCode => Object.hash(durationMinutes, startsAt, endsAt);
}

/// Immutable entity representing a formal assessment or examination.
@immutable
class Assessment {
  /// Unique canonical assessment identifier.
  final String assessmentId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Human-readable title of assessment.
  final String title;

  /// Comprehensive description / instructions.
  final String description;

  /// Associated curriculum exam (e.g. 'upsc_prelims_gs1').
  final String examId;

  /// Optional subject identifier.
  final String? subjectId;

  /// Optional topic identifier.
  final String? topicId;

  /// Creator faculty ID.
  final String creatorFacultyId;

  /// Ordered references to real existing questions.
  final List<String> questionIds;

  /// Marks configuration.
  final AssessmentMarksConfig marksConfig;

  /// Timing and scheduling rules.
  final AssessmentTimingConfig timingConfig;

  /// Maximum permitted attempts per learner (default 1).
  final int maxAttempts;

  /// Lifecycle status.
  final AssessmentStatus status;

  /// Enrolled cohort IDs eligible for this assessment.
  final Set<String> cohortIds;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last updated timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  Assessment({
    required this.assessmentId,
    this.tenantId = 'default_tenant',
    required this.title,
    this.description = '',
    required this.examId,
    this.subjectId,
    this.topicId,
    required this.creatorFacultyId,
    Iterable<String>? questionIds,
    this.marksConfig = const AssessmentMarksConfig(),
    this.timingConfig = const AssessmentTimingConfig(),
    this.maxAttempts = 1,
    this.status = AssessmentStatus.draft,
    Iterable<String>? cohortIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : questionIds = List<String>.unmodifiable(
            (questionIds ?? const <String>[])
                .where((q) => q.trim().isNotEmpty)),
        cohortIds = Set<String>.unmodifiable(
            (cohortIds ?? const <String>[]).where((c) => c.trim().isNotEmpty)),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (creatorFacultyId.trim().isEmpty) {
      throw ArgumentError('creatorFacultyId cannot be empty');
    }
    if (maxAttempts < 1) {
      throw ArgumentError('maxAttempts must be at least 1');
    }
  }

  /// Total questions configured.
  int get questionCount => questionIds.length;

  /// Total maximum marks possible.
  double get totalMarks => questionCount * marksConfig.marksPerQuestion;

  /// Whether the assessment is visible to learners (not in draft).
  bool get isVisibleToLearners => status != AssessmentStatus.draft;

  /// Whether the assessment can be attempted as of [asOfDate].
  bool isAvailable(DateTime asOfDate) {
    if (status != AssessmentStatus.published &&
        status != AssessmentStatus.open) {
      return false;
    }
    return timingConfig.isOpen(asOfDate);
  }

  /// Whether [cohortId] is assigned.
  bool hasCohort(String cohortId) => cohortIds.contains(cohortId.trim());

  Assessment copyWith({
    String? assessmentId,
    String? tenantId,
    String? title,
    String? description,
    String? examId,
    String? subjectId,
    String? topicId,
    String? creatorFacultyId,
    Iterable<String>? questionIds,
    AssessmentMarksConfig? marksConfig,
    AssessmentTimingConfig? timingConfig,
    int? maxAttempts,
    AssessmentStatus? status,
    Iterable<String>? cohortIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Assessment(
      assessmentId: assessmentId ?? this.assessmentId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      examId: examId ?? this.examId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      creatorFacultyId: creatorFacultyId ?? this.creatorFacultyId,
      questionIds: questionIds ?? this.questionIds,
      marksConfig: marksConfig ?? this.marksConfig,
      timingConfig: timingConfig ?? this.timingConfig,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
      cohortIds: cohortIds ?? this.cohortIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'assessmentId': assessmentId,
        'tenantId': tenantId,
        'title': title,
        'description': description,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        if (topicId != null) 'topicId': topicId,
        'creatorFacultyId': creatorFacultyId,
        'questionIds': questionIds,
        'marksConfig': marksConfig.toJson(),
        'timingConfig': timingConfig.toJson(),
        'maxAttempts': maxAttempts,
        'status': status.name,
        'cohortIds': cohortIds.toList()..sort(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        assessmentId: json['assessmentId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        subjectId: json['subjectId'] as String?,
        topicId: json['topicId'] as String?,
        creatorFacultyId: json['creatorFacultyId'] as String? ?? '',
        questionIds:
            (json['questionIds'] as List<dynamic>?)?.map((e) => e.toString()) ??
                const [],
        marksConfig: json['marksConfig'] != null
            ? AssessmentMarksConfig.fromJson(
                Map<String, dynamic>.from(json['marksConfig'] as Map))
            : const AssessmentMarksConfig(),
        timingConfig: json['timingConfig'] != null
            ? AssessmentTimingConfig.fromJson(
                Map<String, dynamic>.from(json['timingConfig'] as Map))
            : const AssessmentTimingConfig(),
        maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 1,
        status: AssessmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AssessmentStatus.draft,
        ),
        cohortIds:
            (json['cohortIds'] as List<dynamic>?)?.map((e) => e.toString()) ??
                const [],
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
      other is Assessment &&
          assessmentId == other.assessmentId &&
          tenantId == other.tenantId &&
          title == other.title &&
          examId == other.examId &&
          creatorFacultyId == other.creatorFacultyId &&
          status == other.status &&
          marksConfig == other.marksConfig &&
          timingConfig == other.timingConfig;

  @override
  int get hashCode => Object.hash(
        assessmentId,
        tenantId,
        title,
        examId,
        creatorFacultyId,
        status,
      );

  @override
  String toString() =>
      'Assessment(id: $assessmentId, title: "$title", questions: ${questionIds.length}, status: ${status.name})';
}
