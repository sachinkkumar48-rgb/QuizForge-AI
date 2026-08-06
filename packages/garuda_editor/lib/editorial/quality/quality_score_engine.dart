library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';

class QualityScoreBreakdown {
  final double evidenceCompleteness; // 0-15
  final double officialSourceQuality; // 0-15
  final double metadataCompleteness; // 0-10
  final double knowledgeLinks; // 0-15
  final double editorialReview; // 0-15
  final double factVerification; // 0-10
  final double relationshipIntegrity; // 0-10
  final double searchCoverage; // 0-5
  final double publicationReadiness; // 0-5

  const QualityScoreBreakdown({
    required this.evidenceCompleteness,
    required this.officialSourceQuality,
    required this.metadataCompleteness,
    required this.knowledgeLinks,
    required this.editorialReview,
    required this.factVerification,
    required this.relationshipIntegrity,
    required this.searchCoverage,
    required this.publicationReadiness,
  });

  double get totalScore => (evidenceCompleteness +
          officialSourceQuality +
          metadataCompleteness +
          knowledgeLinks +
          editorialReview +
          factVerification +
          relationshipIntegrity +
          searchCoverage +
          publicationReadiness)
      .clamp(0.0, 100.0);

  Map<String, double> toJson() => {
        'evidenceCompleteness': evidenceCompleteness,
        'officialSourceQuality': officialSourceQuality,
        'metadataCompleteness': metadataCompleteness,
        'knowledgeLinks': knowledgeLinks,
        'editorialReview': editorialReview,
        'factVerification': factVerification,
        'relationshipIntegrity': relationshipIntegrity,
        'searchCoverage': searchCoverage,
        'publicationReadiness': publicationReadiness,
        'totalScore': totalScore,
      };
}

class QualityScoreEngine {
  static QualityScoreBreakdown calculateScore(KnowledgeObject object) {
    // 1. Evidence Completeness (0-15)
    double evidence = 0.0;
    if (object.evidenceIds.isNotEmpty) {
      evidence = (object.evidenceIds.length * 5.0).clamp(5.0, 15.0);
    }

    // 2. Official Source Quality (0-15)
    double officialSource = 0.0;
    final source = object.officialSource.toLowerCase();
    if (source.contains('upsc') ||
        source.contains('pib') ||
        source.contains('gazette') ||
        source.contains('supremecourt') ||
        source.contains('supreme court') ||
        source.contains('constitution') ||
        source.contains('parliament') ||
        source.contains('ministry') ||
        source.contains('government')) {
      officialSource = 15.0;
    } else if (source.isNotEmpty) {
      officialSource = 10.0;
    }

    // 3. Metadata Completeness (0-10)
    double metadata = 0.0;
    if (object.title.isNotEmpty) metadata += 2.5;
    if (object.content.isNotEmpty) metadata += 2.5;
    if (object.subject.isNotEmpty) metadata += 2.5;
    if (object.topic.isNotEmpty) metadata += 2.5;

    // 4. Knowledge Links (0-15)
    double links = 0.0;
    if (object.relatedArticles.isNotEmpty || object.relatedCaseLaws.isNotEmpty) {
      final totalLinks = object.relatedArticles.length + object.relatedCaseLaws.length;
      links = (totalLinks * 5.0).clamp(5.0, 15.0);
    }

    // 5. Editorial Review (0-15)
    double review = 0.0;
    if (object.status.displayName == 'Approved' || object.status.displayName == 'Published') {
      review = 15.0;
    } else if (object.status.displayName.contains('Review') || object.status.displayName.contains('Verified')) {
      review = 10.0;
    } else {
      review = 5.0;
    }

    // 6. Fact Verification (0-10)
    double factVerif = 0.0;
    if (object.isVerified) {
      factVerif = 10.0;
    } else if (object.evidenceIds.isNotEmpty) {
      factVerif = 5.0;
    }

    // 7. Relationship Integrity (0-10)
    double relIntegrity = 10.0; // Assume valid unless flagged

    // 8. Search Coverage (0-5)
    double searchCov = (object.tags.length * 2.5).clamp(0.0, 5.0);

    // 9. Overall Publication Readiness (0-5)
    double pubReadiness = 0.0;
    if (evidence > 0 && officialSource > 0 && metadata >= 7.5 && factVerif >= 5.0) {
      pubReadiness = 5.0;
    }

    return QualityScoreBreakdown(
      evidenceCompleteness: evidence,
      officialSourceQuality: officialSource,
      metadataCompleteness: metadata,
      knowledgeLinks: links,
      editorialReview: review,
      factVerification: factVerif,
      relationshipIntegrity: relIntegrity,
      searchCoverage: searchCov,
      publicationReadiness: pubReadiness,
    );
  }
}
