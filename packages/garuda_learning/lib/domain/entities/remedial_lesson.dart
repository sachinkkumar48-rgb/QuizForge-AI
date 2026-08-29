/// Remedial Lesson Entity (TITAN-KO-025.0 P25).
///
/// Immutable domain model representing a structured remedial micro-lesson bound to a
/// target [LearningObjective] for targeted remediation prior to re-testing.
///
/// Educational Safety Invariants:
/// - Explicitly attributes origin via [ContentOrigin].
/// - Preserves primary source provenance via [SourceReference] list.
/// - Clarifies common exam traps and cognitive pitfalls via [misconceptions].
/// - Contains zero claims of learner innate intelligence or exam pass guarantees.
library;

import 'package:meta/meta.dart';

import 'bloom_taxonomy_level.dart';
import 'content_origin.dart';
import 'source_reference.dart';

/// Structured remedial micro-lesson designed for targeted concept mastery.
@immutable
class RemedialLesson {
  /// Unique canonical identifier of this remedial lesson (e.g. 'rem_lo_const_02_v1').
  final String lessonId;

  /// Canonical P17 learning objective identifier this lesson remediates.
  final String objectiveId;

  /// Clear, focused title of the remedial lesson.
  final String title;

  /// High-level conceptual summary of the topic.
  final String summary;

  /// Ordered list of key takeaway points (unmodifiable).
  final List<String> learningPoints;

  /// Comprehensive pedagogical explanation of the underlying doctrine or principle.
  final String explanation;

  /// Practical examples, case studies, or hypothetical scenarios illustrating the concept.
  final List<String> examples;

  /// Common traps, misconceptions, or frequent errors associated with this objective.
  final List<String> misconceptions;

  /// Verified primary legal, statutory, or academic source references backing this lesson.
  final List<SourceReference> sourceReferences;

  /// Epistemic origin and authority level of the content.
  final ContentOrigin contentOrigin;

  /// Estimated completion duration in minutes (range [1, 120]).
  final int estimatedMinutes;

  /// Cognitive complexity level of the objective per Bloom's Taxonomy.
  final BloomTaxonomyLevel bloomLevel;

  /// UTC timestamp when this lesson was authored or verified.
  final DateTime authoredAt;

  /// Revision version of the micro-lesson (starts at 1).
  final int version;

  /// Immutable metadata for extensibility.
  final Map<String, dynamic> metadata;

