library;

import '../domain/entities/case_knowledge_object.dart';
import '../repositories/case_repository.dart';

/// Statistical analysis and deliverable coverage report for Constitutional Case Library.
class CaseAnalysisReport {
  final int totalCases;
  final int landmarkPrecedentsCount;
  final int overruledCasesCount;
  final List<String> uniqueArticlesLinked;
  final int uniqueArticlesCount;
  final List<String> uniqueAmendmentsLinked;
  final int uniqueAmendmentsCount;
  final List<String> uniqueJudgesLinked;
  final int uniqueJudgesCount;
  final int totalPYQLinks;
  final int totalKnowledgeGraphLinks;
  final double evidenceCoverageRate;

  const CaseAnalysisReport({
    required this.totalCases,
    required this.landmarkPrecedentsCount,
    required this.overruledCasesCount,
    required this.uniqueArticlesLinked,
    required this.uniqueArticlesCount,
    required this.uniqueAmendmentsLinked,
    required this.uniqueAmendmentsCount,
    required this.uniqueJudgesLinked,
    required this.uniqueJudgesCount,
    required this.totalPYQLinks,
    required this.totalKnowledgeGraphLinks,
    required this.evidenceCoverageRate,
  });

  Map<String, dynamic> toJson() => {
        'totalCases': totalCases,
        'landmarkPrecedentsCount': landmarkPrecedentsCount,
        'overruledCasesCount': overruledCasesCount,
        'uniqueArticlesLinked': uniqueArticlesLinked,
        'uniqueArticlesCount': uniqueArticlesCount,
        'uniqueAmendmentsLinked': uniqueAmendmentsLinked,
        'uniqueAmendmentsCount': uniqueAmendmentsCount,
        'uniqueJudgesLinked': uniqueJudgesLinked,
        'uniqueJudgesCount': uniqueJudgesCount,
        'totalPYQLinks': totalPYQLinks,
        'totalKnowledgeGraphLinks': totalKnowledgeGraphLinks,
        'evidenceCoverageRate': evidenceCoverageRate,
      };

  @override
  String toString() {
    return 'CaseAnalysisReport(Cases: $totalCases [$landmarkPrecedentsCount Precedents, $overruledCasesCount Overruled], ArticlesLinked: $uniqueArticlesCount, AmendmentsLinked: $uniqueAmendmentsCount, Judges: $uniqueJudgesCount, PYQs: $totalPYQLinks, KGLinks: $totalKnowledgeGraphLinks, EvidenceCoverage: ${(evidenceCoverageRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Analyzer Engine for calculating metrics and deliverable statistics.
class CaseAnalyzer {
  static Future<CaseAnalysisReport> analyzeRepository(
      CaseRepository repository) async {
    final cases = await repository.getCases();
    return analyzeCases(cases);
  }

  static CaseAnalysisReport analyzeCases(List<CaseKnowledgeObject> cases) {
    final totalCases = cases.length;
    int landmarkCount = 0;
    int overruledCount = 0;

    final uniqueArticles = <String>{};
    final uniqueAmendments = <String>{};
    final uniqueJudges = <String>{};
    int totalPYQLinks = 0;
    int totalKGLinks = 0;
    int casesWithEvidence = 0;

    for (final c in cases) {
      if (c.status.name == 'landmarkPrecedent') {
        landmarkCount++;
      } else {
        overruledCount++;
      }

      for (final art in c.relatedArticles) {
        if (art.isNotEmpty) uniqueArticles.add(art);
      }

      for (final amd in c.relatedAmendments) {
        if (amd.isNotEmpty) uniqueAmendments.add(amd);
      }

      for (final j in c.judges) {
        if (j.isNotEmpty) uniqueJudges.add(j);
      }

      totalPYQLinks += c.pyqIds.length;

      totalKGLinks += c.relatedArticles.length +
          c.relatedParts.length +
          c.relatedSchedules.length +
          c.relatedAmendments.length +
          c.relatedActs.length +
          c.crossReferences.length;

      if (c.citations.isNotEmpty || c.evidenceReferences.isNotEmpty || c.primarySource.isNotEmpty) {
        casesWithEvidence++;
      }
    }

    final evidenceCoverage = totalCases == 0 ? 0.0 : casesWithEvidence / totalCases;

    return CaseAnalysisReport(
      totalCases: totalCases,
      landmarkPrecedentsCount: landmarkCount,
      overruledCasesCount: overruledCount,
      uniqueArticlesLinked: uniqueArticles.toList()..sort(),
      uniqueArticlesCount: uniqueArticles.length,
      uniqueAmendmentsLinked: uniqueAmendments.toList()..sort(),
      uniqueAmendmentsCount: uniqueAmendments.length,
      uniqueJudgesLinked: uniqueJudges.toList()..sort(),
      uniqueJudgesCount: uniqueJudges.length,
      totalPYQLinks: totalPYQLinks,
      totalKnowledgeGraphLinks: totalKGLinks,
      evidenceCoverageRate: evidenceCoverage,
    );
  }
}
