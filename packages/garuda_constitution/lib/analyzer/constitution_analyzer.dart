library;

import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_enums.dart';
import '../repositories/constitution_repository.dart';

/// Comprehensive statistical analysis and deliverable coverage report model.
class ConstitutionAnalysisReport {
  final int totalArticles;
  final int activeArticlesCount;
  final int repealedArticlesCount;
  final List<String> activeArticles;
  final List<String> repealedArticles;
  final int totalAmendmentRecords;
  final int uniqueAmendmentsCount;
  final List<String> uniqueAmendments;
  final int totalCaseLawRecords;
  final int uniqueCasesCount;
  final List<String> uniqueCases;
  final int totalPYQLinks;
  final int uniquePYQCount;
  final int totalCrossLinks;
  final double evidenceCoverageRate;
  final double bareTextCoverageRate;

  const ConstitutionAnalysisReport({
    required this.totalArticles,
    required this.activeArticlesCount,
    required this.repealedArticlesCount,
    required this.activeArticles,
    required this.repealedArticles,
    required this.totalAmendmentRecords,
    required this.uniqueAmendmentsCount,
    required this.uniqueAmendments,
    required this.totalCaseLawRecords,
    required this.uniqueCasesCount,
    required this.uniqueCases,
    required this.totalPYQLinks,
    required this.uniquePYQCount,
    required this.totalCrossLinks,
    required this.evidenceCoverageRate,
    required this.bareTextCoverageRate,
  });

  Map<String, dynamic> toJson() => {
        'totalArticles': totalArticles,
        'activeArticlesCount': activeArticlesCount,
        'repealedArticlesCount': repealedArticlesCount,
        'activeArticles': activeArticles,
        'repealedArticles': repealedArticles,
        'totalAmendmentRecords': totalAmendmentRecords,
        'uniqueAmendmentsCount': uniqueAmendmentsCount,
        'uniqueAmendments': uniqueAmendments,
        'totalCaseLawRecords': totalCaseLawRecords,
        'uniqueCasesCount': uniqueCasesCount,
        'uniqueCases': uniqueCases,
        'totalPYQLinks': totalPYQLinks,
        'uniquePYQCount': uniquePYQCount,
        'totalCrossLinks': totalCrossLinks,
        'evidenceCoverageRate': evidenceCoverageRate,
        'bareTextCoverageRate': bareTextCoverageRate,
      };

  @override
  String toString() {
    return 'ConstitutionAnalysisReport(Articles: $totalArticles [$activeArticlesCount Active, $repealedArticlesCount Repealed], Amendments: $totalAmendmentRecords, Cases: $totalCaseLawRecords, PYQs: $totalPYQLinks, CrossLinks: $totalCrossLinks, EvidenceCoverage: ${(evidenceCoverageRate * 100).toStringAsFixed(1)}%, BareTextCoverage: ${(bareTextCoverageRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Analyzer Engine for calculating coverage, metrics, and deliverable statistics.
class ConstitutionAnalyzer {
  static Future<ConstitutionAnalysisReport> analyzeRepository(
      ConstitutionRepository repository) async {
    final articles = await repository.getArticles();
    return analyzeArticles(articles);
  }

  static ConstitutionAnalysisReport analyzeArticles(
      List<ArticleKnowledgeObject> articles) {
    final totalArticles = articles.length;

    final activeList = <String>[];
    final repealedList = <String>[];
    int totalAmendmentRecords = 0;
    final uniqueAmendments = <String>{};
    int totalCaseLawRecords = 0;
    final uniqueCases = <String>{};
    int totalPYQLinks = 0;
    final uniquePYQs = <String>{};
    int totalCrossLinks = 0;
    int articlesWithEvidence = 0;
    int articlesWithBareText = 0;

    for (final art in articles) {
      if (art.status == ConstitutionStatus.active) {
        activeList.add(art.articleNumber);
      } else if (art.status == ConstitutionStatus.repealed) {
        repealedList.add(art.articleNumber);
      }

      totalAmendmentRecords += art.amendmentHistory.length;
      for (final amd in art.amendmentHistory) {
        if (amd.amendmentName.isNotEmpty) {
          uniqueAmendments.add(amd.amendmentName);
        }
      }
      for (final amdName in art.relatedAmendments) {
        if (amdName.isNotEmpty) {
          uniqueAmendments.add(amdName);
        }
      }

      totalCaseLawRecords += art.caseLaw.length;
      for (final c in art.caseLaw) {
        if (c.caseName.isNotEmpty) {
          uniqueCases.add(c.caseName);
        }
      }
      for (final cName in art.relatedCases) {
        if (cName.isNotEmpty) {
          uniqueCases.add(cName);
        }
      }

      totalPYQLinks += art.pyqIds.length;
      for (final p in art.pyqIds) {
        uniquePYQs.add(p);
      }

      // Count all cross links
      totalCrossLinks += art.relatedArticles.length +
          art.relatedParts.length +
          art.relatedSchedules.length +
          art.relatedAmendments.length +
          art.relatedActs.length +
          art.relatedRules.length +
          art.relatedReports.length +
          art.relatedCommittees.length;

      if (art.citations.isNotEmpty || art.evidenceReferences.isNotEmpty) {
        articlesWithEvidence++;
      }

      if (art.officialConstitutionalText.trim().isNotEmpty) {
        articlesWithBareText++;
      }
    }

    final evidenceCoverage = totalArticles == 0 ? 0.0 : articlesWithEvidence / totalArticles;
    final bareTextCoverage = totalArticles == 0 ? 0.0 : articlesWithBareText / totalArticles;

    return ConstitutionAnalysisReport(
      totalArticles: totalArticles,
      activeArticlesCount: activeList.length,
      repealedArticlesCount: repealedList.length,
      activeArticles: activeList,
      repealedArticles: repealedList,
      totalAmendmentRecords: totalAmendmentRecords,
      uniqueAmendmentsCount: uniqueAmendments.length,
      uniqueAmendments: uniqueAmendments.toList(),
      totalCaseLawRecords: totalCaseLawRecords,
      uniqueCasesCount: uniqueCases.length,
      uniqueCases: uniqueCases.toList(),
      totalPYQLinks: totalPYQLinks,
      uniquePYQCount: uniquePYQs.length,
      totalCrossLinks: totalCrossLinks,
      evidenceCoverageRate: evidenceCoverage,
      bareTextCoverageRate: bareTextCoverage,
    );
  }
}
