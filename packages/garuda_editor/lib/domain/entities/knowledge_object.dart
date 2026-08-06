library;

import 'package:meta/meta.dart';
import 'editorial_status.dart';
import 'knowledge_object_version.dart';

/// Immutable domain model representing a GARUDA Knowledge Object.
@immutable
class KnowledgeObject {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final String subtopic;
  final String concept;
  final String summary;
  final String content;
  final List<String> references;
  final List<String> evidenceIds;
  final List<String> linkedObjectIds;
  final Map<String, dynamic> metadata;
  final EditorialStatus status;
  final int currentVersion;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KnowledgeObjectVersion> versions;

  KnowledgeObject({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    this.subtopic = '',
    this.concept = '',
    this.summary = '',
    required this.content,
    this.references = const [],
    this.evidenceIds = const [],
    this.linkedObjectIds = const [],
    Map<String, dynamic>? metadata,
    this.status = EditorialStatus.draft,
    int? version,
    int currentVersion = 1,
    this.createdBy = 'Editor',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.versions = const [],
    String? officialSource,
    String? package,
    String? knowledgeType,
    List<String>? relatedArticles,
    List<String>? relatedCaseLaws,
    List<String>? tags,
    bool? isVerified,
  })  : metadata = Map<String, dynamic>.from(metadata ?? const {}),
        currentVersion = version ?? currentVersion,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    if (officialSource != null) this.metadata['officialSource'] = officialSource;
    if (package != null) this.metadata['package'] = package;
    if (knowledgeType != null) this.metadata['knowledgeType'] = knowledgeType;
    if (relatedArticles != null) this.metadata['relatedArticles'] = relatedArticles;
    if (relatedCaseLaws != null) this.metadata['relatedCaseLaws'] = relatedCaseLaws;
    if (tags != null) this.metadata['tags'] = tags;
    if (isVerified != null) this.metadata['isVerified'] = isVerified;
  }

  int get version => currentVersion;

  String get officialSource => metadata['officialSource'] as String? ?? '';
  String get package => metadata['package'] as String? ?? 'garuda_knowledge';
  String get knowledgeType => metadata['knowledgeType'] as String? ?? 'KnowledgeObject';

  List<String> get relatedArticles =>
      (metadata['relatedArticles'] as List?)?.map((e) => e.toString()).toList() ?? const [];

  List<String> get relatedCaseLaws =>
      (metadata['relatedCaseLaws'] as List?)?.map((e) => e.toString()).toList() ?? const [];

  List<String> get tags =>
      (metadata['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [];

  bool get isVerified =>
      metadata['isVerified'] as bool? ?? (evidenceIds.isNotEmpty && status == EditorialStatus.published);

  KnowledgeObject copyWith({
    String? id,
    String? title,
    String? subject,
    String? topic,
    String? subtopic,
    String? concept,
    String? summary,
    String? content,
    List<String>? references,
    List<String>? evidenceIds,
    List<String>? linkedObjectIds,
    Map<String, dynamic>? metadata,
    EditorialStatus? status,
    int? currentVersion,
    int? version,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<KnowledgeObjectVersion>? versions,
    String? officialSource,
    String? package,
    String? knowledgeType,
    List<String>? relatedArticles,
    List<String>? relatedCaseLaws,
    List<String>? tags,
    bool? isVerified,
  }) {
    final newMetadata = Map<String, dynamic>.from(metadata ?? this.metadata);
    if (officialSource != null) newMetadata['officialSource'] = officialSource;
    if (package != null) newMetadata['package'] = package;
    if (knowledgeType != null) newMetadata['knowledgeType'] = knowledgeType;
    if (relatedArticles != null) newMetadata['relatedArticles'] = relatedArticles;
    if (relatedCaseLaws != null) newMetadata['relatedCaseLaws'] = relatedCaseLaws;
    if (tags != null) newMetadata['tags'] = tags;
    if (isVerified != null) newMetadata['isVerified'] = isVerified;

    return KnowledgeObject(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      concept: concept ?? this.concept,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      references: references ?? List.from(this.references),
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      linkedObjectIds: linkedObjectIds ?? List.from(this.linkedObjectIds),
      metadata: newMetadata,
      status: status ?? this.status,
      currentVersion: version ?? currentVersion ?? this.currentVersion,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      versions: versions ?? List.from(this.versions),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'topic': topic,
        'subtopic': subtopic,
        'concept': concept,
        'summary': summary,
        'content': content,
        'references': references,
        'evidenceIds': evidenceIds,
        'linkedObjectIds': linkedObjectIds,
        'metadata': metadata,
        'status': status.name,
        'currentVersion': currentVersion,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'versions': versions.map((v) => v.toJson()).toList(),
      };

  factory KnowledgeObject.fromJson(Map<String, dynamic> json) => KnowledgeObject(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        subtopic: json['subtopic'] as String? ?? '',
        concept: json['concept'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        content: json['content'] as String? ?? '',
        references:
            (json['references'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidenceIds:
            (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        linkedObjectIds:
            (json['linkedObjectIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        status: EditorialStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EditorialStatus.draft,
        ),
        currentVersion: (json['currentVersion'] as num?)?.toInt() ?? 1,
        createdBy: json['createdBy'] as String? ?? 'Editor',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        versions: (json['versions'] as List?)
                ?.map((e) => KnowledgeObjectVersion.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeObject && other.id == id && other.currentVersion == currentVersion;
  }

  @override
  int get hashCode => Object.hash(id, currentVersion);
}
