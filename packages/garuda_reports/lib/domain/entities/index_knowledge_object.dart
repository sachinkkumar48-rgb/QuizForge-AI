library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'report_enums.dart';

/// Immutable record of a single historical edition/ranking of an Index.
@immutable
class IndexEdition {
  final int editionYear;
  final String indiaRanking;
  final String indiaScore;
  final int totalEconomies;
  final String summary;

  const IndexEdition({
    required this.editionYear,
    this.indiaRanking = '',
    this.indiaScore = '',
    this.totalEconomies = 0,
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
        'editionYear': editionYear,
        'indiaRanking': indiaRanking,
        'indiaScore': indiaScore,
        'totalEconomies': totalEconomies,
        'summary': summary,
      };

  factory IndexEdition.fromJson(Map<String, dynamic> json) => IndexEdition(
        editionYear: (json['editionYear'] as num?)?.toInt() ?? 0,
        indiaRanking: json['indiaRanking'] as String? ?? '',
        indiaScore: json['indiaScore'] as String? ?? '',
        totalEconomies: (json['totalEconomies'] as num?)?.toInt() ?? 0,
        summary: json['summary'] as String? ?? '',
      );
}

/// First-class Index Knowledge Object representing a composite index/ranking publication.
@immutable
class IndexKnowledgeObject {
  final String id;
  final String indexName;
  final String publisher;
  final String publishingMinistry;
  final String methodology;
  final List<String> indicators;
  final String weightage;
  final String latestRanking;
  final String indiasRanking;
  final String indiaScore;
  final IndexTrend trend;
  final bool hasStateWiseData;
  final List<String> topStates;
  final int latestEditionYear;
  final int totalEconomies;
  final List<IndexEdition> editionHistory;
  final String officialUrl;
  final String officialPdfUrl;
  final String upscRelevance;
  final List<String> relatedReportIds;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  IndexKnowledgeObject({
    required this.id,
    required this.indexName,
    required this.publisher,
    this.publishingMinistry = '',
    this.methodology = '',
    this.indicators = const [],
    this.weightage = '',
    this.latestRanking = '',
    this.indiasRanking = '',
    this.indiaScore = '',
    this.trend = IndexTrend.firstEdition,
    this.hasStateWiseData = false,
    this.topStates = const [],
    this.latestEditionYear = 0,
    this.totalEconomies = 0,
    this.editionHistory = const [],
    this.officialUrl = '',
    this.officialPdfUrl = '',
    this.upscRelevance = '',
    this.relatedReportIds = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedDoctrineIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
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
      title: indexName,
      subject: 'Reports & Indices',
      topic: publisher,
      subtopic: methodology,
      summary:
          'India Ranking: $indiasRanking (${latestEditionYear > 0 ? latestEditionYear : ""}).',
      content:
          'Index: $indexName. Publisher: $publisher. Methodology: $methodology. Indicators: ${indicators.join("; ")}. Weightage: $weightage. Latest Ranking: $latestRanking. India Ranking: $indiasRanking. Trend: ${trend.name}.',
      officialSource: publisher,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'IndexKnowledgeObject',
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'latestEditionYear': latestEditionYear,
        'latestRanking': latestRanking,
        'indiasRanking': indiasRanking,
        'indiaScore': indiaScore,
        'trend': trend.name,
        'hasStateWiseData': hasStateWiseData,
        'topStates': topStates,
        'publishingMinistry': publishingMinistry,
        'relatedReportIds': relatedReportIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'officialUrl': officialUrl,
        'officialPdfUrl': officialPdfUrl,
      },
    );
  }

