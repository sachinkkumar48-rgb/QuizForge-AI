library;

import '../domain/entities/body_enums.dart';
import '../domain/entities/body_knowledge_object.dart';
import '../search/body_search_engine.dart';

/// Corpus-coverage metrics for the Government Bodies Library.
class BodyCorpusReport {
  final int totalExpectedBodies;
  final int totalImportedBodies;
  final double bodyCoveragePercentage;
  final int bodyTypeCount;
  final int categoryCount;
  final Map<BodyType, int> bodyTypeDistribution;
  final Map<BodyCategory, int> categoryDistribution;
  final Map<BodyStatus, int> statusDistribution;
  final Map<ConstitutionalBasis, int> constitutionalBasisDistribution;
  final Map<StatutoryBasis, int> statutoryBasisDistribution;
  final Map<BodyJurisdiction, int> jurisdictionDistribution;
  final Map<UpscRelevanceLevel, int> upscRelevanceDistribution;
  final int totalArticleLinks;
  final int totalActLinks;
  final int totalCaseLawLinks;
  final int totalDoctrineLinks;
  final int totalCommitteeLinks;
  final int totalReportLinks;
  final int totalSchemeLinks;
  final int totalPyqLinks;
  final int totalCurrentAffairsLinks;
  final int totalBodyLinks;
  final int totalRelationships;
  final int totalEvidenceReferences;
  final int totalPublishedBodies;

  const BodyCorpusReport({
    required this.totalExpectedBodies,
    required this.totalImportedBodies,
    required this.bodyCoveragePercentage,
    required this.bodyTypeCount,
    required this.categoryCount,
    required this.bodyTypeDistribution,
    required this.categoryDistribution,
    required this.statusDistribution,
    required this.constitutionalBasisDistribution,
    required this.statutoryBasisDistribution,
    required this.jurisdictionDistribution,
    required this.upscRelevanceDistribution,
    required this.totalArticleLinks,
    required this.totalActLinks,
    required this.totalCaseLawLinks,
    required this.totalDoctrineLinks,
    required this.totalCommitteeLinks,
    required this.totalReportLinks,
    required this.totalSchemeLinks,
    required this.totalPyqLinks,
    required this.totalCurrentAffairsLinks,
    required this.totalBodyLinks,
    required this.totalRelationships,
    required this.totalEvidenceReferences,
    required this.totalPublishedBodies,
  });
}

/// Abstract repository interface for Body Knowledge Objects.
abstract class BodyRepository {
  Future<void> saveBody(BodyKnowledgeObject object);
  Future<BodyKnowledgeObject?> getBodyById(String id);
  Future<List<BodyKnowledgeObject>> getAllBodies();
  Future<BodyKnowledgeObject?> getBodyByExactName(String name);
  Future<BodyKnowledgeObject?> getBodyByAcronym(String acronym);

  Future<List<BodyKnowledgeObject>> getBodiesByType(BodyType type);
  Future<List<BodyKnowledgeObject>> getBodiesByCategory(BodyCategory category);
  Future<List<BodyKnowledgeObject>> getBodiesByArticle(String article);
  Future<List<BodyKnowledgeObject>> getBodiesByAct(String act);
  Future<List<BodyKnowledgeObject>> getBodiesByMinistry(String ministry);
  Future<List<BodyKnowledgeObject>> getBodiesByJurisdiction(BodyJurisdiction jurisdiction);
  Future<List<BodyKnowledgeObject>> getBodiesByAppointmentAuthority(AppointmentAuthority authority);
  Future<List<BodyKnowledgeObject>> getBodiesByYearEstablished(int year);
  Future<List<BodyKnowledgeObject>> getBodiesByStatus(BodyStatus status);
  Future<List<BodyKnowledgeObject>> getBodiesByUpscRelevance(UpscRelevanceLevel relevance);
  Future<List<BodyKnowledgeObject>> getBodiesByKeyword(String keyword);
  Future<List<BodyKnowledgeObject>> getRelatedBodies(BodyKnowledgeObject body);

  Future<List<BodyKnowledgeObject>> searchBodies(BodySearchQuery query);
  Future<BodyCorpusReport> generateCorpusReport();
}
