library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'report_enums.dart';

/// First-class Indicator Knowledge Object that powers the GARUDA Indicator Graph.
/// Each indicator is independently searchable and linkable to Reports, Indices,
/// Surveys, Constitution Articles, Acts, Current Affairs and PYQs.
@immutable
class IndicatorKnowledgeObject {
  final String id;
  final String name;
  final String definition;
  final String unit;
  final String value;
  final String previousValue;
  final IndicatorTrend trend;
  final int? rank;
  final String denominatorBasis;
  final String methodologyNote;
  final String source;
  final String lastVerifiedDate;
  final int referenceYear;
  final ReportCategory category;
  final String geographicalScope;
  final List<String> relatedReportIds;
  final List<String> relatedIndexIds;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedDoctrineIds;
  final List<String> relatedPyqIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  IndicatorKnowledgeObject({
    required this.id,
    required this.name,
    this.definition = '',
    this.unit = '',
    this.value = '',
    this.previousValue = '',
    this.trend = IndicatorTrend.notAvailable,
    this.rank,
    this.denominatorBasis = '',
    this.methodologyNote = '',
    this.source = '',
    this.lastVerifiedDate = '',
    this.referenceYear = 0,
    this.category = ReportCategory.statistics,
    this.geographicalScope = 'India',
    this.relatedReportIds = const [],
    this.relatedIndexIds = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedDoctrineIds = const [],
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
      title: name,
      subject: 'Reports & Indices',
      topic: source,
      subtopic: geographicalScope,
      summary: definition,
      content:
          'Indicator: $name. Value: $value $unit. Previous: $previousValue. Trend: ${trend.displayName}. Rank: $rank. Source: $source. Year: $referenceYear.',
      officialSource: source,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'IndicatorKnowledgeObject',
      relatedArticles: relatedArticleIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'category': category.name,
        'value': value,
        'previousValue': previousValue,
        'trend': trend.name,
        'rank': rank,
        'denominatorBasis': denominatorBasis,
        'methodologyNote': methodologyNote,
        'unit': unit,
        'lastVerifiedDate': lastVerifiedDate,
        'referenceYear': referenceYear,
        'geographicalScope': geographicalScope,
        'relatedReportIds': relatedReportIds,
        'relatedIndexIds': relatedIndexIds,
        'relatedActIds': relatedActIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
      },
    );
  }

  IndicatorKnowledgeObject copyWith({
    String? id,
    String? name,
    String? definition,
    String? unit,
    String? value,
    String? previousValue,
    IndicatorTrend? trend,
    int? rank,
    String? denominatorBasis,
    String? methodologyNote,
    String? source,
    String? lastVerifiedDate,
    int? referenceYear,
    ReportCategory? category,
    String? geographicalScope,
    List<String>? relatedReportIds,
    List<String>? relatedIndexIds,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedDoctrineIds,
    List<String>? relatedPyqIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return IndicatorKnowledgeObject(
      id: id ?? this.id,
      name: name ?? this.name,
      definition: definition ?? this.definition,
      unit: unit ?? this.unit,
      value: value ?? this.value,
      previousValue: previousValue ?? this.previousValue,
      trend: trend ?? this.trend,
      rank: rank ?? this.rank,
      denominatorBasis: denominatorBasis ?? this.denominatorBasis,
      methodologyNote: methodologyNote ?? this.methodologyNote,
      source: source ?? this.source,
      lastVerifiedDate: lastVerifiedDate ?? this.lastVerifiedDate,
      referenceYear: referenceYear ?? this.referenceYear,
      category: category ?? this.category,
      geographicalScope: geographicalScope ?? this.geographicalScope,
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
      relatedIndexIds: relatedIndexIds ?? List.from(this.relatedIndexIds),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedSchemeNames:
          relatedSchemeNames ?? List.from(this.relatedSchemeNames),
      relatedDoctrineIds:
          relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
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
        'name': name,
        'definition': definition,
        'unit': unit,
        'value': value,
        'previousValue': previousValue,
        'trend': trend.name,
        'rank': rank,
        'denominatorBasis': denominatorBasis,
        'methodologyNote': methodologyNote,
        'source': source,
        'lastVerifiedDate': lastVerifiedDate,
        'referenceYear': referenceYear,
        'category': category.name,
        'geographicalScope': geographicalScope,
        'relatedReportIds': relatedReportIds,
        'relatedIndexIds': relatedIndexIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory IndicatorKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      IndicatorKnowledgeObject(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        value: json['value'] as String? ?? '',
        previousValue: json['previousValue'] as String? ?? '',
        trend: IndicatorTrend.values.firstWhere(
          (t) => t.name == json['trend'],
          orElse: () => IndicatorTrend.notAvailable,
        ),
        rank: (json['rank'] as num?)?.toInt(),
        denominatorBasis: json['denominatorBasis'] as String? ?? '',
        methodologyNote: json['methodologyNote'] as String? ?? '',
        source: json['source'] as String? ?? '',
        lastVerifiedDate: json['lastVerifiedDate'] as String? ?? '',
        referenceYear: (json['referenceYear'] as num?)?.toInt() ?? 0,
        category: ReportCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ReportCategory.statistics,
        ),
        geographicalScope: json['geographicalScope'] as String? ?? 'India',
        relatedReportIds: (json['relatedReportIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
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
        relatedSchemeNames: (json['relatedSchemeNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedDoctrineIds: (json['relatedDoctrineIds'] as List?)
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
