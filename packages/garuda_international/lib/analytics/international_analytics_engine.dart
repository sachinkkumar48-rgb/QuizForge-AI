library;

import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';

/// Machine-readable analytics report for the International Organisations Library.
class InternationalAnalyticsReport {
  final int totalOrganisations;
  final Map<InternationalBodyType, int> bodyTypeDistribution;
  final Map<InternationalCategory, int> categoryDistribution;
  final Map<GeographicalRegion, int> regionDistribution;
  final Map<HeadquartersRegion, int> headquartersRegionDistribution;
  final Map<MembershipType, int> membershipTypeDistribution;
  final Map<IndiaRelationshipStatus, int> indiaRelationshipDistribution;
  final Map<int, int> foundingDecadeDistribution;
  final Map<UpscRelevanceLevel, int> upscRelevanceDistribution;
  final Map<String, int> topTreaties;
  final Map<String, int> topConventions;
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;
  final Map<String, int> topLinkedSchemes;
  final Map<String, int> topLinkedCurrentAffairs;
  final Map<String, int> topLinkedPyqs;
  final Map<String, int> topLinkedSdgs;
  final Map<String, int> mostInterconnectedOrganisations;
  final List<String> indiaRelevantOrganisations;
  final double evidenceCoverage;
  final int expectedOrganisations;
  final int importedOrganisations;
  final double coveragePercentage;

  const InternationalAnalyticsReport({
    required this.totalOrganisations,
    required this.bodyTypeDistribution,
    required this.categoryDistribution,
    required this.regionDistribution,
    required this.headquartersRegionDistribution,
    required this.membershipTypeDistribution,
    required this.indiaRelationshipDistribution,
    required this.foundingDecadeDistribution,
    required this.upscRelevanceDistribution,
    required this.topTreaties,
    required this.topConventions,
    required this.topLinkedArticles,
    required this.topLinkedActs,
    required this.topLinkedSchemes,
    required this.topLinkedCurrentAffairs,
    required this.topLinkedPyqs,
    required this.topLinkedSdgs,
    required this.mostInterconnectedOrganisations,
    required this.indiaRelevantOrganisations,
    required this.evidenceCoverage,
    required this.expectedOrganisations,
    required this.importedOrganisations,
    required this.coveragePercentage,
  });
}

/// Computes distributions, linkage frequencies and coverage metrics over the
/// International corpus.
class InternationalAnalyticsEngine {
  InternationalAnalyticsEngine._();

