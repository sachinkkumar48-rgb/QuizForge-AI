library;

import 'package:garuda_editor/garuda_editor.dart';

import '../data/international_seed_corpus.dart';
import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';
import '../search/international_search_engine.dart';
import 'international_repository.dart';

/// In-memory implementation of InternationalRepository pre-seeded with the
/// Phase-I corpus. Offline-first and JSON-compatible.
class InMemoryInternationalRepository implements InternationalRepository {
  final Map<String, InternationalKnowledgeObject> _organisations = {};

  InMemoryInternationalRepository({bool seedDefaultCorpus = true}) {
    if (seedDefaultCorpus) {
      for (final org in InternationalSeedCorpus.phase1Organisations) {
        _organisations[org.id] = org;
      }
    }
  }

  @override
  Future<void> saveOrganisation(InternationalKnowledgeObject object) async {
    _organisations[object.id] = object;
  }

  @override
  Future<InternationalKnowledgeObject?> getOrganisationById(String id) async =>
      _organisations[id];

  @override
  Future<List<InternationalKnowledgeObject>> getAllOrganisations() async =>
      List.unmodifiable(_organisations.values.toList());

  @override
  Future<InternationalKnowledgeObject?> getOrganisationByExactName(
      String name) async {
    final matches = InternationalSearchEngine.findByExactName(
        organisations: _organisations.values.toList(), name: name);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<InternationalKnowledgeObject?> getOrganisationByAcronym(
      String acronym) async {
    final lower = acronym.toLowerCase().trim();
    for (final o in _organisations.values) {
      if (o.acronym.toLowerCase().trim() == lower) return o;
    }
    return null;
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByBodyType(
      InternationalBodyType type) async {
    return _organisations.values.where((o) => o.bodyType == type).toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByCategory(
      InternationalCategory category) async {
    return _organisations.values.where((o) => o.category == category).toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByRegion(
      GeographicalRegion region) async {
    return _organisations.values
        .where((o) => o.geographicalRegion == region)
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByHeadquartersRegion(
      HeadquartersRegion region) async {
    return _organisations.values
        .where((o) => o.headquartersRegion == region)
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByFoundingYear(int year) async {
    return _organisations.values
        .where((o) => o.establishedYear == year)
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByMembershipType(
      MembershipType type) async {
    return _organisations.values.where((o) => o.membershipType == type).toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByIndiaRelationship(
      IndiaRelationshipStatus status) async {
    return _organisations.values
        .where((o) => o.indiaMembership == status)
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByIssueArea(
      GlobalIssueArea issueArea) async {
    return _organisations.values
        .where((o) => o.issueAreas.contains(issueArea))
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByUpscRelevance(
      UpscRelevanceLevel relevance) async {
    return _organisations.values
        .where((o) => o.upscRelevance == relevance)
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByTreaty(String treaty) async {
    final lower = treaty.toLowerCase().trim();
    return _organisations.values
        .where((o) =>
            o.foundingTreaty.toLowerCase().contains(lower) ||
            o.importantConventions.any((c) => c.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getByKeyword(String keyword) async {
    final lower = keyword.toLowerCase().trim();
    return _organisations.values
        .where((o) =>
            o.officialName.toLowerCase().contains(lower) ||
            o.acronym.toLowerCase().contains(lower) ||
            o.mandate.toLowerCase().contains(lower) ||
            o.keywords.any((k) => k.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<InternationalKnowledgeObject>> getRelatedOrganisations(
      InternationalKnowledgeObject organisation) async {
    return InternationalSearchEngine.relatedOrganisations(
      organisations: _organisations.values.toList(),
      organisation: organisation,
    );
  }

  @override
  Future<List<InternationalKnowledgeObject>> searchOrganisations(
      InternationalSearchQuery query) async {
    return InternationalSearchEngine.searchRanked(
      organisations: _organisations.values.toList(),
      query: query,
    );
  }

  @override
  Future<InternationalCorpusReport> generateCorpusReport() async {
    final orgs = _organisations.values.toList();
    final bodyTypeDist = <InternationalBodyType, int>{};
    final categoryDist = <InternationalCategory, int>{};
    final regionDist = <GeographicalRegion, int>{};
    final hqRegionDist = <HeadquartersRegion, int>{};
    final membershipDist = <MembershipType, int>{};
    final indiaDist = <IndiaRelationshipStatus, int>{};
    final relevanceDist = <UpscRelevanceLevel, int>{};

    int treatyLinks = 0;
    int conventionLinks = 0;
    int orgLinks = 0;
    int relationships = 0;
    int articleLinks = 0;
    int actLinks = 0;
    int schemeLinks = 0;
    int caLinks = 0;
    int pyqLinks = 0;
    int sdgLinks = 0;
    int evidenceRefs = 0;
    int indiaRelevant = 0;
    int published = 0;

    for (final o in orgs) {
      bodyTypeDist[o.bodyType] = (bodyTypeDist[o.bodyType] ?? 0) + 1;
      categoryDist[o.category] = (categoryDist[o.category] ?? 0) + 1;
      regionDist[o.geographicalRegion] = (regionDist[o.geographicalRegion] ?? 0) + 1;
      hqRegionDist[o.headquartersRegion] =
          (hqRegionDist[o.headquartersRegion] ?? 0) + 1;
      membershipDist[o.membershipType] = (membershipDist[o.membershipType] ?? 0) + 1;
      indiaDist[o.indiaMembership] = (indiaDist[o.indiaMembership] ?? 0) + 1;
      relevanceDist[o.upscRelevance] = (relevanceDist[o.upscRelevance] ?? 0) + 1;

      treatyLinks += o.foundingTreaty.isNotEmpty ? 1 : 0;
      conventionLinks += o.importantConventions.length;
      orgLinks += o.relatedOrganisationIds.length;
      relationships += o.relationships.length;
      articleLinks += o.relatedArticleIds.length;
      actLinks += o.relatedActIds.length;
      schemeLinks += o.relatedSchemeIds.length;
      caLinks += o.relatedCurrentAffairsIds.length;
      pyqLinks += o.relatedPyqIds.length;
      sdgLinks += o.sdgGoals.length;
      evidenceRefs += o.evidenceIds.length;
      if (o.indiaMembership == IndiaRelationshipStatus.foundingMember ||
          o.indiaMembership == IndiaRelationshipStatus.fullMember ||
          o.indiaMembership == IndiaRelationshipStatus.observer) {
        indiaRelevant++;
      }
      if (o.editorialStatus == EditorialStatus.published) published++;
    }

    double coverage(int imported, int expected) => expected > 0
        ? double.parse(((imported / expected) * 100).toStringAsFixed(1))
        : 100.0;

    return InternationalCorpusReport(
      totalExpectedOrganisations: InternationalSeedCorpus.expectedInternationalCorpus,
      totalImportedOrganisations: orgs.length,
      organisationCoveragePercentage: coverage(
          orgs.length, InternationalSeedCorpus.expectedInternationalCorpus),
      bodyTypeCount: bodyTypeDist.length,
      categoryCount: categoryDist.length,
      bodyTypeDistribution: Map.unmodifiable(bodyTypeDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      regionDistribution: Map.unmodifiable(regionDist),
      headquartersRegionDistribution: Map.unmodifiable(hqRegionDist),
      membershipTypeDistribution: Map.unmodifiable(membershipDist),
      indiaRelationshipDistribution: Map.unmodifiable(indiaDist),
      upscRelevanceDistribution: Map.unmodifiable(relevanceDist),
      totalTreatyLinks: treatyLinks,
      totalConventionLinks: conventionLinks,
      totalOrganisationLinks: orgLinks,
      totalRelationships: relationships,
      totalArticleLinks: articleLinks,
      totalActLinks: actLinks,
      totalSchemeLinks: schemeLinks,
      totalCurrentAffairsLinks: caLinks,
      totalPyqLinks: pyqLinks,
      totalSdgLinks: sdgLinks,
      totalEvidenceReferences: evidenceRefs,
      totalIndiaRelevantOrganisations: indiaRelevant,
      totalPublishedOrganisations: published,
    );
  }

  void clear() => _organisations.clear();
}
