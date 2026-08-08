library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';

class ReportAnalyticsReport {
  final int totalReports;
  final int totalIndices;
  final int totalSurveys;
  final int totalIndicators;
  final Map<String, int> publisherDistribution;
  final Map<ReportCategory, int> categoryDistribution;
  final Map<ReportType, int> reportTypeDistribution;
  final Map<String, int> ministryDistribution;
  final Map<String, int> sectorFrequency;
  final Map<String, int> themeFrequency;
  final Map<RelevanceLevel, int> prelimsRelevanceDistribution;
  final Map<int, int> yearDistribution;
  final double indicatorCoverage; // average key indicators per report
  final double recommendationCoverage; // average recommendations per report
  final double chapterCoverage; // average chapters per report
  final double statisticCoverage; // average statistics per report
  final double pyqMappingDensity; // average PYQ links per report
  final double
      currentAffairsLinkDensity; // average Current Affairs links per report
  final double upscFrequency; // average total exam links (PYQ + CA) per report
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;
  final Map<String, int> topLinkedCommittees;
  final Map<String, int> topLinkedSchemes;
  final Map<String, int> topLinkedBodies;
  final Map<String, int> topLinkedInternationalOrganisations;
  final Map<String, String> indexRankings;
  final int indiaCoverageCount;
  final Map<String, int> sdgDistribution;
  final double evidenceCoverage;
  final Map<String, int> indicatorFrequency;
  final Map<String, int> rankingFrequency;
  final Map<String, int> crossPackageLinkFrequency;
  final List<String> mostInterconnectedReports;

  const ReportAnalyticsReport({
    required this.totalReports,
    required this.totalIndices,
    required this.totalSurveys,
    required this.totalIndicators,
    required this.publisherDistribution,
    required this.categoryDistribution,
    required this.reportTypeDistribution,
    required this.ministryDistribution,
    required this.sectorFrequency,
    required this.themeFrequency,
    required this.prelimsRelevanceDistribution,
    required this.yearDistribution,
    required this.indicatorCoverage,
    required this.recommendationCoverage,
    required this.chapterCoverage,
    required this.statisticCoverage,
    required this.pyqMappingDensity,
    required this.currentAffairsLinkDensity,
    required this.upscFrequency,
    required this.topLinkedArticles,
    required this.topLinkedActs,
    required this.topLinkedCommittees,
    required this.topLinkedSchemes,
    required this.topLinkedBodies,
    required this.topLinkedInternationalOrganisations,
    required this.indexRankings,
    required this.indiaCoverageCount,
    required this.sdgDistribution,
    required this.evidenceCoverage,
    required this.indicatorFrequency,
    required this.rankingFrequency,
    required this.crossPackageLinkFrequency,
    required this.mostInterconnectedReports,
  });

  /// JSON-serialisable summary of the analytics report.
  Map<String, dynamic> toJson() => {
        'totalReports': totalReports,
        'totalIndices': totalIndices,
        'totalSurveys': totalSurveys,
        'totalIndicators': totalIndicators,
        'indiaCoverageCount': indiaCoverageCount,
        'publisherDistribution': publisherDistribution,
        'categoryDistribution': {
          for (final e in categoryDistribution.entries) e.key.name: e.value
        },
        'reportTypeDistribution': {
          for (final e in reportTypeDistribution.entries) e.key.name: e.value
        },
        'ministryDistribution': ministryDistribution,
        'sectorFrequency': sectorFrequency,
        'themeFrequency': themeFrequency,
        'prelimsRelevanceDistribution': {
          for (final e in prelimsRelevanceDistribution.entries)
            e.key.name: e.value
        },
        'yearDistribution': {
          for (final e in yearDistribution.entries) e.key.toString(): e.value
        },
        'indicatorCoverage': indicatorCoverage,
        'recommendationCoverage': recommendationCoverage,
        'chapterCoverage': chapterCoverage,
        'statisticCoverage': statisticCoverage,
        'pyqMappingDensity': pyqMappingDensity,
        'currentAffairsLinkDensity': currentAffairsLinkDensity,
        'upscFrequency': upscFrequency,
        'evidenceCoverage': evidenceCoverage,
        'sdgDistribution': sdgDistribution,
        'indicatorFrequency': indicatorFrequency,
        'rankingFrequency': rankingFrequency,
        'crossPackageLinkFrequency': crossPackageLinkFrequency,
        'mostInterconnectedReports': mostInterconnectedReports,
        'topLinkedArticles': topLinkedArticles,
        'topLinkedActs': topLinkedActs,
        'topLinkedCommittees': topLinkedCommittees,
        'topLinkedSchemes': topLinkedSchemes,
        'topLinkedBodies': topLinkedBodies,
        'topLinkedInternationalOrganisations':
            topLinkedInternationalOrganisations,
        'indexRankings': indexRankings,
      };
}

