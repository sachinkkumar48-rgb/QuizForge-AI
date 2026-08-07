library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class CurrentAffairsAnalyticsReport {
  final int totalEventsCount;
  final Map<CurrentAffairsCategory, int> categoryCounts;
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;
  final Map<String, int> topLinkedCases;
  final Map<String, int> topLinkedDoctrines;
  final Map<String, int> heatmapByMonth;
  final double averageRelevanceScore;

  const CurrentAffairsAnalyticsReport({
    required this.totalEventsCount,
    required this.categoryCounts,
    required this.topLinkedArticles,
    required this.topLinkedActs,
    required this.topLinkedCases,
    required this.topLinkedDoctrines,
    required this.heatmapByMonth,
    required this.averageRelevanceScore,
  });
}

class CurrentAffairsAnalytics {
  static CurrentAffairsAnalyticsReport generateReport(List<CurrentAffairsKnowledgeObject> objects) {
    if (objects.isEmpty) {
      return const CurrentAffairsAnalyticsReport(
        totalEventsCount: 0,
        categoryCounts: {},
        topLinkedArticles: {},
        topLinkedActs: {},
        topLinkedCases: {},
        topLinkedDoctrines: {},
        heatmapByMonth: {},
        averageRelevanceScore: 0.0,
      );
    }

    final categoryCounts = <CurrentAffairsCategory, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final caseMap = <String, int>{};
    final doctrineMap = <String, int>{};
    final heatmap = <String, int>{};
    double totalScore = 0.0;

    for (final obj in objects) {
      categoryCounts[obj.category] = (categoryCounts[obj.category] ?? 0) + 1;
      totalScore += obj.intelligence.relevanceScore;

      final monthKey = '${obj.publicationDate.year}-${obj.publicationDate.month.toString().padLeft(2, '0')}';
      heatmap[monthKey] = (heatmap[monthKey] ?? 0) + 1;

      for (final art in obj.links.articleIds) {
        articleMap[art] = (articleMap[art] ?? 0) + 1;
      }
      for (final act in obj.links.actIds) {
        actMap[act] = (actMap[act] ?? 0) + 1;
      }
      for (final c in obj.links.caseLawIds) {
        caseMap[c] = (caseMap[c] ?? 0) + 1;
      }
      for (final d in obj.links.doctrineIds) {
        doctrineMap[d] = (doctrineMap[d] ?? 0) + 1;
      }
    }

    return CurrentAffairsAnalyticsReport(
      totalEventsCount: objects.length,
      categoryCounts: Map.unmodifiable(categoryCounts),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
      topLinkedCases: Map.unmodifiable(caseMap),
      topLinkedDoctrines: Map.unmodifiable(doctrineMap),
      heatmapByMonth: Map.unmodifiable(heatmap),
      averageRelevanceScore: double.parse((totalScore / objects.length).toStringAsFixed(1)),
    );
  }
}
