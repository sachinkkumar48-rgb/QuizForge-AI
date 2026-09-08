/// Objective Mastery Progression Decision Domain Entity (TITAN-KO-043.0 P43).
///
/// Encapsulates deterministic, evidence-backed progression decisions for individual
/// curriculum learning objectives within QuizForge AI LMS.
library;

import 'package:meta/meta.dart';

import 'objective_mastery_status.dart';

/// Discrete progression stage of an objective across the adaptive learning lifecycle.
enum ProgressionStage {
  /// Zero attempts have been recorded for this objective.
  notStarted,

  /// Attempts recorded, but below statistical minimum required for confident placement.
  insufficientEvidence,

  /// In active practice; performance demonstrates developing competence (50% - 64%).
  learning,

  /// Demonstrates solid positive trend approaching mastery threshold (65% - 79%).
  improving,

  /// Fully meets mastery standards with sufficient evidence (>= 80% accuracy, >= 3 attempts).
  mastered,

  /// Material weakness diagnosed; requires targeted remedial intervention (< 50% accuracy).
  remediationRequired,

  /// Previously achieved objective where retention has fallen below passing threshold.
  regressed;

  bool get isMastered => this == ProgressionStage.mastered;
  bool get isStruggling =>
      this == ProgressionStage.remediationRequired ||
      this == ProgressionStage.regressed;
  bool get hasEvidence => this != ProgressionStage.notStarted;

  String get displayName {
    switch (this) {
      case ProgressionStage.notStarted:
        return 'Not Started';
      case ProgressionStage.insufficientEvidence:
        return 'Insufficient Evidence';
      case ProgressionStage.learning:
        return 'Learning';
      case ProgressionStage.improving:
        return 'Improving';
      case ProgressionStage.mastered:
        return 'Mastered';
      case ProgressionStage.remediationRequired:
        return 'Remediation Required';
      case ProgressionStage.regressed:
        return 'Regressed';
    }
  }
}

/// Immutable progression decision for a learning objective.
@immutable
class ObjectiveProgressionDecision {
  /// Canonical learning objective identifier.
  final String objectiveId;

  /// Human-readable title of the objective.
  final String objectiveTitle;

  /// Architectural mastery classification enum.
  final ObjectiveMasteryStatus masteryStatus;

  /// Granular progression stage.
  final ProgressionStage stage;

  /// Number of authoritative attempts evaluated.
  final int evidenceCount;

  /// Number of correct attempts recorded.
  final int correctCount;

  /// Success rate in range [0.0, 1.0].
  final double successRate;

  /// Whether immediate remedial intervention is required.
  final bool isRemediationRequired;

  /// Whether additional adaptive practice questions are appropriate.
  final bool isAdditionalPracticeAppropriate;

  /// Whether the learner has mastered the concept or satisfied progression criteria.
  final bool canProgress;

  /// Whether scheduled spaced retention revision is appropriate.
  final bool isRevisionAppropriate;

  /// Whether foundational prerequisite objectives remain incomplete.
  final bool hasUnmetPrerequisites;

  /// List of incomplete prerequisite objective IDs.
  final List<String> unmetPrerequisiteIds;

  /// Pedagogical rationale explaining this progression decision.
  final String rationale;

  /// UTC evaluation timestamp.
  final DateTime evaluatedAt;

  ObjectiveProgressionDecision({
    required String objectiveId,
    required String objectiveTitle,
    required this.masteryStatus,
    required this.stage,
    required this.evidenceCount,
    required this.correctCount,
    required this.successRate,
    required this.isRemediationRequired,
    required this.isAdditionalPracticeAppropriate,
    required this.canProgress,
    required this.isRevisionAppropriate,
    required this.hasUnmetPrerequisites,
    List<String> unmetPrerequisiteIds = const [],
    required this.rationale,
    DateTime? evaluatedAt,
  })  : objectiveId = objectiveId.trim(),
        objectiveTitle = objectiveTitle.trim(),
        unmetPrerequisiteIds = List<String>.unmodifiable(unmetPrerequisiteIds),
        evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc(),
        assert(evidenceCount >= 0, 'evidenceCount cannot be negative'),
        assert(correctCount >= 0, 'correctCount cannot be negative'),
        assert(correctCount <= evidenceCount,
            'correctCount cannot exceed evidenceCount'),
        assert(successRate >= 0.0 && successRate <= 1.0,
            'successRate must be in [0.0, 1.0]') {
    if (objectiveId.isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }
  }

