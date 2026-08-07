library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'chapter_knowledge_object.dart';
import 'report_chart.dart';
import 'report_enums.dart';
import 'report_relationship.dart';
import 'report_statistic.dart';
import 'report_table.dart';
import 'recommendation_knowledge_object.dart';

/// Permanent, interconnected Report Knowledge Object in the GARUDA Reports & Indices Library.
/// Every Report is modelled as an independent, searchable Knowledge Object whose internal
/// structure (chapters, indicators, recommendations, statistics) can be linked to the
/// Constitution, Acts, Committees, Schemes, Case Law, Doctrines, Current Affairs and PYQs.
@immutable
class ReportKnowledgeObject {
  final String id;
  final String officialTitle;
  final String shortName;
  final ReportCategory category;
  final String publishingOrganisation;
  final String publishingMinistry;
  final int publicationYear;
  final String edition;
  final PublicationFrequency publicationFrequency;
  final String officialUrl;
  final String officialPdfUrl;
  final String executiveSummary;
  final List<String> objectives;
  final String methodology;
  final List<String> keyFindings;
  final List<String> keyIndicators;
  final List<RecommendationKnowledgeObject> recommendations;
  final List<ReportStatistic> importantStatistics;
  final List<ReportTableMetadata> importantTables;
  final List<ReportChartMetadata> importantCharts;
  final List<ChapterKnowledgeObject> chapters;
  final String upscRelevance;
  final List<String> relatedIndexIds;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<ReportRelationship> relationships;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  ReportKnowledgeObject({
    required this.id,
    required this.officialTitle,
    this.shortName = '',
    this.category = ReportCategory.economy,
    this.publishingOrganisation = '',
    this.publishingMinistry = '',
    this.publicationYear = 0,
    this.edition = '',
    this.publicationFrequency = PublicationFrequency.annual,
    this.officialUrl = '',
    this.officialPdfUrl = '',
    this.executiveSummary = '',
    this.objectives = const [],
    this.methodology = '',
    this.keyFindings = const [],
    this.keyIndicators = const [],
    this.recommendations = const [],
    this.importantStatistics = const [],
    this.importantTables = const [],
    this.importantCharts = const [],
    this.chapters = const [],
    this.upscRelevance = '',
    this.relatedIndexIds = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedCaseLawIds = const [],
    this.relatedDoctrineIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
    this.relationships = const [],
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
      title: officialTitle,
      subject: category.displayName,
      topic: shortName.isNotEmpty ? shortName : officialTitle,
      subtopic: publishingOrganisation,
      summary: executiveSummary,
      content:
          'Report: $officialTitle. Publisher: $publishingOrganisation. Year: $publicationYear. Methodology: $methodology. Key Findings: ${keyFindings.join("; ")}. Key Indicators: ${keyIndicators.join("; ")}. Recommendations: ${recommendations.map((r) => r.title).join("; ")}.',
      officialSource: publishingOrganisation,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'ReportKnowledgeObject',
      relatedArticles: relatedArticleIds,
      relatedCaseLaws: relatedCaseLawIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'publicationYear': publicationYear,
        'edition': edition,
        'publicationFrequency': publicationFrequency.name,
        'publishingMinistry': publishingMinistry,
        'relatedIndexIds': relatedIndexIds,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'officialUrl': officialUrl,
        'officialPdfUrl': officialPdfUrl,
      },
    );
  }

  ReportKnowledgeObject copyWith({
    String? id,
    String? officialTitle,
    String? shortName,
    ReportCategory? category,
    String? publishingOrganisation,
    String? publishingMinistry,
    int? publicationYear,
    String? edition,
    PublicationFrequency? publicationFrequency,
    String? officialUrl,
    String? officialPdfUrl,
    String? executiveSummary,
    List<String>? objectives,
    String? methodology,
    List<String>? keyFindings,
    List<String>? keyIndicators,
    List<RecommendationKnowledgeObject>? recommendations,
    List<ReportStatistic>? importantStatistics,
    List<ReportTableMetadata>? importantTables,
    List<ReportChartMetadata>? importantCharts,
    List<ChapterKnowledgeObject>? chapters,
    String? upscRelevance,
    List<String>? relatedIndexIds,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<ReportRelationship>? relationships,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return ReportKnowledgeObject(
      id: id ?? this.id,
      officialTitle: officialTitle ?? this.officialTitle,
      shortName: shortName ?? this.shortName,
      category: category ?? this.category,
      publishingOrganisation:
          publishingOrganisation ?? this.publishingOrganisation,
      publishingMinistry: publishingMinistry ?? this.publishingMinistry,
      publicationYear: publicationYear ?? this.publicationYear,
      edition: edition ?? this.edition,
      publicationFrequency: publicationFrequency ?? this.publicationFrequency,
      officialUrl: officialUrl ?? this.officialUrl,
      officialPdfUrl: officialPdfUrl ?? this.officialPdfUrl,
      executiveSummary: executiveSummary ?? this.executiveSummary,
      objectives: objectives ?? List.from(this.objectives),
      methodology: methodology ?? this.methodology,
      keyFindings: keyFindings ?? List.from(this.keyFindings),
      keyIndicators: keyIndicators ?? List.from(this.keyIndicators),
      recommendations: recommendations ?? List.from(this.recommendations),
      importantStatistics:
          importantStatistics ?? List.from(this.importantStatistics),
      importantTables: importantTables ?? List.from(this.importantTables),
      importantCharts: importantCharts ?? List.from(this.importantCharts),
      chapters: chapters ?? List.from(this.chapters),
      upscRelevance: upscRelevance ?? this.upscRelevance,
      relatedIndexIds: relatedIndexIds ?? List.from(this.relatedIndexIds),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedSchemeNames:
          relatedSchemeNames ?? List.from(this.relatedSchemeNames),
      relatedCaseLawIds: relatedCaseLawIds ?? List.from(this.relatedCaseLawIds),
      relatedDoctrineIds:
          relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      relationships: relationships ?? List.from(this.relationships),
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      keywords: keywords ?? List.from(this.keywords),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'officialTitle': officialTitle,
        'shortName': shortName,
        'category': category.name,
        'publishingOrganisation': publishingOrganisation,
        'publishingMinistry': publishingMinistry,
        'publicationYear': publicationYear,
        'edition': edition,
        'publicationFrequency': publicationFrequency.name,
        'officialUrl': officialUrl,
        'officialPdfUrl': officialPdfUrl,
        'executiveSummary': executiveSummary,
        'objectives': objectives,
        'methodology': methodology,
        'keyFindings': keyFindings,
        'keyIndicators': keyIndicators,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'importantStatistics':
            importantStatistics.map((s) => s.toJson()).toList(),
        'importantTables': importantTables.map((t) => t.toJson()).toList(),
        'importantCharts': importantCharts.map((c) => c.toJson()).toList(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'upscRelevance': upscRelevance,
        'relatedIndexIds': relatedIndexIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory ReportKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      ReportKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialTitle: json['officialTitle'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        category: ReportCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ReportCategory.economy,
        ),
        publishingOrganisation: json['publishingOrganisation'] as String? ?? '',
        publishingMinistry: json['publishingMinistry'] as String? ?? '',
        publicationYear: (json['publicationYear'] as num?)?.toInt() ?? 0,
        edition: json['edition'] as String? ?? '',
        publicationFrequency: PublicationFrequency.values.firstWhere(
          (f) => f.name == json['publicationFrequency'],
          orElse: () => PublicationFrequency.annual,
        ),
        officialUrl: json['officialUrl'] as String? ?? '',
        officialPdfUrl: json['officialPdfUrl'] as String? ?? '',
        executiveSummary: json['executiveSummary'] as String? ?? '',
        objectives:
            (json['objectives'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        methodology: json['methodology'] as String? ?? '',
        keyFindings:
            (json['keyFindings'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        keyIndicators: (json['keyIndicators'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        recommendations: (json['recommendations'] as List?)
                ?.map((r) => RecommendationKnowledgeObject.fromJson(
                    Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        importantStatistics: (json['importantStatistics'] as List?)
                ?.map((s) => ReportStatistic.fromJson(
                    Map<String, dynamic>.from(s as Map)))
                .toList() ??
            const [],
        importantTables: (json['importantTables'] as List?)
                ?.map((t) => ReportTableMetadata.fromJson(
                    Map<String, dynamic>.from(t as Map)))
                .toList() ??
            const [],
        importantCharts: (json['importantCharts'] as List?)
                ?.map((c) => ReportChartMetadata.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList() ??
            const [],
        chapters: (json['chapters'] as List?)
                ?.map((c) => ChapterKnowledgeObject.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList() ??
            const [],
        upscRelevance: json['upscRelevance'] as String? ?? '',
        relatedIndexIds: (json['relatedIndexIds'] as List?)
                ?.map((e) => e.toString())
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
        relatedCommitteeIds: (json['relatedCommitteeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedSchemeNames: (json['relatedSchemeNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCaseLawIds: (json['relatedCaseLawIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedDoctrineIds: (json['relatedDoctrineIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCurrentAffairsIds: (json['relatedCurrentAffairsIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedPyqIds: (json['relatedPyqIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relationships: (json['relationships'] as List?)
                ?.map((r) => ReportRelationship.fromJson(
                    Map<String, dynamic>.from(r as Map)))
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
