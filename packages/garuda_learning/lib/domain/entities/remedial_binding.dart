/// Remedial Lesson Binding Entity (TITAN-KO-025.0 P25).
///
/// Immutable domain model binding a [RemedialLesson] to a specific learner's
/// diagnostic context (e.g. P23 WeakSpotProfile, P21 Recommendation).
library;

import 'package:meta/meta.dart';

import 'remedial_lesson.dart';

/// Strategic trigger causing a remedial lesson to be bound to a learner.
enum RemedialBindingTrigger {
  /// Triggered by evidence-backed diagnostic weakness from P23 [WeakSpotProfile].
  weakSpotDiagnostic,

  /// Triggered by adaptive next-best-action recommendation from P21 [LearningRecommendation].
  adaptiveRecommendation,

  /// Triggered by retention decay or failed recall in P20 spaced repetition.
  spacedRepetitionStruggle,

  /// Proactively selected by curriculum planner or learner study agenda.
  manualCurriculumStudy;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case RemedialBindingTrigger.weakSpotDiagnostic:
        return 'P23 Weak-Spot Remediation';
      case RemedialBindingTrigger.adaptiveRecommendation:
        return 'P21 Recommended Action';
      case RemedialBindingTrigger.spacedRepetitionStruggle:
        return 'P20 Spaced Review Remediation';
      case RemedialBindingTrigger.manualCurriculumStudy:
        return 'Curriculum Micro-Study';
    }
  }

  /// Parses a string name into a [RemedialBindingTrigger].
  static RemedialBindingTrigger fromJson(String? name) {
    if (name == null) return RemedialBindingTrigger.weakSpotDiagnostic;
    return RemedialBindingTrigger.values.firstWhere(
      (e) => e.name == name,
      orElse: () => RemedialBindingTrigger.weakSpotDiagnostic,
    );
  }

  /// Serializes to JSON string.
  String toJson() => name;
}

/// Immutable record linking a [RemedialLesson] to a learner's diagnostic context.
@immutable
class RemedialLessonBinding {
  /// Unique deterministic binding identifier.
  final String bindingId;

  /// Target learner identifier.
  final String learnerId;

  /// Target learning objective identifier.
  final String objectiveId;

  /// The micro-lesson bound for remedial study.
  final RemedialLesson lesson;

  /// Reason or mechanism that triggered this remedial assignment.
  final RemedialBindingTrigger trigger;

  /// Optional deficiency score from P23 diagnostic in range [0.0, 1.0].
  final double? deficiencyScore;

  /// Optional P21 recommendation ID (preserved as provenance only; zero mutation).
  final String? sourceRecommendationId;

  /// UTC timestamp when this binding was created.
  final DateTime boundAt;

  /// Immutable binding metadata.
  final Map<String, dynamic> metadata;

  RemedialLessonBinding({
    required this.bindingId,
    required this.learnerId,
    required this.objectiveId,
    required this.lesson,
    this.trigger = RemedialBindingTrigger.weakSpotDiagnostic,
    this.deficiencyScore,
    this.sourceRecommendationId,
    required DateTime boundAt,
    Map<String, dynamic>? metadata,
  })  : boundAt = boundAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (bindingId.trim().isEmpty) {
      throw ArgumentError(
          'bindingId cannot be empty for RemedialLessonBinding');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for RemedialLessonBinding');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'objectiveId cannot be empty for RemedialLessonBinding');
    }
    if (deficiencyScore != null &&
        (deficiencyScore! < 0.0 || deficiencyScore! > 1.0)) {
      throw ArgumentError(
          'deficiencyScore ($deficiencyScore) must be between 0.0 and 1.0');
    }
  }

  /// Convenience accessor for the bound lesson's ID.
  String get lessonId => lesson.lessonId;

  /// Convenience accessor for the bound lesson's title.
  String get lessonTitle => lesson.title;

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'bindingId': bindingId,
        'learnerId': learnerId,
        'objectiveId': objectiveId,
        'lesson': lesson.toJson(),
        'trigger': trigger.name,
        if (deficiencyScore != null) 'deficiencyScore': deficiencyScore,
        if (sourceRecommendationId != null)
          'sourceRecommendationId': sourceRecommendationId,
        'boundAt': boundAt.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory RemedialLessonBinding.fromJson(Map<String, dynamic> json) =>
      RemedialLessonBinding(
        bindingId: json['bindingId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        lesson: RemedialLesson.fromJson(json['lesson'] as Map<String, dynamic>),
        trigger: RemedialBindingTrigger.fromJson(json['trigger'] as String?),
        deficiencyScore: (json['deficiencyScore'] as num?)?.toDouble(),
        sourceRecommendationId: json['sourceRecommendationId'] as String?,
        boundAt: json['boundAt'] != null
            ? DateTime.parse(json['boundAt'] as String).toUtc()
            : DateTime.utc(2026, 1, 1),
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedialLessonBinding &&
          runtimeType == other.runtimeType &&
          bindingId == other.bindingId &&
          learnerId == other.learnerId &&
          objectiveId == other.objectiveId &&
          lesson == other.lesson &&
          trigger == other.trigger;

  @override
  int get hashCode =>
      Object.hash(bindingId, learnerId, objectiveId, lesson, trigger);

  @override
  String toString() =>
      'RemedialLessonBinding($bindingId: $learnerId -> $lessonTitle [$trigger])';
}
