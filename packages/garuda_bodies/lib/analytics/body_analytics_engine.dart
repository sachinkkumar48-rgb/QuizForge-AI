library;

import '../domain/entities/body_enums.dart';
import '../domain/entities/body_knowledge_object.dart';

/// Machine-readable analytics report for the Government Bodies Library.
class BodyAnalyticsReport {
  final int totalBodies;
  final Map<BodyType, int> bodyTypeDistribution;
  final Map<BodyCategory, int> categoryDistribution;
  final Map<String, int> ministryDistribution;
  final Map<ConstitutionalBasis, int> constitutionalBasisDistribution;
  final Map<StatutoryBasis, int> statutoryBasisDistribution;
  final Map<BodyJurisdiction, int> jurisdictionDistribution;
  final Map<int, int> yearEstablishedDistribution;
  final Map<UpscRelevanceLevel, int> upscRelevanceDistribution;
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;
  final Map<String, int> topLinkedCases;
  final Map<String, int> topLinkedDoctrines;
  final Map<String, int> topLinkedCommittees;
  final Map<String, int> topLinkedReports;
  final Map<String, int> topLinkedSchemes;
  final Map<String, int> topLinkedPyqs;
  final Map<String, int> topLinkedCurrentAffairs;
  final Map<String, int> mostInterconnectedBodies;
  final double averageArticleLinksPerBody;
  final double averageActLinksPerBody;
  final double evidenceCoverage;
  final int expectedBodies;
  final int importedBodies;
  final double coveragePercentage;

  const BodyAnalyticsReport({
    required this.totalBodies,
    required this.bodyTypeDistribution,
    required this.categoryDistribution,
    required this.ministryDistribution,
    required this.constitutionalBasisDistribution,
    required this.statutoryBasisDistribution,
    required this.jurisdictionDistribution,
    required this.yearEstablishedDistribution,
    required this.upscRelevanceDistribution,
    required this.topLinkedArticles,
    required this.topLinkedActs,
    required this.topLinkedCases,
    required this.topLinkedDoctrines,
    required this.topLinkedCommittees,
    required this.topLinkedReports,
    required this.topLinkedSchemes,
    required this.topLinkedPyqs,
    required this.topLinkedCurrentAffairs,
    required this.mostInterconnectedBodies,
    required this.averageArticleLinksPerBody,
    required this.averageActLinksPerBody,
    required this.evidenceCoverage,
    required this.expectedBodies,
    required this.importedBodies,
    required this.coveragePercentage,
  });
}

/// Computes distributions, linkage frequencies and coverage metrics over the
/// Bodies corpus.
class BodyAnalyticsEngine {
  BodyAnalyticsEngine._();

