library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'report_enums.dart';

/// First-class structured Recommendation Knowledge Object extracted from a Report.
@immutable
class RecommendationKnowledgeObject {
  final String id;
  final String title;
  final String description;
  final String recommendingBody;
  final String recipientActor;
  final RecommendationStatus status;
  final String reportId;
  final String chapterId;
  final List<String> relatedActIds;
  final List<String> relatedArticleIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedPyqIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  RecommendationKnowledgeObject({
    required this.id,
    required this.title,
    required this.description,
    this.recommendingBody = '',
    this.recipientActor = '',
    this.status = RecommendationStatus.underConsideration,
    this.reportId = '',
    this.chapterId = '',
    this.relatedActIds = const [],
    this.relatedArticleIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedPyqIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.evidenceIds = const [],
    this.keywords = const [],
    this.version = 1,
    this.editorialStatus = EditorialStatus.imported,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Bridge helper converting to base GARUDA KnowledgeObject for the Editorial Production Engine.
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: title,
      subject: 'Reports & Indices',
      topic: reportId.isNotEmpty ? reportId : recommendingBody,
      subtopic: recipientActor,
      summary: description,
      content:
          'Recommendation: $title. Recommended By: $recommendingBody. Recipient: $recipientActor. Status: ${status.name}. Source Report: $reportId.',
      officialSource: recommendingBody,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'RecommendationKnowledgeObject',
      relatedArticles: relatedArticleIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'status': status.name,
        'reportId': reportId,
        'chapterId': chapterId,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
      },
    );
  }

  RecommendationKnowledgeObject copyWith({
    String? id,
    String? title,
    String? description,
    String? recommendingBody,
    String? recipientActor,
    RecommendationStatus? status,
    String? reportId,
    String? chapterId,
    List<String>? relatedActIds,
    List<String>? relatedArticleIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedPyqIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return RecommendationKnowledgeObject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendingBody: recommendingBody ?? this.recommendingBody,
      recipientActor: recipientActor ?? this.recipientActor,
      status: status ?? this.status,
      reportId: reportId ?? this.reportId,
      chapterId: chapterId ?? this.chapterId,
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedSchemeNames:
          relatedSchemeNames ?? List.from(this.relatedSchemeNames),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      keywords: keywords ?? List.from(this.keywords),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'recommendingBody': recommendingBody,
        'recipientActor': recipientActor,
        'status': status.name,
        'reportId': reportId,
        'chapterId': chapterId,
        'relatedActIds': relatedActIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory RecommendationKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      RecommendationKnowledgeObject(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        recommendingBody: json['recommendingBody'] as String? ?? '',
        recipientActor: json['recipientActor'] as String? ?? '',
        status: RecommendationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RecommendationStatus.underConsideration,
        ),
        reportId: json['reportId'] as String? ?? '',
        chapterId: json['chapterId'] as String? ?? '',
        relatedActIds: (json['relatedActIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedArticleIds: (json['relatedArticleIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCommitteeIds: (json['relatedCommitteeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedSchemeNames: (json['relatedSchemeNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedPyqIds: (json['relatedPyqIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCurrentAffairsIds: (json['relatedCurrentAffairsIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        evidenceIds:
            (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        keywords:
            (json['keywords'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        editorialStatus: EditorialStatus.values.firstWhere(
          (s) => s.name == json['editorialStatus'],
          orElse: () => EditorialStatus.imported,
        ),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}
