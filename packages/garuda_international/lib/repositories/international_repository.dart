library;

import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';
import '../search/international_search_engine.dart';

/// Corpus-coverage metrics for the International Organisations Library.
class InternationalCorpusReport {
  final int totalExpectedOrganisations;
  final int totalImportedOrganisations;
  final double organisationCoveragePercentage;
  final int bodyTypeCount;
  final int categoryCount;
  final Map<InternationalBodyType, int> bodyTypeDistribution;
  final Map<InternationalCategory, int> categoryDistribution;
  final Map<GeographicalRegion, int> regionDistribution;
  final Map<HeadquartersRegion, int> headquartersRegionDistribution;
  final Map<MembershipType, int> membershipTypeDistribution;
  final Map<IndiaRelationshipStatus, int> indiaRelationshipDistribution;
  final Map<UpscRelevanceLevel, int> upscRelevanceDistribution;
  final int totalTreatyLinks;
  final int totalConventionLinks;
  final int totalOrganisationLinks;
  final int totalRelationships;
  final int totalArticleLinks;
  final int totalActLinks;
  final int totalSchemeLinks;
  final int totalCurrentAffairsLinks;
  final int totalPyqLinks;
  final int totalSdgLinks;
  final int totalEvidenceReferences;
  final int totalIndiaRelevantOrganisations;
  final int totalPublishedOrganisations;

  const InternationalCorpusReport({
    required this.totalExpectedOrganisations,
    required this.totalImportedOrganisations,
    required this.organisationCoveragePercentage,
    required this.bodyTypeCount,
    required this.categoryCount,
    required this.bodyTypeDistribution,
    required this.categoryDistribution,
    required this.regionDistribution,
    required this.headquartersRegionDistribution,
    required this.membershipTypeDistribution,
    required this.indiaRelationshipDistribution,
    required this.upscRelevanceDistribution,
    required this.totalTreatyLinks,
    required this.totalConventionLinks,
    required this.totalOrganisationLinks,
    required this.totalRelationships,
    required this.totalArticleLinks,
    required this.totalActLinks,
    required this.totalSchemeLinks,
    required this.totalCurrentAffairsLinks,
    required this.totalPyqLinks,
    required this.totalSdgLinks,
    required this.totalEvidenceReferences,
    required this.totalIndiaRelevantOrganisations,
    required this.totalPublishedOrganisations,
  });
}

/// Abstract repository interface for International Knowledge Objects.
abstract class InternationalRepository {
  Future<void> saveOrganisation(InternationalKnowledgeObject object);
  Future<InternationalKnowledgeObject?> getOrganisationById(String id);
  Future<List<InternationalKnowledgeObject>> getAllOrganisations();
  Future<InternationalKnowledgeObject?> getOrganisationByExactName(String name);
  Future<InternationalKnowledgeObject?> getOrganisationByAcronym(String acronym);

  Future<List<InternationalKnowledgeObject>> getByBodyType(InternationalBodyType type);
  Future<List<InternationalKnowledgeObject>> getByCategory(InternationalCategory category);
  Future<List<InternationalKnowledgeObject>> getByRegion(GeographicalRegion region);
  Future<List<InternationalKnowledgeObject>> getByHeadquartersRegion(HeadquartersRegion region);
  Future<List<InternationalKnowledgeObject>> getByFoundingYear(int year);
  Future<List<InternationalKnowledgeObject>> getByMembershipType(MembershipType type);
  Future<List<InternationalKnowledgeObject>> getByIndiaRelationship(IndiaRelationshipStatus status);
  Future<List<InternationalKnowledgeObject>> getByIssueArea(GlobalIssueArea issueArea);
  Future<List<InternationalKnowledgeObject>> getByUpscRelevance(UpscRelevanceLevel relevance);
  Future<List<InternationalKnowledgeObject>> getByTreaty(String treaty);
  Future<List<InternationalKnowledgeObject>> getByKeyword(String keyword);
  Future<List<InternationalKnowledgeObject>> getRelatedOrganisations(InternationalKnowledgeObject organisation);

  Future<List<InternationalKnowledgeObject>> searchOrganisations(InternationalSearchQuery query);
  Future<InternationalCorpusReport> generateCorpusReport();
}
