library;

import '../domain/entities/doctrine_knowledge_object.dart';
import '../repositories/doctrine_repository.dart';

/// Statistical analysis and deliverable coverage report for Constitutional Doctrine Library.
class DoctrineAnalysisReport {
  final int totalDoctrines;
  final List<String> uniqueArticlesLinked;
  final int uniqueArticlesCount;
  final List<String> uniqueCasesLinked;
  final int uniqueCasesCount;
  final List<String> uniqueAmendmentsLinked;
  final int uniqueAmendmentsCount;
  final int totalPYQLinks;
  final int totalKnowledgeGraphLinks;
  final double evidenceCoverageRate;

  const DoctrineAnalysisReport({
    required this.totalDoctrines,
    required this.uniqueArticlesLinked,
    required this.uniqueArticlesCount,
    required this.uniqueCasesLinked,
    required this.uniqueCasesCount,
    required this.uniqueAmendmentsLinked,
    required this.uniqueAmendmentsCount,
    required this.totalPYQLinks,
    required this.totalKnowledgeGraphLinks,
    required this.evidenceCoverageRate,
  });

  Map<String, dynamic> toJson() => {
        'totalDoctrines': totalDoctrines,
        'uniqueArticlesLinked': uniqueArticlesLinked,
        'uniqueArticlesCount': uniqueArticlesCount,
        'uniqueCasesLinked': uniqueCasesLinked,
        'uniqueCasesCount': uniqueCasesCount,
        'uniqueAmendmentsLinked': uniqueAmendmentsLinked,
        'uniqueAmendmentsCount': uniqueAmendmentsCount,
        'totalPYQLinks': totalPYQLinks,
        'totalKnowledgeGraphLinks': totalKnowledgeGraphLinks,
        'evidenceCoverageRate': evidenceCoverageRate,
      };

  @override
  String toString() {
    return 'DoctrineAnalysisReport(Doctrines: $totalDoctrines, ArticlesLinked: $uniqueArticlesCount, CasesLinked: $uniqueCasesCount, AmendmentsLinked: $uniqueAmendmentsCount, PYQs: $totalPYQLinks, KGLinks: $totalKnowledgeGraphLinks, EvidenceCoverage: ${(evidenceCoverageRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Analyzer Engine for calculating metrics and deliverable statistics.
class DoctrineAnalyzer {
  static Future<DoctrineAnalysisReport> analyzeRepository(
      DoctrineRepository repository) async {
    final doctrines = await repository.getDoctrines();
    return analyzeDoctrines(doctrines);
  }

  static DoctrineAnalysisReport analyzeDoctrines(
      List<DoctrineKnowledgeObject> doctrines) {
    final totalDoctrines = doctrines.length;

    final uniqueArticles = <String>{};
    final uniqueCases = <String>{};
    final uniqueAmendments = <String>{};
    int totalPYQLinks = 0;
    int totalKGLinks = 0;
    int doctrinesWithEvidence = 0;

    for (final d in doctrines) {
      for (final art in d.relatedArticles) {
        if (art.isNotEmpty) uniqueArticles.add(art);
      }

      if (d.originatingCase.isNotEmpty) {
        uniqueCases.add(d.originatingCase);
      }
      for (final c in d.landmarkCases) {
        if (c.isNotEmpty) uniqueCases.add(c);
      }
      for (final c in d.subsequentCases) {
        if (c.isNotEmpty) uniqueCases.add(c);
      }

      for (final amd in d.relatedAmendments) {
        if (amd.isNotEmpty) uniqueAmendments.add(amd);
      }

      totalPYQLinks += d.pyqIds.length;

      totalKGLinks += d.relatedArticles.length +
          d.relatedParts.length +
          d.relatedSchedules.length +
          d.relatedAmendments.length +
          d.relatedActs.length +
          d.landmarkCases.length +
          d.crossReferences.length;

      if (d.citations.isNotEmpty || d.evidenceReferences.isNotEmpty || d.primarySource.isNotEmpty) {
        doctrinesWithEvidence++;
      }
    }

    final evidenceCoverage = totalDoctrines == 0 ? 0.0 : doctrinesWithEvidence / totalDoctrines;

    return DoctrineAnalysisReport(
      totalDoctrines: totalDoctrines,
      uniqueArticlesLinked: uniqueArticles.toList()..sort(),
      uniqueArticlesCount: uniqueArticles.length,
      uniqueCasesLinked: uniqueCases.toList()..sort(),
      uniqueCasesCount: uniqueCases.length,
      uniqueAmendmentsLinked: uniqueAmendments.toList()..sort(),
      uniqueAmendmentsCount: uniqueAmendments.length,
      totalPYQLinks: totalPYQLinks,
      totalKnowledgeGraphLinks: totalKGLinks,
      evidenceCoverageRate: evidenceCoverage,
    );
  }
}
