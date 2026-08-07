library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'chapter_knowledge_object.dart';
import 'report_chart.dart';
import 'report_enums.dart';
import 'report_statistic.dart';
import 'report_table.dart';

/// First-class Survey Knowledge Object representing official statistical surveys.
@immutable
class SurveyKnowledgeObject {
  final String id;
  final String officialTitle;
  final String shortName;
  final String publishingOrganisation;
  final String publishingMinistry;
  final int surveyYear;
  final String referencePeriod;
  final PublicationFrequency frequency;
  final String sampleSize;
  final String sampleFrame;
  final String methodology;
  final String officialUrl;
  final String officialPdfUrl;
  final String executiveSummary;
  final List<String> objectives;
  final List<String> keyFindings;
  final List<ReportStatistic> importantStatistics;
  final List<ReportTableMetadata> importantTables;
  final List<ReportChartMetadata> importantCharts;
  final List<ChapterKnowledgeObject> chapters;
  final String upscRelevance;
  final List<String> relatedReportIds;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<String> evidenceIds;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  SurveyKnowledgeObject({
    required this.id,
    required this.officialTitle,
    this.shortName = '',
    this.publishingOrganisation = '',
    this.publishingMinistry = '',
    this.surveyYear = 0,
    this.referencePeriod = '',
    this.frequency = PublicationFrequency.annual,
    this.sampleSize = '',
    this.sampleFrame = '',
    this.methodology = '',
    this.officialUrl = '',
    this.officialPdfUrl = '',
    this.executiveSummary = '',
    this.objectives = const [],
    this.keyFindings = const [],
    this.importantStatistics = const [],
    this.importantTables = const [],
    this.importantCharts = const [],
    this.chapters = const [],
    this.upscRelevance = '',
    this.relatedReportIds = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedCaseLawIds = const [],
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
      title: officialTitle,
      subject: ReportCategory.statistics.displayName,
      topic: shortName.isNotEmpty ? shortName : officialTitle,
      subtopic: publishingOrganisation,
      summary: executiveSummary,
      content:
          'Survey: $officialTitle. Sample Size: $sampleSize. Reference Period: $referencePeriod. Methodology: $methodology. Key Findings: ${keyFindings.join("; ")}.',
      officialSource: publishingOrganisation,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_reports',
      knowledgeType: 'SurveyKnowledgeObject',
      relatedArticles: relatedArticleIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'surveyYear': surveyYear,
        'referencePeriod': referencePeriod,
        'frequency': frequency.name,
        'sampleSize': sampleSize,
        'publishingMinistry': publishingMinistry,
        'relatedReportIds': relatedReportIds,
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

  SurveyKnowledgeObject copyWith({
    String? id,
    String? officialTitle,
    String? shortName,
    String? publishingOrganisation,
    String? publishingMinistry,
    int? surveyYear,
    String? referencePeriod,
    PublicationFrequency? frequency,
    String? sampleSize,
    String? sampleFrame,
    String? methodology,
    String? officialUrl,
    String? officialPdfUrl,
    String? executiveSummary,
    List<String>? objectives,
    List<String>? keyFindings,
    List<ReportStatistic>? importantStatistics,
    List<ReportTableMetadata>? importantTables,
    List<ReportChartMetadata>? importantCharts,
    List<ChapterKnowledgeObject>? chapters,
    String? upscRelevance,
    List<String>? relatedReportIds,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedSchemeNames,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<String>? evidenceIds,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return SurveyKnowledgeObject(
      id: id ?? this.id,
      officialTitle: officialTitle ?? this.officialTitle,
      shortName: shortName ?? this.shortName,
      publishingOrganisation:
          publishingOrganisation ?? this.publishingOrganisation,
      publishingMinistry: publishingMinistry ?? this.publishingMinistry,
      surveyYear: surveyYear ?? this.surveyYear,
      referencePeriod: referencePeriod ?? this.referencePeriod,
      frequency: frequency ?? this.frequency,
      sampleSize: sampleSize ?? this.sampleSize,
      sampleFrame: sampleFrame ?? this.sampleFrame,
      methodology: methodology ?? this.methodology,
      officialUrl: officialUrl ?? this.officialUrl,
      officialPdfUrl: officialPdfUrl ?? this.officialPdfUrl,
      executiveSummary: executiveSummary ?? this.executiveSummary,
      objectives: objectives ?? List.from(this.objectives),
      keyFindings: keyFindings ?? List.from(this.keyFindings),
      importantStatistics:
          importantStatistics ?? List.from(this.importantStatistics),
      importantTables: importantTables ?? List.from(this.importantTables),
      importantCharts: importantCharts ?? List.from(this.importantCharts),
      chapters: chapters ?? List.from(this.chapters),
      upscRelevance: upscRelevance ?? this.upscRelevance,
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
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
        'publishingOrganisation': publishingOrganisation,
        'publishingMinistry': publishingMinistry,
        'surveyYear': surveyYear,
        'referencePeriod': referencePeriod,
        'frequency': frequency.name,
        'sampleSize': sampleSize,
        'sampleFrame': sampleFrame,
        'methodology': methodology,
        'officialUrl': officialUrl,
        'officialPdfUrl': officialPdfUrl,
        'executiveSummary': executiveSummary,
        'objectives': objectives,
        'keyFindings': keyFindings,
        'importantStatistics':
            importantStatistics.map((s) => s.toJson()).toList(),
        'importantTables': importantTables.map((t) => t.toJson()).toList(),
        'importantCharts': importantCharts.map((c) => c.toJson()).toList(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'upscRelevance': upscRelevance,
        'relatedReportIds': relatedReportIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory SurveyKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      SurveyKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialTitle: json['officialTitle'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        publishingOrganisation: json['publishingOrganisation'] as String? ?? '',
        publishingMinistry: json['publishingMinistry'] as String? ?? '',
        surveyYear: (json['surveyYear'] as num?)?.toInt() ?? 0,
        referencePeriod: json['referencePeriod'] as String? ?? '',
        frequency: PublicationFrequency.values.firstWhere(
          (f) => f.name == json['frequency'],
          orElse: () => PublicationFrequency.annual,
        ),
        sampleSize: json['sampleSize'] as String? ?? '',
        sampleFrame: json['sampleFrame'] as String? ?? '',
        methodology: json['methodology'] as String? ?? '',
        officialUrl: json['officialUrl'] as String? ?? '',
        officialPdfUrl: json['officialPdfUrl'] as String? ?? '',
        executiveSummary: json['executiveSummary'] as String? ?? '',
        objectives:
            (json['objectives'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        keyFindings:
            (json['keyFindings'] as List?)?.map((e) => e.toString()).toList() ??
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
