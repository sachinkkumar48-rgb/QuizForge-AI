library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'recommendation_knowledge_object.dart';
import 'report_statistic.dart';

/// First-class Chapter Knowledge Object decomposing a Report into searchable sections.
@immutable
class ChapterKnowledgeObject {
  final String id;
  final String parentReportId;
  final String chapterNumber;
  final String title;
  final String summary;
  final List<String> keyPoints;
  final List<String> keyIndicators;
  final List<ReportStatistic> statistics;
  final List<RecommendationKnowledgeObject> recommendations;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedPyqIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  ChapterKnowledgeObject({
    required this.id,
    required this.parentReportId,
    required this.chapterNumber,
    required this.title,
    this.summary = '',
    this.keyPoints = const [],
    this.keyIndicators = const [],
    this.statistics = const [],
    this.recommendations = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
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
      topic: parentReportId,
      subtopic: chapterNumber,
      summary: summary,
      content:
          'Chapter ${chapterNumber.isNotEmpty ? chapterNumber : title}. Key Points: ${keyPoints.join("; ")}. Statistics: ${statistics.map((s) => '${s.label}: ${s.displayValue}').join("; ")}. Recommendations: ${recommendations.map((r) => r.title).join("; ")}.',
      officialSource: parentReportId,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'ChapterKnowledgeObject',
      relatedArticles: relatedArticleIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'parentReportId': parentReportId,
        'chapterNumber': chapterNumber,
        'relatedActIds': relatedActIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
      },
    );
  }

  ChapterKnowledgeObject copyWith({
    String? id,
    String? parentReportId,
    String? chapterNumber,
    String? title,
    String? summary,
    List<String>? keyPoints,
    List<String>? keyIndicators,
    List<ReportStatistic>? statistics,
    List<RecommendationKnowledgeObject>? recommendations,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedPyqIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return ChapterKnowledgeObject(
      id: id ?? this.id,
      parentReportId: parentReportId ?? this.parentReportId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? List.from(this.keyPoints),
      keyIndicators: keyIndicators ?? List.from(this.keyIndicators),
      statistics: statistics ?? List.from(this.statistics),
      recommendations: recommendations ?? List.from(this.recommendations),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
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
        'parentReportId': parentReportId,
        'chapterNumber': chapterNumber,
        'title': title,
        'summary': summary,
        'keyPoints': keyPoints,
        'keyIndicators': keyIndicators,
        'statistics': statistics.map((s) => s.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory ChapterKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      ChapterKnowledgeObject(
        id: json['id'] as String? ?? '',
        parentReportId: json['parentReportId'] as String? ?? '',
        chapterNumber: json['chapterNumber'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        keyPoints:
            (json['keyPoints'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        keyIndicators: (json['keyIndicators'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        statistics: (json['statistics'] as List?)
                ?.map((s) => ReportStatistic.fromJson(
                    Map<String, dynamic>.from(s as Map)))
                .toList() ??
            const [],
        recommendations: (json['recommendations'] as List?)
                ?.map((r) => RecommendationKnowledgeObject.fromJson(
                    Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        relatedArticleIds: (json['relatedArticleIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedActIds: (json['relatedActIds'] as List?)
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
