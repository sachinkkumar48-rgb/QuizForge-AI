/// Course & Program Domain Entities (TITAN-KO-052.0 P52).
///
/// Production domain models representing institutional courses, curricula programs,
/// prerequisites, and cohort associations.
library;

import 'package:meta/meta.dart';

/// Explicit status for an institutional course or program.
enum CourseStatus {
  active,
  archived,
}

/// Immutable domain model representing an institutional course/program offering.
@immutable
class Course {
  /// Unique canonical course identifier (e.g. 'course_const_law_101').
  final String courseId;

  /// Human-readable course title.
  final String title;

  /// Course syllabus description and learning objectives overview.
  final String description;

  /// Target curriculum exam context (e.g. 'clat_pg_2026', 'upsc_prelims_gs1').
  final String examId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Lead instructor / faculty member identifier.
  final String facultyId;

  /// Optional prerequisite course identifiers required prior to active enrollment.
  final List<String> prerequisiteCourseIds;

  /// Cohort identifiers associated with this course.
  final Set<String> cohortIds;

  /// Current offering status.
  final CourseStatus status;

  /// Estimated study duration in hours.
  final int estimatedHours;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last update timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  Course({
    required this.courseId,
    required this.title,
    this.description = '',
    required this.examId,
    this.tenantId = 'default_tenant',
    required this.facultyId,
    Iterable<String>? prerequisiteCourseIds,
    Iterable<String>? cohortIds,
    this.status = CourseStatus.active,
    this.estimatedHours = 40,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : prerequisiteCourseIds = List<String>.unmodifiable(
          (prerequisiteCourseIds ?? const <String>[])
              .where((id) => id.trim().isNotEmpty),
        ),
        cohortIds = Set<String>.unmodifiable(
          (cohortIds ?? const <String>[]).where((id) => id.trim().isNotEmpty),
        ),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (facultyId.trim().isEmpty) {
      throw ArgumentError('facultyId cannot be empty');
    }
    if (estimatedHours < 0) {
      throw ArgumentError('estimatedHours must be non-negative');
    }
  }

  bool get isActive => status == CourseStatus.active;
  bool get isArchived => status == CourseStatus.archived;

  Course copyWith({
    String? courseId,
    String? title,
    String? description,
    String? examId,
    String? tenantId,
    String? facultyId,
    List<String>? prerequisiteCourseIds,
    Set<String>? cohortIds,
    CourseStatus? status,
    int? estimatedHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Course(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      examId: examId ?? this.examId,
      tenantId: tenantId ?? this.tenantId,
      facultyId: facultyId ?? this.facultyId,
      prerequisiteCourseIds:
          prerequisiteCourseIds ?? this.prerequisiteCourseIds,
      cohortIds: cohortIds ?? this.cohortIds,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'title': title,
        'description': description,
        'examId': examId,
        'tenantId': tenantId,
        'facultyId': facultyId,
        'prerequisiteCourseIds': prerequisiteCourseIds,
        'cohortIds': cohortIds.toList(),
        'status': status.name,
        'estimatedHours': estimatedHours,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        courseId: json['courseId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        facultyId: json['facultyId'] as String? ?? '',
        prerequisiteCourseIds: (json['prerequisiteCourseIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        cohortIds: (json['cohortIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            const {},
        status: CourseStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CourseStatus.active,
        ),
        estimatedHours: (json['estimatedHours'] as num?)?.toInt() ?? 40,
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
      other is Course &&
          courseId == other.courseId &&
          tenantId == other.tenantId &&
          examId == other.examId;

  @override
  int get hashCode => Object.hash(courseId, tenantId, examId);

  @override
  String toString() =>
      'Course(id: $courseId, title: $title, status: ${status.name})';
}
