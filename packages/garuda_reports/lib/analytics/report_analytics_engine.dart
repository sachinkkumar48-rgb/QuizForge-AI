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
  final Map<String, String> indexRankings;

  const ReportAnalyticsReport({
    required this.totalReports,
    required this.totalIndices,
    required this.totalSurveys,
    required this.totalIndicators,
    required this.publisherDistribution,
    required this.categoryDistribution,
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
    required this.indexRankings,
  });
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
        indexRankings: const {},
      );
    }

    final pubDist = <String, int>{};
    final catDist = <ReportCategory, int>{};
    final yearDist = <int, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final committeeMap = <String, int>{};
    final schemeMap = <String, int>{};

    int totalIndicatorsCount = 0;
    int totalRecs = 0;
    int totalChapters = 0;
    int totalStats = 0;
    int totalPyqs = 0;
    int totalCa = 0;

    for (final r in reports) {
      final pub = r.publishingOrganisation.isNotEmpty
          ? r.publishingOrganisation
          : 'Unspecified';
      pubDist[pub] = (pubDist[pub] ?? 0) + 1;
      catDist[r.category] = (catDist[r.category] ?? 0) + 1;
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
      for (final chapter in r.chapters) {
        totalRecs += chapter.recommendations.length;
        totalStats += chapter.statistics.length;
        totalPyqs += chapter.relatedPyqIds.length;
        totalCa += chapter.relatedCurrentAffairsIds.length;
      }
    }

    final count = reports.length;

    final indexRankings = <String, String>{
      for (final idx in indices) idx.id: idx.indiasRanking,
    };

    return ReportAnalyticsReport(
      totalReports: count,
      totalIndices: indices.length,
      totalSurveys: surveys.length,
      totalIndicators: indicators.length,
      publisherDistribution: Map.unmodifiable(pubDist),
      categoryDistribution: Map.unmodifiable(catDist),
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
      indexRankings: Map.unmodifiable(indexRankings),
    );
  }
}
