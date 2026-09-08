/// Grade Dispute Domain Entities (TITAN-KO-050.0 P50).
///
/// Production models managing learner grade disputes, review states,
/// faculty resolution paths, and pedagogical rationale.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle states for a grade dispute.
enum GradeDisputeStatus {
  open,
  underReview,
  resolved,
  rejected,
}

/// Category of dispute resolution executed by faculty.
enum GradeDisputeResolutionType {
  approvedWithOverride,
  rejected,
  dismissed,
}

/// Immutable entity representing a learner's dispute of an official published grade.
@immutable
class GradeDispute {
  /// Unique canonical dispute identifier.
  final String disputeId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target cohort identifier.
  final String cohortId;

  /// Enrolled learner identifier.
  final String learnerId;

  /// Associated assessment identifier.
  final String assessmentId;

  /// Linked assessment evaluation result identifier.
  final String resultId;

  /// Linked gradebook entry identifier.
  final String entryId;

  /// Learner-provided justification/rationale for the dispute.
  final String reason;

  /// Current lifecycle state.
  final GradeDisputeStatus status;

  /// Resolution category once determined.
  final GradeDisputeResolutionType? resolutionType;

  /// Faculty notes or justification regarding the resolution.
  final String? resolutionNotes;

  /// Identifier of the reviewing faculty member.
  final String? reviewerFacultyId;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC timestamp when review began.
  final DateTime? reviewedAt;

  /// UTC timestamp when dispute was resolved/rejected.
  final DateTime? resolvedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  GradeDispute({
    required this.disputeId,
    this.tenantId = 'default_tenant',
    required this.cohortId,
    required this.learnerId,
    required this.assessmentId,
    required this.resultId,
    required this.entryId,
    required this.reason,
    this.status = GradeDisputeStatus.open,
    this.resolutionType,
    this.resolutionNotes,
    this.reviewerFacultyId,
    DateTime? createdAt,
    this.reviewedAt,
    this.resolvedAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (disputeId.trim().isEmpty) {
      throw ArgumentError('disputeId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty');
    }
    if (entryId.trim().isEmpty) {
      throw ArgumentError('entryId cannot be empty');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Dispute reason cannot be empty');
    }
  }

  /// Whether the dispute is active and awaiting faculty determination.
  bool get isPending =>
      status == GradeDisputeStatus.open ||
      status == GradeDisputeStatus.underReview;

  /// Transitions dispute state to [underReview].
  GradeDispute startReview({
    required String facultyId,
    DateTime? reviewedAt,
  }) {
    if (status != GradeDisputeStatus.open) {
      return this; // Idempotent or already under review
    }
    return copyWith(
      status: GradeDisputeStatus.underReview,
      reviewerFacultyId: facultyId.trim(),
      reviewedAt: (reviewedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Resolves the dispute with an approved grade override.
  GradeDispute resolveWithOverride({
    required String facultyId,
    required String notes,
    DateTime? resolvedAt,
  }) {
    final now = (resolvedAt ?? DateTime.now()).toUtc();
    return copyWith(
      status: GradeDisputeStatus.resolved,
      resolutionType: GradeDisputeResolutionType.approvedWithOverride,
      resolutionNotes: notes.trim(),
      reviewerFacultyId: facultyId.trim(),
      resolvedAt: now,
    );
  }

  /// Rejects the dispute with faculty justification.
  GradeDispute reject({
    required String facultyId,
    required String notes,
    DateTime? resolvedAt,
  }) {
    final cleanNotes = notes.trim();
    if (cleanNotes.isEmpty) {
      throw ArgumentError('Rejection notes cannot be empty');
    }
    final now = (resolvedAt ?? DateTime.now()).toUtc();
    return copyWith(
      status: GradeDisputeStatus.rejected,
      resolutionType: GradeDisputeResolutionType.rejected,
      resolutionNotes: cleanNotes,
      reviewerFacultyId: facultyId.trim(),
      resolvedAt: now,
    );
  }

  GradeDispute copyWith({
    String? disputeId,
    String? tenantId,
    String? cohortId,
    String? learnerId,
    String? assessmentId,
    String? resultId,
    String? entryId,
    String? reason,
    GradeDisputeStatus? status,
    GradeDisputeResolutionType? resolutionType,
    String? resolutionNotes,
    String? reviewerFacultyId,
    DateTime? createdAt,
    DateTime? reviewedAt,
    DateTime? resolvedAt,
    Map<String, dynamic>? metadata,
  }) {
    return GradeDispute(
      disputeId: disputeId ?? this.disputeId,
      tenantId: tenantId ?? this.tenantId,
      cohortId: cohortId ?? this.cohortId,
      learnerId: learnerId ?? this.learnerId,
      assessmentId: assessmentId ?? this.assessmentId,
      resultId: resultId ?? this.resultId,
      entryId: entryId ?? this.entryId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      resolutionType: resolutionType ?? this.resolutionType,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      reviewerFacultyId: reviewerFacultyId ?? this.reviewerFacultyId,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'disputeId': disputeId,
        'tenantId': tenantId,
        'cohortId': cohortId,
        'learnerId': learnerId,
        'assessmentId': assessmentId,
        'resultId': resultId,
        'entryId': entryId,
        'reason': reason,
        'status': status.name,
        if (resolutionType != null) 'resolutionType': resolutionType!.name,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
        if (reviewerFacultyId != null) 'reviewerFacultyId': reviewerFacultyId,
        'createdAt': createdAt.toIso8601String(),
        if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
        'metadata': metadata,
      };

  factory GradeDispute.fromJson(Map<String, dynamic> json) => GradeDispute(
        disputeId: json['disputeId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        cohortId: json['cohortId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        resultId: json['resultId'] as String? ?? '',
        entryId: json['entryId'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        status: GradeDisputeStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GradeDisputeStatus.open,
        ),
        resolutionType: json['resolutionType'] != null
            ? GradeDisputeResolutionType.values.firstWhere(
                (e) => e.name == json['resolutionType'],
                orElse: () => GradeDisputeResolutionType.rejected,
              )
            : null,
        resolutionNotes: json['resolutionNotes'] as String?,
        reviewerFacultyId: json['reviewerFacultyId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : null,
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.parse(json['reviewedAt'] as String).toUtc()
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeDispute &&
          disputeId == other.disputeId &&
          tenantId == other.tenantId &&
          cohortId == other.cohortId &&
          learnerId == other.learnerId &&
          assessmentId == other.assessmentId &&
          resultId == other.resultId &&
          status == other.status &&
          resolutionType == other.resolutionType;

  @override
  int get hashCode => Object.hash(
        disputeId,
        tenantId,
        cohortId,
        learnerId,
        assessmentId,
        resultId,
        status,
        resolutionType,
      );

  @override
  String toString() =>
      'GradeDispute(id: $disputeId, learner: $learnerId, assessment: $assessmentId, status: ${status.name})';
}
