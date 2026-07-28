import 'package:meta/meta.dart';
import 'content_block.dart';
import 'glossary_item.dart';
import 'knowledge_concept.dart';
import 'knowledge_object_metadata.dart';
import 'knowledge_relationship.dart';

/// Canonical Knowledge Object produced by Knowledge Ingestion Pipeline.
/// Serves as the single source of truth for K3 content synthesis.
@immutable
class KnowledgeObject {
  final String id;
  final String title;
  final String summary; // Placeholder only in K2
  final String? chapter;
  final String? module;
  final String? course;
  final String source;
  final String language;
  final String difficulty;
  final int estimatedReadingTime; // minutes
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final List<KnowledgeConcept> concepts;
  final List<String> keywords;
  final List<GlossaryItem> glossary;
  final List<String> references;
  final List<ContentBlock> contentBlocks;
  final KnowledgeObjectMetadata metadata;
  final List<KnowledgeRelationship> relationships;
  final DateTime createdAt;

  KnowledgeObject({
    required this.id,
    required this.title,
    this.summary = '[K2 Placeholder Summary]',
    this.chapter,
    this.module,
    this.course,
    required this.source,
    this.language = 'en',
    this.difficulty = 'medium',
    this.estimatedReadingTime = 5,
    List<String>? learningObjectives,
    List<String>? prerequisites,
    List<String>? learningOutcomes,
    List<KnowledgeConcept>? concepts,
    List<String>? keywords,
    List<GlossaryItem>? glossary,
    List<String>? references,
    List<ContentBlock>? contentBlocks,
    KnowledgeObjectMetadata? metadata,
    List<KnowledgeRelationship>? relationships,
    DateTime? createdAt,
  })  : learningObjectives = List.unmodifiable(learningObjectives ?? []),
        prerequisites = List.unmodifiable(prerequisites ?? []),
        learningOutcomes = List.unmodifiable(learningOutcomes ?? []),
        concepts = List.unmodifiable(concepts ?? []),
        keywords = List.unmodifiable(keywords ?? []),
        glossary = List.unmodifiable(glossary ?? []),
        references = List.unmodifiable(references ?? []),
        contentBlocks = List.unmodifiable(contentBlocks ?? []),
        metadata = metadata ?? KnowledgeObjectMetadata(title: title),
        relationships = List.unmodifiable(relationships ?? []),
        createdAt = createdAt ?? DateTime.now();

  KnowledgeObject copyWith({
    String? id,
    String? title,
    String? summary,
    String? chapter,
    String? module,
    String? course,
    String? source,
    String? language,
    String? difficulty,
    int? estimatedReadingTime,
    List<String>? learningObjectives,
    List<String>? prerequisites,
    List<String>? learningOutcomes,
    List<KnowledgeConcept>? concepts,
    List<String>? keywords,
    List<GlossaryItem>? glossary,
    List<String>? references,
    List<ContentBlock>? contentBlocks,
    KnowledgeObjectMetadata? metadata,
    List<KnowledgeRelationship>? relationships,
    DateTime? createdAt,
  }) {
    return KnowledgeObject(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      chapter: chapter ?? this.chapter,
      module: module ?? this.module,
      course: course ?? this.course,
      source: source ?? this.source,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      estimatedReadingTime: estimatedReadingTime ?? this.estimatedReadingTime,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      prerequisites: prerequisites ?? this.prerequisites,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      concepts: concepts ?? this.concepts,
      keywords: keywords ?? this.keywords,
      glossary: glossary ?? this.glossary,
      references: references ?? this.references,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      metadata: metadata ?? this.metadata,
      relationships: relationships ?? this.relationships,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'chapter': chapter,
        'module': module,
        'course': course,
        'source': source,
        'language': language,
        'difficulty': difficulty,
        'estimatedReadingTime': estimatedReadingTime,
        'learningObjectives': learningObjectives,
        'prerequisites': prerequisites,
        'learningOutcomes': learningOutcomes,
        'concepts': concepts.map((c) => c.toJson()).toList(),
        'keywords': keywords,
        'glossary': glossary.map((g) => g.toJson()).toList(),
        'references': references,
        'contentBlocks': contentBlocks.map((b) => b.toJson()).toList(),
        'metadata': metadata.toJson(),
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory KnowledgeObject.fromJson(Map<String, dynamic> json) =>
      KnowledgeObject(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String? ?? '[K2 Placeholder Summary]',
        chapter: json['chapter'] as String?,
        module: json['module'] as String?,
        course: json['course'] as String?,
        source: json['source'] as String? ?? 'unknown',
        language: json['language'] as String? ?? 'en',
        difficulty: json['difficulty'] as String? ?? 'medium',
        estimatedReadingTime: json['estimatedReadingTime'] as int? ?? 5,
        learningObjectives:
            List<String>.from(json['learningObjectives'] as List? ?? []),
        prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
        learningOutcomes:
            List<String>.from(json['learningOutcomes'] as List? ?? []),
        concepts: (json['concepts'] as List? ?? [])
            .map((c) =>
                KnowledgeConcept.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        keywords: List<String>.from(json['keywords'] as List? ?? []),
        glossary: (json['glossary'] as List? ?? [])
            .map((g) =>
                GlossaryItem.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList(),
        references: List<String>.from(json['references'] as List? ?? []),
        contentBlocks: (json['contentBlocks'] as List? ?? [])
            .map((b) =>
                parseContentBlockFromJson(Map<String, dynamic>.from(b as Map)))
            .toList(),
        metadata: json['metadata'] != null
            ? KnowledgeObjectMetadata.fromJson(
                Map<String, dynamic>.from(json['metadata'] as Map))
            : null,
        relationships: (json['relationships'] as List? ?? [])
            .map((r) => KnowledgeRelationship.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          source == other.source;

  @override
  int get hashCode => Object.hash(id, title, source);
}
