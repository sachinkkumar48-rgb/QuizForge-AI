library;

import '../domain/entities/scheme_beneficiary.dart';
import '../domain/entities/scheme_enums.dart';
import '../domain/entities/scheme_knowledge_object.dart';
import '../domain/entities/scheme_ministry.dart';

/// Machine-readable analytics report for the Government Schemes Library.
class SchemeAnalyticsReport {
  final int totalSchemes;
  final Map<SchemeMinistry, int> ministryDistribution;
  final Map<SchemeCategory, int> categoryDistribution;
  final Map<SchemeSector, int> sectorDistribution;
  final Map<BeneficiaryGroup, int> beneficiaryDistribution;
  final Map<int, int> launchYearDistribution;
  final Map<SchemeStatus, int> statusDistribution;
  final Map<SchemeType, int> schemeTypeDistribution;
  final Map<FundingPatternType, int> fundingPatternDistribution;
  final Map<String, int> topLinkedArticles;
  final Map<String, int> topLinkedActs;
  final Map<String, int> topLinkedCommittees;
  final Map<String, int> topLinkedReports;
  final Map<String, int> topLinkedPyqs;
  final Map<String, int> topLinkedCurrentAffairs;
  final Map<SdgGoal, int> topLinkedSdgs;
  final Map<String, int> mostInterconnectedSchemes;
  final double averageBenefitPerScheme;
  final double averageComponentPerScheme;
  final double averageSdgPerScheme;
  final double averagePyqPerScheme;
  final double averageCurrentAffairsPerScheme;
  final int expectedSchemes;
  final int importedSchemes;
  final double coveragePercentage;

  const SchemeAnalyticsReport({
    required this.totalSchemes,
    required this.ministryDistribution,
    required this.categoryDistribution,
    required this.sectorDistribution,
    required this.beneficiaryDistribution,
    required this.launchYearDistribution,
    required this.statusDistribution,
    required this.schemeTypeDistribution,
    required this.fundingPatternDistribution,
    required this.topLinkedArticles,
    required this.topLinkedActs,
    required this.topLinkedCommittees,
    required this.topLinkedReports,
    required this.topLinkedPyqs,
    required this.topLinkedCurrentAffairs,
    required this.topLinkedSdgs,
    required this.mostInterconnectedSchemes,
    required this.averageBenefitPerScheme,
    required this.averageComponentPerScheme,
    required this.averageSdgPerScheme,
    required this.averagePyqPerScheme,
    required this.averageCurrentAffairsPerScheme,
    required this.expectedSchemes,
    required this.importedSchemes,
    required this.coveragePercentage,
  });
}

/// Computes distributions, linkage frequencies and coverage metrics over the
/// Schemes corpus.
class SchemeAnalyticsEngine {
  SchemeAnalyticsEngine._();