  RemedialLesson({
    required this.lessonId,
    required this.objectiveId,
    required this.title,
    required this.summary,
    required List<String> learningPoints,
    required this.explanation,
    List<String>? examples,
    List<String>? misconceptions,
    List<SourceReference>? sourceReferences,
    this.contentOrigin = ContentOrigin.pedagogicalExplanation,
    required this.estimatedMinutes,
    this.bloomLevel = BloomTaxonomyLevel.understand,
    required DateTime authoredAt,
    this.version = 1,
    Map<String, dynamic>? metadata,
  })  : learningPoints = List<String>.unmodifiable(learningPoints),
        examples = List<String>.unmodifiable(examples ?? const <String>[]),
        misconceptions =
            List<String>.unmodifiable(misconceptions ?? const <String>[]),
        sourceReferences = List<SourceReference>.unmodifiable(
            sourceReferences ?? const <SourceReference>[]),
        authoredAt = authoredAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (lessonId.trim().isEmpty) {
      throw ArgumentError('lessonId cannot be empty for RemedialLesson');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('objectiveId cannot be empty for RemedialLesson');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty for RemedialLesson');
    }
    if (summary.trim().isEmpty) {
      throw ArgumentError('summary cannot be empty for RemedialLesson');
    }
    if (learningPoints.isEmpty) {
      throw ArgumentError(
          'learningPoints must contain at least one point for RemedialLesson');
    }
    if (explanation.trim().isEmpty) {
      throw ArgumentError('explanation cannot be empty for RemedialLesson');
    }
    if (estimatedMinutes < 1 || estimatedMinutes > 120) {
      throw ArgumentError(
          'estimatedMinutes ($estimatedMinutes) must be between 1 and 120');
    }
    if (version < 1) {
      throw ArgumentError('version ($version) must be >= 1');
    }
  }

  /// Whether this lesson has associated primary source citations.
  bool get hasSourceReferences => sourceReferences.isNotEmpty;

  /// Whether this lesson includes identified misconceptions.
  bool get hasMisconceptions => misconceptions.isNotEmpty;

  /// Whether this lesson includes practical examples.
  bool get hasExamples => examples.isNotEmpty;

  /// Whether this lesson is marked as authoritative primary source material.
  bool get isAuthoritativeSource => contentOrigin.isAuthoritativeSource;

  /// Creates a copy with optionally updated fields.
  RemedialLesson copyWith({
    String? lessonId,
    String? objectiveId,
    String? title,
    String? summary,
    List<String>? learningPoints,
    String? explanation,
    List<String>? examples,
    List<String>? misconceptions,
    List<SourceReference>? sourceReferences,
    ContentOrigin? contentOrigin,
    int? estimatedMinutes,
    BloomTaxonomyLevel? bloomLevel,
    DateTime? authoredAt,
    int? version,
    Map<String, dynamic>? metadata,
  }) {
    return RemedialLesson(
      lessonId: lessonId ?? this.lessonId,
      objectiveId: objectiveId ?? this.objectiveId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      learningPoints: learningPoints ?? this.learningPoints,
      explanation: explanation ?? this.explanation,
      examples: examples ?? this.examples,
      misconceptions: misconceptions ?? this.misconceptions,
      sourceReferences: sourceReferences ?? this.sourceReferences,
      contentOrigin: contentOrigin ?? this.contentOrigin,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      authoredAt: authoredAt ?? this.authoredAt,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'objectiveId': objectiveId,
        'title': title,
        'summary': summary,
        'learningPoints': learningPoints,
        'explanation': explanation,
        'examples': examples,
        'misconceptions': misconceptions,
        'sourceReferences': sourceReferences.map((r) => r.toJson()).toList(),
        'contentOrigin': contentOrigin.name,
        'estimatedMinutes': estimatedMinutes,
        'bloomLevel': bloomLevel.name,
        'authoredAt': authoredAt.toIso8601String(),
        'version': version,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory RemedialLesson.fromJson(Map<String, dynamic> json) => RemedialLesson(
        lessonId: json['lessonId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        learningPoints: (json['learningPoints'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        explanation: json['explanation'] as String? ?? '',
        examples: (json['examples'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        misconceptions: (json['misconceptions'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        sourceReferences:
            (json['sourceReferences'] as List<dynamic>? ?? const [])
                .map((e) => SourceReference.fromJson(e as Map<String, dynamic>))
                .toList(),
        contentOrigin: ContentOrigin.fromJson(json['contentOrigin'] as String?),
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
        bloomLevel: json['bloomLevel'] == null
            ? BloomTaxonomyLevel.understand
            : BloomTaxonomyLevel.values.firstWhere(
                (e) => e.name == json['bloomLevel'],
                orElse: () => BloomTaxonomyLevel.understand,
              ),
        authoredAt: json['authoredAt'] != null
            ? DateTime.parse(json['authoredAt'] as String).toUtc()
            : DateTime.utc(2026, 1, 1),
        version: json['version'] as int? ?? 1,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedialLesson &&
          runtimeType == other.runtimeType &&
          lessonId == other.lessonId &&
          objectiveId == other.objectiveId &&
          title == other.title &&
          version == other.version;

  @override
  int get hashCode => Object.hash(lessonId, objectiveId, title, version);

  @override
  String toString() =>
      'RemedialLesson($lessonId: "$title" for $objectiveId, $estimatedMinutes min, v$version)';
}