class ReportAnalyticsEngine {
  static ReportAnalyticsReport generateReport({
    required List<ReportKnowledgeObject> reports,
    List<IndexKnowledgeObject> indices = const [],
    List<SurveyKnowledgeObject> surveys = const [],
    List<IndicatorKnowledgeObject> indicators = const [],
  }) {
    if (reports.isEmpty) {
      return ReportAnalyticsReport(
        totalReports: 0,
        totalIndices: indices.length,
        totalSurveys: surveys.length,
        totalIndicators: indicators.length,
        publisherDistribution: const {},
        categoryDistribution: const {},
        reportTypeDistribution: const {},
        ministryDistribution: const {},
        sectorFrequency: const {},
        themeFrequency: const {},
        prelimsRelevanceDistribution: const {},
        yearDistribution: const {},
        indicatorCoverage: 0.0,
        recommendationCoverage: 0.0,
        chapterCoverage: 0.0,
        statisticCoverage: 0.0,
        pyqMappingDensity: 0.0,
        currentAffairsLinkDensity: 0.0,
        upscFrequency: 0.0,
        topLinkedArticles: const {},
        topLinkedActs: const {},
        topLinkedCommittees: const {},
        topLinkedSchemes: const {},
        topLinkedBodies: const {},
        topLinkedInternationalOrganisations: const {},
        indexRankings: const {},
        indiaCoverageCount: 0,
        sdgDistribution: const {},
        evidenceCoverage: 0.0,
        indicatorFrequency: const {},
        rankingFrequency: const {},
        crossPackageLinkFrequency: const {},
        mostInterconnectedReports: const [],
      );
    }

    final pubDist = <String, int>{};
    final catDist = <ReportCategory, int>{};
    final typeDist = <ReportType, int>{};
    final ministryDist = <String, int>{};
    final sectorDist = <String, int>{};
    final themeDist = <String, int>{};
    final relevanceDist = <RelevanceLevel, int>{};
    final yearDist = <int, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final committeeMap = <String, int>{};
    final schemeMap = <String, int>{};
    final bodyMap = <String, int>{};
    final internationalMap = <String, int>{};
    final sdgMap = <String, int>{};
    final indicatorFreq = <String, int>{};
    final rankingFreq = <String, int>{};
    final crossPackageMap = <String, int>{};
    final interconnectivity = <String, int>{};

    int totalIndicatorsCount = 0;
    int totalRecs = 0;
    int totalChapters = 0;
    int totalStats = 0;
    int totalPyqs = 0;
    int totalCa = 0;
    int indiaCount = 0;
    int evidenceCount = 0;

    for (final r in reports) {
      final pub = r.publishingOrganisation.isNotEmpty
          ? r.publishingOrganisation
          : 'Unspecified';
      pubDist[pub] = (pubDist[pub] ?? 0) + 1;
      catDist[r.category] = (catDist[r.category] ?? 0) + 1;
      typeDist[r.reportType] = (typeDist[r.reportType] ?? 0) + 1;
      final ministry = r.publishingMinistry.isNotEmpty
          ? r.publishingMinistry
          : 'Unspecified';
      ministryDist[ministry] = (ministryDist[ministry] ?? 0) + 1;
      for (final s in r.sectors) {
        sectorDist[s] = (sectorDist[s] ?? 0) + 1;
      }
      for (final t in r.themes) {
        themeDist[t] = (themeDist[t] ?? 0) + 1;
      }
      relevanceDist[r.prelimsRelevance] = (relevanceDist[r.prelimsRelevance] ?? 0) + 1;
      yearDist[r.publicationYear] = (yearDist[r.publicationYear] ?? 0) + 1;

      totalIndicatorsCount += r.keyIndicators.length;
      totalRecs += r.recommendations.length;
      totalChapters += r.chapters.length;
      totalStats += r.importantStatistics.length;
      totalPyqs += r.relatedPyqIds.length;
      totalCa += r.relatedCurrentAffairsIds.length;

      for (final a in r.relatedArticleIds) {
        articleMap[a] = (articleMap[a] ?? 0) + 1;
      }
      for (final a in r.relatedActIds) {
        actMap[a] = (actMap[a] ?? 0) + 1;
      }
      for (final c in r.relatedCommitteeIds) {
        committeeMap[c] = (committeeMap[c] ?? 0) + 1;
      }
      for (final s in r.relatedSchemeNames) {
        schemeMap[s] = (schemeMap[s] ?? 0) + 1;
      }
      for (final b in r.relatedBodies) {
        bodyMap[b] = (bodyMap[b] ?? 0) + 1;
      }
      for (final o in r.relatedInternationalOrganisations) {
        internationalMap[o] = (internationalMap[o] ?? 0) + 1;
      }
      for (final chapter in r.chapters) {
        totalRecs += chapter.recommendations.length;
        totalStats += chapter.statistics.length;
        totalPyqs += chapter.relatedPyqIds.length;
        totalCa += chapter.relatedCurrentAffairsIds.length;
      }

      if (r.indiaCoverage) indiaCount++;
      if (r.evidenceIds.isNotEmpty) evidenceCount++;
      for (final s in r.sdgGoals) {
        sdgMap[s] = (sdgMap[s] ?? 0) + 1;
      }
      for (final ind in r.keyIndicators) {
        indicatorFreq[ind] = (indicatorFreq[ind] ?? 0) + 1;
      }
      for (final idx in r.relatedIndexIds) {
        rankingFreq[idx] = (rankingFreq[idx] ?? 0) + 1;
      }

      final crossLinks = <String>[
        ...r.relatedArticleIds,
        ...r.relatedActIds,
        ...r.relatedCommitteeIds,
        ...r.relatedSchemeNames,
        ...r.relatedBodies,
        ...r.relatedInternationalOrganisations,
        ...r.relatedCurrentAffairsIds,
        ...r.relatedPyqIds,
      ];
      for (final link in crossLinks) {
        crossPackageMap[link] = (crossPackageMap[link] ?? 0) + 1;
      }
      interconnectivity[r.id] = crossLinks.length;
    }

    final count = reports.length;

    final indexRankings = <String, String>{
      for (final idx in indices) idx.id: idx.indiasRanking,
    };

    final interconnectedSorted = interconnectivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ReportAnalyticsReport(
      totalReports: count,
      totalIndices: indices.length,
      totalSurveys: surveys.length,
      totalIndicators: indicators.length,
      publisherDistribution: Map.unmodifiable(pubDist),
      categoryDistribution: Map.unmodifiable(catDist),
      reportTypeDistribution: Map.unmodifiable(typeDist),
      ministryDistribution: Map.unmodifiable(ministryDist),
      sectorFrequency: Map.unmodifiable(sectorDist),
      themeFrequency: Map.unmodifiable(themeDist),
      prelimsRelevanceDistribution: Map.unmodifiable(relevanceDist),
      yearDistribution: Map.unmodifiable(yearDist),
      indicatorCoverage:
          double.parse((totalIndicatorsCount / count).toStringAsFixed(1)),
      recommendationCoverage:
          double.parse((totalRecs / count).toStringAsFixed(1)),
      chapterCoverage: double.parse((totalChapters / count).toStringAsFixed(1)),
      statisticCoverage: double.parse((totalStats / count).toStringAsFixed(1)),
      pyqMappingDensity: double.parse((totalPyqs / count).toStringAsFixed(1)),
      currentAffairsLinkDensity:
          double.parse((totalCa / count).toStringAsFixed(1)),
      upscFrequency:
          double.parse(((totalPyqs + totalCa) / count).toStringAsFixed(1)),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
      topLinkedCommittees: Map.unmodifiable(committeeMap),
      topLinkedSchemes: Map.unmodifiable(schemeMap),
      topLinkedBodies: Map.unmodifiable(bodyMap),
      topLinkedInternationalOrganisations:
          Map.unmodifiable(internationalMap),
      indexRankings: Map.unmodifiable(indexRankings),
      indiaCoverageCount: indiaCount,
      sdgDistribution: Map.unmodifiable(sdgMap),
      evidenceCoverage: double.parse((evidenceCount / count).toStringAsFixed(2)),
      indicatorFrequency: Map.unmodifiable(indicatorFreq),
      rankingFrequency: Map.unmodifiable(rankingFreq),
      crossPackageLinkFrequency: Map.unmodifiable(crossPackageMap),
      mostInterconnectedReports: interconnectedSorted
          .map((e) => e.key)
          .take(10)
          .toList(),
    );
  }
}
