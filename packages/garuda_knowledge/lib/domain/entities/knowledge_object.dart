import 'package:meta/meta.dart';
import '../enums/knowledge_object_type.dart';
import '../value_objects/knowledge_object_id.dart';
import 'knowledge_category.dart';
import 'knowledge_citation.dart';
import 'knowledge_evidence_reference.dart';
import 'knowledge_metadata.dart';
import 'knowledge_reference.dart';
import 'knowledge_relationship.dart';
import 'knowledge_source.dart';
import 'knowledge_tag.dart';
import 'knowledge_version.dart';

/// Central aggregate root representing an immutable Knowledge Object in GARUDA.
@immutable
class KnowledgeObject {
  final KnowledgeObjectId id;
  final KnowledgeObjectType type;
  final String title;
  final String content;
  final String? summary;
  final KnowledgeCategory? category;
  final List<KnowledgeTag> tags;
  final List<KnowledgeSource> sources;
  final List<KnowledgeCitation> citations;
  final List<KnowledgeEvidenceReference> evidenceReferences;
  final List<KnowledgeReference> references;
  final List<KnowledgeRelationship> relationships;
  final KnowledgeVersion currentVersion;
  final List<KnowledgeVersion> versionHistory;
  final KnowledgeMetadata metadata;

  const KnowledgeObject({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.summary,
    this.category,
    this.tags = const [],
    this.sources = const [],
    this.citations = const [],
    this.evidenceReferences = const [],
    this.references = const [],
    this.relationships = const [],
    required this.currentVersion,
    this.versionHistory = const [],
    required this.metadata,
  });

  KnowledgeObject copyWith({
    KnowledgeObjectId? id,
    KnowledgeObjectType? type,
    String? title,
    String? content,
    String? summary,
    KnowledgeCategory? category,
    List<KnowledgeTag>? tags,
    List<KnowledgeSource>? sources,
    List<KnowledgeCitation>? citations,
    List<KnowledgeEvidenceReference>? evidenceReferences,
    List<KnowledgeReference>? references,
    List<KnowledgeRelationship>? relationships,
    KnowledgeVersion? currentVersion,
    List<KnowledgeVersion>? versionHistory,
    KnowledgeMetadata? metadata,
  }) {
    return KnowledgeObject(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      sources: sources ?? this.sources,
      citations: citations ?? this.citations,
      evidenceReferences: evidenceReferences ?? this.evidenceReferences,
      references: references ?? this.references,
      relationships: relationships ?? this.relationships,
      currentVersion: currentVersion ?? this.currentVersion,
      versionHistory: versionHistory ?? this.versionHistory,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.toJson(),
        'type': type.toJson(),
        'title': title,
        'content': content,
        'summary': summary,
        'category': category?.toJson(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'sources': sources.map((s) => s.toJson()).toList(),
        'citations': citations.map((c) => c.toJson()).toList(),
        'evidenceReferences':
            evidenceReferences.map((e) => e.toJson()).toList(),
        'references': references.map((r) => r.toJson()).toList(),
        'relationships': relationships.map((rel) => rel.toJson()).toList(),
        'currentVersion': currentVersion.toJson(),
        'versionHistory': versionHistory.map((v) => v.toJson()).toList(),
        'metadata': metadata.toJson(),
      };

  factory KnowledgeObject.fromJson(Map<String, dynamic> json) {
    return KnowledgeObject(
      id: KnowledgeObjectId.fromJson(json['id'] as String),
      type: KnowledgeObjectType.fromJson(json['type'] as String),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String?,
      category: json['category'] != null
          ? KnowledgeCategory.fromJson(
              json['category'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => KnowledgeTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => KnowledgeSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      citations: (json['citations'] as List<dynamic>?)
              ?.map(
                  (e) => KnowledgeCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      evidenceReferences: (json['evidenceReferences'] as List<dynamic>?)
              ?.map((e) => KnowledgeEvidenceReference.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      references: (json['references'] as List<dynamic>?)
              ?.map((e) =>
                  KnowledgeReference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relationships: (json['relationships'] as List<dynamic>?)
              ?.map((e) =>
                  KnowledgeRelationship.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentVersion: KnowledgeVersion.fromJson(
          json['currentVersion'] as Map<String, dynamic>),
      versionHistory: (json['versionHistory'] as List<dynamic>?)
              ?.map(
                  (e) => KnowledgeVersion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: KnowledgeMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeObject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