  static InternationalAnalyticsReport generateReport({
    required List<InternationalKnowledgeObject> organisations,
    int expectedOrganisations = 0,
  }) {
    if (organisations.isEmpty) {
      return InternationalAnalyticsReport(
        totalOrganisations: 0,
        bodyTypeDistribution: const {},
        categoryDistribution: const {},
        regionDistribution: const {},
        headquartersRegionDistribution: const {},
        membershipTypeDistribution: const {},
        indiaRelationshipDistribution: const {},
        foundingDecadeDistribution: const {},
        upscRelevanceDistribution: const {},
        topTreaties: const {},
        topConventions: const {},
        topLinkedArticles: const {},
        topLinkedActs: const {},
        topLinkedSchemes: const {},
        topLinkedCurrentAffairs: const {},
        topLinkedPyqs: const {},
        topLinkedSdgs: const {},
        mostInterconnectedOrganisations: const {},
        indiaRelevantOrganisations: const [],
        evidenceCoverage: 0.0,
        expectedOrganisations: expectedOrganisations,
        importedOrganisations: 0,
        coveragePercentage: 0.0,
      );
    }

    final bodyTypeDist = <InternationalBodyType, int>{};
    final categoryDist = <InternationalCategory, int>{};
    final regionDist = <GeographicalRegion, int>{};
    final hqRegionDist = <HeadquartersRegion, int>{};
    final membershipDist = <MembershipType, int>{};
    final indiaDist = <IndiaRelationshipStatus, int>{};
    final decadeDist = <int, int>{};
    final relevanceDist = <UpscRelevanceLevel, int>{};
    final treatyMap = <String, int>{};
    final conventionMap = <String, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final schemeMap = <String, int>{};
    final caMap = <String, int>{};
    final pyqMap = <String, int>{};
    final sdgMap = <String, int>{};
    final interconnected = <String, int>{};
    final indiaRelevant = <String>[];

    int totalEvidence = 0;

    for (final o in organisations) {
      bodyTypeDist[o.bodyType] = (bodyTypeDist[o.bodyType] ?? 0) + 1;
      categoryDist[o.category] = (categoryDist[o.category] ?? 0) + 1;
      regionDist[o.geographicalRegion] =
          (regionDist[o.geographicalRegion] ?? 0) + 1;
      hqRegionDist[o.headquartersRegion] =
          (hqRegionDist[o.headquartersRegion] ?? 0) + 1;
      membershipDist[o.membershipType] = (membershipDist[o.membershipType] ?? 0) + 1;
      indiaDist[o.indiaMembership] = (indiaDist[o.indiaMembership] ?? 0) + 1;
      relevanceDist[o.upscRelevance] = (relevanceDist[o.upscRelevance] ?? 0) + 1;

      final decade = (o.establishedYear ~/ 10) * 10;
      decadeDist[decade] = (decadeDist[decade] ?? 0) + 1;

      if (o.foundingTreaty.isNotEmpty) {
        treatyMap[o.foundingTreaty] = (treatyMap[o.foundingTreaty] ?? 0) + 1;
      }
      for (final c in o.importantConventions) {
        conventionMap[c] = (conventionMap[c] ?? 0) + 1;
      }
      for (final a in o.relatedArticleIds) {
        articleMap[a] = (articleMap[a] ?? 0) + 1;
      }
      for (final a in o.relatedActIds) {
        actMap[a] = (actMap[a] ?? 0) + 1;
      }
      for (final s in o.relatedSchemeIds) {
        schemeMap[s] = (schemeMap[s] ?? 0) + 1;
      }
      for (final c in o.relatedCurrentAffairsIds) {
        caMap[c] = (caMap[c] ?? 0) + 1;
      }
      for (final p in o.relatedPyqIds) {
        pyqMap[p] = (pyqMap[p] ?? 0) + 1;
      }
      for (final s in o.sdgGoals) {
        sdgMap[s] = (sdgMap[s] ?? 0) + 1;
      }

      final connectionScore = o.relationships.length + o.relatedOrganisationIds.length;
      interconnected[o.officialName] = connectionScore;

      if (o.indiaMembership == IndiaRelationshipStatus.foundingMember ||
          o.indiaMembership == IndiaRelationshipStatus.fullMember ||
          o.indiaMembership == IndiaRelationshipStatus.observer) {
        indiaRelevant.add(o.officialName);
      }

      totalEvidence += o.evidenceIds.length;
    }

    final count = organisations.length;
    final sortedInterconnected = Map<String, int>.fromEntries(
      interconnected.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return InternationalAnalyticsReport(
      totalOrganisations: count,
      bodyTypeDistribution: Map.unmodifiable(bodyTypeDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      regionDistribution: Map.unmodifiable(regionDist),
      headquartersRegionDistribution: Map.unmodifiable(hqRegionDist),
      membershipTypeDistribution: Map.unmodifiable(membershipDist),
      indiaRelationshipDistribution: Map.unmodifiable(indiaDist),
      foundingDecadeDistribution: Map.unmodifiable(decadeDist),
      upscRelevanceDistribution: Map.unmodifiable(relevanceDist),
      topTreaties: Map.unmodifiable(treatyMap),
      topConventions: Map.unmodifiable(conventionMap),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
      topLinkedSchemes: Map.unmodifiable(schemeMap),
      topLinkedCurrentAffairs: Map.unmodifiable(caMap),
      topLinkedPyqs: Map.unmodifiable(pyqMap),
      topLinkedSdgs: Map.unmodifiable(sdgMap),
      mostInterconnectedOrganisations: Map.unmodifiable(sortedInterconnected),
      indiaRelevantOrganisations: List.unmodifiable(indiaRelevant),
      evidenceCoverage: double.parse((totalEvidence / count).toStringAsFixed(1)),
      expectedOrganisations: expectedOrganisations,
      importedOrganisations: count,
      coveragePercentage: expectedOrganisations > 0
          ? double.parse(((count / expectedOrganisations) * 100).toStringAsFixed(1))
          : 0.0,
    );
  }
}
