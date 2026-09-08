/// Institutional Cohort Entity (TITAN-KO-048.0 P48).
///
/// Immutable domain model representing a student batch, class, or institutional cohort.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle status of a cohort.
enum CohortStatus {
  draft,
  active,
  archived,
}

/// Immutable entity representing an institutional cohort.
@immutable
class Cohort {
  /// Unique canonical cohort identifier (e.g. `cohort_upsc_2026_a`).
  final String cohortId;

  /// Institution / Tenant identifier for multi-tenant isolation.
  final String tenantId;

  /// Display name of the cohort (e.g. 'UPSC 2026 Batch A').
  final String name;

  /// Detailed description or batch purpose.
  final String description;

  /// Associated curriculum exam (e.g. 'upsc_prelims_gs1').
  final String examId;

  /// Primary faculty owner ID.
  final String primaryFacultyId;

  /// Set of additional faculty / instructor IDs with management privileges.
  final Set<String> additionalFacultyIds;

  /// Set of enrolled learner IDs.
  final Set<String> learnerIds;

  /// Current lifecycle status.
  final CohortStatus status;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last updated timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  Cohort({
    required this.cohortId,
    this.tenantId = 'default_tenant',
    required this.name,
    this.description = '',
    required this.examId,
    required this.primaryFacultyId,
    Iterable<String>? additionalFacultyIds,
    Iterable<String>? learnerIds,
    this.status = CohortStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : additionalFacultyIds = Set<String>.unmodifiable(
          (additionalFacultyIds ?? const <String>[])
              .where((s) => s.trim().isNotEmpty),
        ),
        learnerIds = Set<String>.unmodifiable(
          (learnerIds ?? const <String>[]).where((s) => s.trim().isNotEmpty),
        ),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('cohort name cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (primaryFacultyId.trim().isEmpty) {
      throw ArgumentError('primaryFacultyId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
  }

  /// All faculty IDs responsible for this cohort.
  Set<String> get allFacultyIds => {
        primaryFacultyId,
        ...additionalFacultyIds,
      };

  /// Whether [facultyId] is assigned to this cohort.
  bool hasFaculty(String facultyId) => allFacultyIds.contains(facultyId.trim());

  /// Whether [learnerId] is an enrolled member.
  bool hasLearner(String learnerId) => learnerIds.contains(learnerId.trim());

  /// Number of enrolled learners.
  int get learnerCount => learnerIds.length;

  /// Returns a new copy with the given learner added (idempotent).
  Cohort addLearner(String learnerId, {DateTime? updatedAt}) {
    final clean = learnerId.trim();
    if (clean.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (learnerIds.contains(clean)) {
      return this;
    }
    return copyWith(
      learnerIds: {...learnerIds, clean},
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Returns a new copy with the given learner removed.
  Cohort removeLearner(String learnerId, {DateTime? updatedAt}) {
    final clean = learnerId.trim();
    if (!learnerIds.contains(clean)) {
      return this;
    }
    final next = Set<String>.from(learnerIds)..remove(clean);
    return copyWith(
      learnerIds: next,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Returns a new copy with the given faculty member added.
  Cohort addFaculty(String facultyId,
      {bool isPrimary = false, DateTime? updatedAt}) {
    final clean = facultyId.trim();
    if (clean.isEmpty) {
      throw ArgumentError('facultyId cannot be empty');
    }
    final now = (updatedAt ?? DateTime.now()).toUtc();
    if (isPrimary) {
      final nextAdditional = Set<String>.from(additionalFacultyIds)
        ..remove(clean);
      if (primaryFacultyId.isNotEmpty && primaryFacultyId != clean) {
        nextAdditional.add(primaryFacultyId);
      }
      return copyWith(
        primaryFacultyId: clean,
        additionalFacultyIds: nextAdditional,
        updatedAt: now,
      );
    } else {
      if (primaryFacultyId == clean) return this;
      return copyWith(
        additionalFacultyIds: {...additionalFacultyIds, clean},
        updatedAt: now,
      );
    }
  }

  Cohort copyWith({
    String? cohortId,
    String? tenantId,
    String? name,
    String? description,
    String? examId,
    String? primaryFacultyId,
    Iterable<String>? additionalFacultyIds,
    Iterable<String>? learnerIds,
    CohortStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Cohort(
      cohortId: cohortId ?? this.cohortId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      examId: examId ?? this.examId,
      primaryFacultyId: primaryFacultyId ?? this.primaryFacultyId,
      additionalFacultyIds: additionalFacultyIds ?? this.additionalFacultyIds,
      learnerIds: learnerIds ?? this.learnerIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'cohortId': cohortId,
        'tenantId': tenantId,
        'name': name,
        'description': description,
        'examId': examId,
        'primaryFacultyId': primaryFacultyId,
        'additionalFacultyIds': additionalFacultyIds.toList()..sort(),
        'learnerIds': learnerIds.toList()..sort(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      cohortId: json['cohortId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? 'default_tenant',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      primaryFacultyId: json['primaryFacultyId'] as String? ?? '',
      additionalFacultyIds: (json['additionalFacultyIds'] as List<dynamic>?)
              ?.map((e) => e.toString()) ??
          const [],
      learnerIds:
          (json['learnerIds'] as List<dynamic>?)?.map((e) => e.toString()) ??
              const [],
      status: CohortStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CohortStatus.active,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toUtc()
          : null,
      metadata: Map<String, dynamic>.from(
          json['metadata'] as Map? ?? const <String, dynamic>{}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cohort &&
          cohortId == other.cohortId &&
          tenantId == other.tenantId &&
          name == other.name &&
          description == other.description &&
          examId == other.examId &&
          primaryFacultyId == other.primaryFacultyId &&
          status == other.status &&
          _setEquals(additionalFacultyIds, other.additionalFacultyIds) &&
          _setEquals(learnerIds, other.learnerIds);

  @override
  int get hashCode => Object.hash(
        cohortId,
        tenantId,
        name,
        examId,
        primaryFacultyId,
        status,
      );

  @override
  String toString() =>
      'Cohort(id: $cohortId, name: $name, exam: $examId, learners: ${learnerIds.length})';

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