  /// Factory creating an initial decision for an untouched objective.
  factory ObjectiveProgressionDecision.notStarted({
    required String objectiveId,
    required String objectiveTitle,
    bool hasUnmetPrerequisites = false,
    List<String> unmetPrerequisiteIds = const [],
    DateTime? evaluatedAt,
  }) {
    return ObjectiveProgressionDecision(
      objectiveId: objectiveId,
      objectiveTitle: objectiveTitle,
      masteryStatus: ObjectiveMasteryStatus.notAttempted,
      stage: ProgressionStage.notStarted,
      evidenceCount: 0,
      correctCount: 0,
      successRate: 0.0,
      isRemediationRequired: false,
      isAdditionalPracticeAppropriate: !hasUnmetPrerequisites,
      canProgress: false,
      isRevisionAppropriate: false,
      hasUnmetPrerequisites: hasUnmetPrerequisites,
      unmetPrerequisiteIds: unmetPrerequisiteIds,
      rationale: hasUnmetPrerequisites
          ? 'Prerequisite foundational concepts must be satisfied before starting this objective.'
          : 'Objective scheduled in curriculum sequence; no attempts recorded yet.',
      evaluatedAt: evaluatedAt,
    );
  }

  ObjectiveProgressionDecision copyWith({
    String? objectiveId,
    String? objectiveTitle,
    ObjectiveMasteryStatus? masteryStatus,
    ProgressionStage? stage,
    int? evidenceCount,
    int? correctCount,
    double? successRate,
    bool? isRemediationRequired,
    bool? isAdditionalPracticeAppropriate,
    bool? canProgress,
    bool? isRevisionAppropriate,
    bool? hasUnmetPrerequisites,
    List<String>? unmetPrerequisiteIds,
    String? rationale,
    DateTime? evaluatedAt,
  }) {
    return ObjectiveProgressionDecision(
      objectiveId: objectiveId ?? this.objectiveId,
      objectiveTitle: objectiveTitle ?? this.objectiveTitle,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      stage: stage ?? this.stage,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      correctCount: correctCount ?? this.correctCount,
      successRate: successRate ?? this.successRate,
      isRemediationRequired:
          isRemediationRequired ?? this.isRemediationRequired,
      isAdditionalPracticeAppropriate: isAdditionalPracticeAppropriate ??
          this.isAdditionalPracticeAppropriate,
      canProgress: canProgress ?? this.canProgress,
      isRevisionAppropriate:
          isRevisionAppropriate ?? this.isRevisionAppropriate,
      hasUnmetPrerequisites:
          hasUnmetPrerequisites ?? this.hasUnmetPrerequisites,
      unmetPrerequisiteIds:
          unmetPrerequisiteIds ?? this.unmetPrerequisiteIds,
      rationale: rationale ?? this.rationale,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'objectiveTitle': objectiveTitle,
        'masteryStatus': masteryStatus.name,
        'stage': stage.name,
        'evidenceCount': evidenceCount,
        'correctCount': correctCount,
        'successRate': successRate,
        'isRemediationRequired': isRemediationRequired,
        'isAdditionalPracticeAppropriate': isAdditionalPracticeAppropriate,
        'canProgress': canProgress,
        'isRevisionAppropriate': isRevisionAppropriate,
        'hasUnmetPrerequisites': hasUnmetPrerequisites,
        'unmetPrerequisiteIds': unmetPrerequisiteIds,
        'rationale': rationale,
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory ObjectiveProgressionDecision.fromJson(Map<String, dynamic> json) {
    return ObjectiveProgressionDecision(
      objectiveId: json['objectiveId'] as String? ?? '',
      objectiveTitle: json['objectiveTitle'] as String? ?? '',
      masteryStatus: ObjectiveMasteryStatus.values.firstWhere(
        (e) => e.name == json['masteryStatus'],
        orElse: () => ObjectiveMasteryStatus.notAttempted,
      ),
      stage: ProgressionStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => ProgressionStage.notStarted,
      ),
      evidenceCount: json['evidenceCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      isRemediationRequired: json['isRemediationRequired'] as bool? ?? false,
      isAdditionalPracticeAppropriate:
          json['isAdditionalPracticeAppropriate'] as bool? ?? true,
      canProgress: json['canProgress'] as bool? ?? false,
      isRevisionAppropriate: json['isRevisionAppropriate'] as bool? ?? false,
      hasUnmetPrerequisites: json['hasUnmetPrerequisites'] as bool? ?? false,
      unmetPrerequisiteIds: (json['unmetPrerequisiteIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rationale: json['rationale'] as String? ?? '',
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.tryParse(json['evaluatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjectiveProgressionDecision &&
          runtimeType == other.runtimeType &&
          objectiveId == other.objectiveId &&
          masteryStatus == other.masteryStatus &&
          stage == other.stage &&
          evidenceCount == other.evidenceCount &&
          correctCount == other.correctCount &&
          (successRate - other.successRate).abs() < 1e-6 &&
          isRemediationRequired == other.isRemediationRequired &&
          canProgress == other.canProgress &&
          hasUnmetPrerequisites == other.hasUnmetPrerequisites;

  @override
  int get hashCode => Object.hash(
        objectiveId,
        masteryStatus,
        stage,
        evidenceCount,
        correctCount,
        isRemediationRequired,
        canProgress,
      );
}
