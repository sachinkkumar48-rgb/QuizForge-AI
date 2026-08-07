library;

import '../domain/entities/committee_enums.dart';
import '../domain/entities/committee_knowledge_object.dart';

class CommitteeAnalyticsReport {
  final int totalCommittees;
  final Map<CommitteeCategory, int> categoryDistribution;
  final Map<String, int> ministryDistribution;
  final Map<CommitteeStatus, int> statusDistribution;
  final Map<RecommendationStatus, int> recommendationStatusDistribution;
  final double averageRecommendationsPerCommittee;
  final double pyqMappingDensity; // average PYQ links per committee
  final double currentAffairsLinkDensity; // average Current Affairs links per committee
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;

  const CommitteeAnalyticsReport({
    required this.totalCommittees,
    required this.categoryDistribution,
    required this.ministryDistribution,
    required this.statusDistribution,
    required this.recommendationStatusDistribution,
    required this.averageRecommendationsPerCommittee,
    required this.pyqMappingDensity,
    required this.currentAffairsLinkDensity,
    required this.topLinkedArticles,
    required this.topLinkedActs,
  });
}

class CommitteeAnalyticsEngine {
  static CommitteeAnalyticsReport generateReport(List<CommitteeKnowledgeObject> committees) {
    if (committees.isEmpty) {
      return const CommitteeAnalyticsReport(
        totalCommittees: 0,
        categoryDistribution: {},
        ministryDistribution: {},
        statusDistribution: {},
        recommendationStatusDistribution: {},
        averageRecommendationsPerCommittee: 0.0,
        pyqMappingDensity: 0.0,
        currentAffairsLinkDensity: 0.0,
        topLinkedArticles: {},
        topLinkedActs: {},
      );
    }

    final catDist = <CommitteeCategory, int>{};
    final minDist = <String, int>{};
    final statusDist = <CommitteeStatus, int>{};
    final recStatusDist = <RecommendationStatus, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};

    int totalRecs = 0;
    int totalPyqs = 0;
    int totalCa = 0;

    for (final c in committees) {
      catDist[c.category] = (catDist[c.category] ?? 0) + 1;
      statusDist[c.currentStatus] = (statusDist[c.currentStatus] ?? 0) + 1;

      final minName = c.constitutingAuthority.isNotEmpty ? c.constitutingAuthority : 'Unspecified';
      minDist[minName] = (minDist[minName] ?? 0) + 1;

      totalRecs += c.recommendations.length;
      totalPyqs += c.relatedPyqIds.length;
      totalCa += c.relatedCurrentAffairsIds.length;

      for (final rec in c.recommendations) {
        recStatusDist[rec.status] = (recStatusDist[rec.status] ?? 0) + 1;
      }

      for (final art in c.relatedArticleIds) {
        articleMap[art] = (articleMap[art] ?? 0) + 1;
      }

      for (final act in c.relatedActIds) {
        actMap[act] = (actMap[act] ?? 0) + 1;
      }
    }

    final count = committees.length;

    return CommitteeAnalyticsReport(
      totalCommittees: count,
      categoryDistribution: Map.unmodifiable(catDist),
      ministryDistribution: Map.unmodifiable(minDist),
      statusDistribution: Map.unmodifiable(statusDist),
      recommendationStatusDistribution: Map.unmodifiable(recStatusDist),
      averageRecommendationsPerCommittee:
          double.parse((totalRecs / count).toStringAsFixed(1)),
      pyqMappingDensity: double.parse((totalPyqs / count).toStringAsFixed(1)),
      currentAffairsLinkDensity: double.parse((totalCa / count).toStringAsFixed(1)),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
    );
  }
}