  IndexKnowledgeObject copyWith({
    String? id,
    String? indexName,
    String? publisher,
    String? publishingMinistry,
    String? methodology,
    List<String>? indicators,
    String? weightage,
    String? latestRanking,
    String? indiasRanking,
    String? indiaScore,
    IndexTrend? trend,
    bool? hasStateWiseData,
    List<String>? topStates,
    int? latestEditionYear,
    int? totalEconomies,
    List<IndexEdition>? editionHistory,
    String? officialUrl,
    String? officialPdfUrl,
    String? upscRelevance,
    List<String>? relatedReportIds,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return IndexKnowledgeObject(
      id: id ?? this.id,
      indexName: indexName ?? this.indexName,
      publisher: publisher ?? this.publisher,
      publishingMinistry: publishingMinistry ?? this.publishingMinistry,
      methodology: methodology ?? this.methodology,
      indicators: indicators ?? List.from(this.indicators),
      weightage: weightage ?? this.weightage,
      latestRanking: latestRanking ?? this.latestRanking,
      indiasRanking: indiasRanking ?? this.indiasRanking,
      indiaScore: indiaScore ?? this.indiaScore,
      trend: trend ?? this.trend,
      hasStateWiseData: hasStateWiseData ?? this.hasStateWiseData,
      topStates: topStates ?? List.from(this.topStates),
      latestEditionYear: latestEditionYear ?? this.latestEditionYear,
      totalEconomies: totalEconomies ?? this.totalEconomies,
      editionHistory: editionHistory ?? List.from(this.editionHistory),
      officialUrl: officialUrl ?? this.officialUrl,
      officialPdfUrl: officialPdfUrl ?? this.officialPdfUrl,
      upscRelevance: upscRelevance ?? this.upscRelevance,
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedSchemeNames:
          relatedSchemeNames ?? List.from(this.relatedSchemeNames),
      relatedDoctrineIds:
          relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      keywords: keywords ?? List.from(this.keywords),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'indexName': indexName,
        'publisher': publisher,
        'publishingMinistry': publishingMinistry,
        'methodology': methodology,
        'indicators': indicators,
        'weightage': weightage,
        'latestRanking': latestRanking,
        'indiasRanking': indiasRanking,
        'indiaScore': indiaScore,
        'trend': trend.name,
        'hasStateWiseData': hasStateWiseData,
        'topStates': topStates,
        'latestEditionYear': latestEditionYear,
        'totalEconomies': totalEconomies,
        'editionHistory': editionHistory.map((e) => e.toJson()).toList(),
        'officialUrl': officialUrl,
        'officialPdfUrl': officialPdfUrl,
        'upscRelevance': upscRelevance,
        'relatedReportIds': relatedReportIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory IndexKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      IndexKnowledgeObject(
        id: json['id'] as String? ?? '',
        indexName: json['indexName'] as String? ?? '',
        publisher: json['publisher'] as String? ?? '',
        publishingMinistry: json['publishingMinistry'] as String? ?? '',
        methodology: json['methodology'] as String? ?? '',
        indicators:
            (json['indicators'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        weightage: json['weightage'] as String? ?? '',
        latestRanking: json['latestRanking'] as String? ?? '',
        indiasRanking: json['indiasRanking'] as String? ?? '',
        indiaScore: json['indiaScore'] as String? ?? '',
        trend: IndexTrend.values.firstWhere(
          (t) => t.name == json['trend'],
          orElse: () => IndexTrend.firstEdition,
        ),
        hasStateWiseData: json['hasStateWiseData'] as bool? ?? false,
        topStates:
            (json['topStates'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        latestEditionYear: (json['latestEditionYear'] as num?)?.toInt() ?? 0,
        totalEconomies: (json['totalEconomies'] as num?)?.toInt() ?? 0,
        editionHistory: (json['editionHistory'] as List?)
                ?.map((e) =>
                    IndexEdition.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        officialUrl: json['officialUrl'] as String? ?? '',
        officialPdfUrl: json['officialPdfUrl'] as String? ?? '',
        upscRelevance: json['upscRelevance'] as String? ?? '',
        relatedReportIds: (json['relatedReportIds'] as List?)
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
