/// Managed Content Item & Lifecycle Entities (TITAN-KO-045.0 P45).
///
/// Production domain models representing curriculum-aligned content authored,
/// validated, versioned, and published by faculty or administrators.
library;

import 'package:garuda_pyq/garuda_pyq.dart'
    show Answer, NormalizedQuestion, Option, PyqSourceReference;
import 'package:meta/meta.dart';

import 'bloom_taxonomy_level.dart';
import 'content_origin.dart';
import 'remedial_lesson.dart';
import 'source_reference.dart';

/// Supported categories of faculty-managed content.
enum ManagedContentType {
  question,
  remedialLesson,
  learningMaterial,
}

/// Explicit lifecycle states for managed content.
enum ContentLifecycleStatus {
  draft,
  validationFailed,
  readyToPublish,
  published,
  unpublished,
}

/// Immutable domain model representing a managed content item.
@immutable
class ManagedContentItem {
  /// Unique canonical identifier (e.g. 'mc_q_art21_01', 'mc_rem_dpsp_01').
  final String id;

  /// Human-readable title of the content item.
  final String title;

  /// High-level description or notes.
  final String description;

  /// Associated curriculum exam (e.g. 'upsc_prelims_gs1').
  final String examId;

  /// Associated curriculum subject (e.g. 'indian_polity').
  final String subjectId;

  /// Associated curriculum topic (e.g. 'Fundamental Rights').
  final String topicId;

  /// Target curriculum learning objective ID (e.g. 'lo_article_21_foundations').
  final String objectiveId;

  /// Category of content.
  final ManagedContentType contentType;

  /// Identifier of author / faculty member.
  final String authorId;

  /// Display name of the author.
  final String authorName;

  /// Source provenance / academic standard citation.
  final String provenance;

  /// Epistemic origin of the content.
  final ContentOrigin contentOrigin;

  /// Current publication lifecycle status.
  final ContentLifecycleStatus status;

  /// Content revision version number (monotonically starts at 1).
  final int version;

  /// Timestamp when first drafted.
  final DateTime createdAt;

  /// Timestamp of latest modification.
  final DateTime updatedAt;

  /// List of validation errors recorded during last validation check.
  final List<String> validationErrors;

  // --- Question-Specific Fields ---
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty;
  final BloomTaxonomyLevel bloomLevel;

  // --- Remedial Lesson / Learning Material Fields ---
  final String summary;
  final List<String> learningPoints;
  final String lessonExplanation;
  final List<String> examples;
  final List<String> misconceptions;
  final int estimatedMinutes;

  /// Arbitrary extensible metadata.
  final Map<String, dynamic> metadata;

  ManagedContentItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.examId,
    required this.subjectId,
    required this.topicId,
    required this.objectiveId,
    required this.contentType,
    required this.authorId,
    this.authorName = 'Faculty Contributor',
    required this.provenance,
    this.contentOrigin = ContentOrigin.pedagogicalExplanation,
    this.status = ContentLifecycleStatus.draft,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.validationErrors = const [],
    this.prompt = '',
    this.options = const [],
    this.correctAnswer = '',
    this.explanation = '',
    this.difficulty = 'Medium',
    this.bloomLevel = BloomTaxonomyLevel.apply,
    this.summary = '',
    this.learningPoints = const [],
    this.lessonExplanation = '',
    this.examples = const [],
    this.misconceptions = const [],
    this.estimatedMinutes = 10,
    this.metadata = const {},
  })  : assert(id.trim().isNotEmpty, 'id cannot be empty'),
        assert(version >= 1, 'version must be >= 1');

  bool get isPublished => status == ContentLifecycleStatus.published;
  bool get isDraft => status == ContentLifecycleStatus.draft;
  bool get isUnpublished => status == ContentLifecycleStatus.unpublished;
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Converts this managed item into a runtime [NormalizedQuestion].
  NormalizedQuestion toNormalizedQuestion() {
    // Map correct answer text or letter to target option id
    String targetCorrectKey = 'A';
    final upperAns = correctAnswer.trim().toUpperCase();
    if (upperAns.length == 1 &&
        upperAns.codeUnitAt(0) >= 65 &&
        upperAns.codeUnitAt(0) <= 90) {
      targetCorrectKey = upperAns;
    } else {
      final matchIdx = options.indexWhere((o) =>
          o.trim().toLowerCase() == correctAnswer.trim().toLowerCase());
      if (matchIdx != -1) {
        targetCorrectKey = String.fromCharCode(65 + matchIdx);
      }
    }

    final opts = options.asMap().entries.map((e) {
      final optKey = String.fromCharCode(65 + e.key); // 'A', 'B', 'C', 'D'
      return Option(
        key: optKey,
        text: e.value,
        isCorrect: optKey == targetCorrectKey,
      );
    }).toList();

    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: DateTime.now().year,
      paper: 'GS Paper 1',
      stage: 'Prelims',
      subject: subjectId,
      topic: topicId,
      normalizedText: prompt,
      originalText: prompt,
      options: opts,
      officialAnswer: Answer(
        correctOptionKeys: [targetCorrectKey],
        officialAnswerSource: provenance,
      ),
      explanation: explanation.isNotEmpty ? explanation : lessonExplanation,
      difficulty: difficulty,
      source: PyqSourceReference(
        sourceId: 'src_$id',
        sourceType: 'FacultyContent',
        sourceTitle: provenance,
        publisher: authorName,
        retrievedAt: createdAt,
        checksum: 'fac_$id',
      ),
      objectiveIds: [objectiveId],
      tags: ['faculty_authored', 'version_$version'],
      metadata: {
        'managedContentId': id,
        'version': version,
        'authorId': authorId,
        'contentOrigin': contentOrigin.name,
        ...metadata,
      },
    );
  }

  /// Converts this managed item into an authoritative [RemedialLesson].
  RemedialLesson toRemedialLesson() {
    return RemedialLesson(
      lessonId: id,
      objectiveId: objectiveId,
      title: title,
      summary: summary.isNotEmpty ? summary : description,
      learningPoints: learningPoints.isNotEmpty ? learningPoints : [title],
      explanation:
          lessonExplanation.isNotEmpty ? lessonExplanation : explanation,
      examples: examples,
      misconceptions: misconceptions,
      sourceReferences: [
        SourceReference(
          sourceId: 'ref_$id',
          sourceType: SourceReferenceType.textbook,
          referenceIdentifier: provenance,
        ),
      ],
      contentOrigin: contentOrigin,
      estimatedMinutes: estimatedMinutes,
      bloomLevel: bloomLevel,
      authoredAt: updatedAt,
      version: version,
      metadata: {
        'managedContentId': id,
        'authorId': authorId,
        'authorName': authorName,
        'topicId': topicId,
        'examId': examId,
        ...metadata,
      },
    );
  }

  ManagedContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? examId,
    String? subjectId,
    String? topicId,
    String? objectiveId,
    ManagedContentType? contentType,
    String? authorId,
    String? authorName,
    String? provenance,
    ContentOrigin? contentOrigin,
    ContentLifecycleStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? validationErrors,
    String? prompt,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    BloomTaxonomyLevel? bloomLevel,
    String? summary,
    List<String>? learningPoints,
    String? lessonExplanation,
    List<String>? examples,
    List<String>? misconceptions,
    int? estimatedMinutes,
    Map<String, dynamic>? metadata,
  }) {
    return ManagedContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      examId: examId ?? this.examId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      objectiveId: objectiveId ?? this.objectiveId,
      contentType: contentType ?? this.contentType,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      provenance: provenance ?? this.provenance,
      contentOrigin: contentOrigin ?? this.contentOrigin,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validationErrors: validationErrors ?? this.validationErrors,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      summary: summary ?? this.summary,
      learningPoints: learningPoints ?? this.learningPoints,
      lessonExplanation: lessonExplanation ?? this.lessonExplanation,
      examples: examples ?? this.examples,
      misconceptions: misconceptions ?? this.misconceptions,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      metadata: metadata ?? this.metadata,
    );
  }
}