  static SchemeAnalyticsReport generateReport({
    required List<SchemeKnowledgeObject> schemes,
    int expectedSchemes = 0,
  }) {
    if (schemes.isEmpty) {
      return SchemeAnalyticsReport(
        totalSchemes: 0,
        ministryDistribution: const {},
        categoryDistribution: const {},
        sectorDistribution: const {},
        beneficiaryDistribution: const {},
        launchYearDistribution: const {},
        statusDistribution: const {},
        schemeTypeDistribution: const {},
        fundingPatternDistribution: const {},
        topLinkedArticles: const {},
        topLinkedActs: const {},
        topLinkedCommittees: const {},
        topLinkedReports: const {},
        topLinkedPyqs: const {},
        topLinkedCurrentAffairs: const {},
        topLinkedSdgs: const {},
        mostInterconnectedSchemes: const {},
        averageBenefitPerScheme: 0.0,
        averageComponentPerScheme: 0.0,
        averageSdgPerScheme: 0.0,
        averagePyqPerScheme: 0.0,
        averageCurrentAffairsPerScheme: 0.0,
        expectedSchemes: expectedSchemes,
        importedSchemes: 0,
        coveragePercentage: 0.0,
      );
    }

    final ministryDist = <SchemeMinistry, int>{};
    final categoryDist = <SchemeCategory, int>{};
    final sectorDist = <SchemeSector, int>{};
    final beneficiaryDist = <BeneficiaryGroup, int>{};
    final yearDist = <int, int>{};
    final statusDist = <SchemeStatus, int>{};
    final typeDist = <SchemeType, int>{};
    final fundingDist = <FundingPatternType, int>{};
    final articleMap = <String, int>{};
    final actMap = <String, int>{};
    final committeeMap = <String, int>{};
    final reportMap = <String, int>{};
    final pyqMap = <String, int>{};
    final caMap = <String, int>{};
    final sdgMap = <SdgGoal, int>{};
    final interconnected = <String, int>{};

    int totalBenefits = 0;
    int totalComponents = 0;
    int totalSdgs = 0;
    int totalPyqs = 0;
    int totalCa = 0;

    for (final s in schemes) {
      ministryDist[s.ministry] = (ministryDist[s.ministry] ?? 0) + 1;
      categoryDist[s.category] = (categoryDist[s.category] ?? 0) + 1;
      sectorDist[s.sector] = (sectorDist[s.sector] ?? 0) + 1;
      final launchYear = s.launchDate?.year ?? 0;
      yearDist[launchYear] = (yearDist[launchYear] ?? 0) + 1;
      statusDist[s.status] = (statusDist[s.status] ?? 0) + 1;
      typeDist[s.schemeType] = (typeDist[s.schemeType] ?? 0) + 1;
      fundingDist[s.funding.fundingPattern] =
          (fundingDist[s.funding.fundingPattern] ?? 0) + 1;

      for (final b in s.beneficiaries) {
        beneficiaryDist[b] = (beneficiaryDist[b] ?? 0) + 1;
      }

      for (final a in s.relatedArticleIds) {
        articleMap[a] = (articleMap[a] ?? 0) + 1;
      }
      for (final a in s.relatedActIds) {
        actMap[a] = (actMap[a] ?? 0) + 1;
      }
      for (final c in s.relatedCommitteeIds) {
        committeeMap[c] = (committeeMap[c] ?? 0) + 1;
      }
      for (final r in s.relatedReportIds) {
        reportMap[r] = (reportMap[r] ?? 0) + 1;
      }
      for (final p in s.relatedPyqIds) {
        pyqMap[p] = (pyqMap[p] ?? 0) + 1;
      }
      for (final c in s.relatedCurrentAffairsIds) {
        caMap[c] = (caMap[c] ?? 0) + 1;
      }
      for (final g in s.sdgGoals) {
        sdgMap[g] = (sdgMap[g] ?? 0) + 1;
      }

      final connectionScore =
          s.relationships.length + s.relatedSchemeIds.length;
      interconnected[s.officialName] = connectionScore;

      totalBenefits += s.benefits.length;
      totalComponents += s.components.length;
      totalSdgs += s.sdgGoals.length;
      totalPyqs += s.relatedPyqIds.length;
      totalCa += s.relatedCurrentAffairsIds.length;
    }

    final count = schemes.length;
    final sortedInterconnected = Map<String, int>.fromEntries(
      interconnected.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return SchemeAnalyticsReport(
      totalSchemes: count,
      ministryDistribution: Map.unmodifiable(ministryDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      sectorDistribution: Map.unmodifiable(sectorDist),
      beneficiaryDistribution: Map.unmodifiable(beneficiaryDist),
      launchYearDistribution: Map.unmodifiable(yearDist),
      statusDistribution: Map.unmodifiable(statusDist),
      schemeTypeDistribution: Map.unmodifiable(typeDist),
      fundingPatternDistribution: Map.unmodifiable(fundingDist),
      topLinkedArticles: Map.unmodifiable(articleMap),
      topLinkedActs: Map.unmodifiable(actMap),
      topLinkedCommittees: Map.unmodifiable(committeeMap),
      topLinkedReports: Map.unmodifiable(reportMap),
      topLinkedPyqs: Map.unmodifiable(pyqMap),
      topLinkedCurrentAffairs: Map.unmodifiable(caMap),
      topLinkedSdgs: Map.unmodifiable(sdgMap),
      mostInterconnectedSchemes: Map.unmodifiable(sortedInterconnected),
      averageBenefitPerScheme:
          double.parse((totalBenefits / count).toStringAsFixed(1)),
      averageComponentPerScheme:
          double.parse((totalComponents / count).toStringAsFixed(1)),
      averageSdgPerScheme:
          double.parse((totalSdgs / count).toStringAsFixed(1)),
      averagePyqPerScheme:
          double.parse((totalPyqs / count).toStringAsFixed(1)),
      averageCurrentAffairsPerScheme:
          double.parse((totalCa / count).toStringAsFixed(1)),
      expectedSchemes: expectedSchemes,
      importedSchemes: count,
      coveragePercentage: expectedSchemes > 0
          ? double.parse(((count / expectedSchemes) * 100).toStringAsFixed(1))
          : 0.0,
    );
  }
}