  static BodyAnalyticsReport generateReport({
    required List<BodyKnowledgeObject> bodies,
    int expectedBodies = 0,
  }) {
    if (bodies.isEmpty) {
      return BodyAnalyticsReport(
        totalBodies: 0,
        bodyTypeDistribution: const {},
        categoryDistribution: const {},
        ministryDistribution: const {},
        constitutionalBasisDistribution: const {},
        statutoryBasisDistribution: const {},
        jurisdictionDistribution: const {},
        yearEstablishedDistribution: const {},
        upscRelevanceDistribution: const {},
        topLinkedArticles: const {},
        topLinkedActs: const {},
        topLinkedCases: const {},
        topLinkedDoctrines: const {},
        topLinkedCommittees: const {},
        topLinkedReports: const {},
        topLinkedSchemes: const {},
        topLinkedPyqs: const {},
        topLinkedCurrentAffairs: const {},
        mostInterconnectedBodies: const {},
        averageArticleLinksPerBody: 0.0,
        averageActLinksPerBody: 0.0,
        evidenceCoverage: 0.0,
        expectedBodies: expectedBodies,
        importedBodies: 0,
        coveragePercentage: 0.0,
      );
    }

    final typeDist = <BodyType, int>{};
    final categoryDist = <BodyCategory, int>{};
    final ministryDist = <String, int>{};
    final constitutionalDist = <ConstitutionalBasis, int>{};
    final statutoryDist = <StatutoryBasis, int>{};
    final jurisdictionDist = <BodyJurisdiction, int>{};
    final yearDist = <int, int>{};
    final relevanceDist = <UpscRelevanceLevel, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final caseMap = <String, int>{};
    final doctrineMap = <String, int>{};
    final committeeMap = <String, int>{};
    final reportMap = <String, int>{};
    final schemeMap = <String, int>{};
    final pyqMap = <String, int>{};
    final caMap = <String, int>{};
    final interconnected = <String, int>{};

    int totalArticles = 0;
    int totalActs = 0;
    int totalEvidence = 0;

    for (final b in bodies) {
      typeDist[b.bodyType] = (typeDist[b.bodyType] ?? 0) + 1;
      categoryDist[b.category] = (categoryDist[b.category] ?? 0) + 1;
      final oversight = b.parentMinistry.isNotEmpty
          ? b.parentMinistry
          : 'Unspecified';
      ministryDist[oversight] = (ministryDist[oversight] ?? 0) + 1;
      constitutionalDist[b.constitutionalBasis] =
          (constitutionalDist[b.constitutionalBasis] ?? 0) + 1;
      statutoryDist[b.statutoryBasis] = (statutoryDist[b.statutoryBasis] ?? 0) + 1;
      jurisdictionDist[b.jurisdiction] = (jurisdictionDist[b.jurisdiction] ?? 0) + 1;
      yearDist[b.yearEstablished] = (yearDist[b.yearEstablished] ?? 0) + 1;
      relevanceDist[b.upscRelevance] = (relevanceDist[b.upscRelevance] ?? 0) + 1;

      for (final a in [...b.establishingArticleIds, ...b.relatedArticleIds]) {
        articleMap[a] = (articleMap[a] ?? 0) + 1;
      }
      for (final a in [...b.establishingActIds, ...b.relatedActIds]) {
        actMap[a] = (actMap[a] ?? 0) + 1;
      }
      for (final c in b.relatedCaseLawIds) {
        caseMap[c] = (caseMap[c] ?? 0) + 1;
      }
      for (final d in b.relatedDoctrineIds) {
        doctrineMap[d] = (doctrineMap[d] ?? 0) + 1;
      }
      for (final c in b.relatedCommitteeIds) {
        committeeMap[c] = (committeeMap[c] ?? 0) + 1;
      }
      for (final r in b.relatedReportIds) {
        reportMap[r] = (reportMap[r] ?? 0) + 1;
      }
      for (final s in b.relatedSchemeIds) {
        schemeMap[s] = (schemeMap[s] ?? 0) + 1;
      }
      for (final p in b.relatedPyqIds) {
        pyqMap[p] = (pyqMap[p] ?? 0) + 1;
      }
      for (final c in b.relatedCurrentAffairsIds) {
        caMap[c] = (caMap[c] ?? 0) + 1;
      }

      final connectionScore =
          b.relationships.length + b.relatedBodyIds.length;
      interconnected[b.officialName] = connectionScore;

      totalArticles +=
          b.establishingArticleIds.length + b.relatedArticleIds.length;
      totalActs += b.establishingActIds.length + b.relatedActIds.length;
      totalEvidence += b.evidenceIds.length;
    }

    final count = bodies.length;
    final sortedInterconnected = Map<String, int>.fromEntries(
      interconnected.entries.toList()
        ..sort((a, c) => c.value.compareTo(a.value)),
    );

    return BodyAnalyticsReport(
      totalBodies: count,
      bodyTypeDistribution: Map.unmodifiable(typeDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      ministryDistribution: Map.unmodifiable(ministryDist),
      constitutionalBasisDistribution: Map.unmodifiable(constitutionalDist),
      statutoryBasisDistribution: Map.unmodifiable(statutoryDist),
      jurisdictionDistribution: Map.unmodifiable(jurisdictionDist),
      yearEstablishedDistribution: Map.unmodifiable(yearDist),
      upscRelevanceDistribution: Map.unmodifiable(relevanceDist),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
      topLinkedCases: Map.unmodifiable(caseMap),
      topLinkedDoctrines: Map.unmodifiable(doctrineMap),
      topLinkedCommittees: Map.unmodifiable(committeeMap),
      topLinkedReports: Map.unmodifiable(reportMap),
      topLinkedSchemes: Map.unmodifiable(schemeMap),
      topLinkedPyqs: Map.unmodifiable(pyqMap),
      topLinkedCurrentAffairs: Map.unmodifiable(caMap),
      mostInterconnectedBodies: Map.unmodifiable(sortedInterconnected),
      averageArticleLinksPerBody:
          double.parse((totalArticles / count).toStringAsFixed(1)),
      averageActLinksPerBody:
          double.parse((totalActs / count).toStringAsFixed(1)),
      evidenceCoverage:
          double.parse((totalEvidence / count).toStringAsFixed(1)),
      expectedBodies: expectedBodies,
      importedBodies: count,
      coveragePercentage: expectedBodies > 0
          ? double.parse(((count / expectedBodies) * 100).toStringAsFixed(1))
          : 0.0,
    );
  }
}
