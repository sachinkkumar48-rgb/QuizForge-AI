library;

import 'package:garuda_editor/garuda_editor.dart';

import '../data/body_seed_corpus.dart';
import '../domain/entities/body_enums.dart';
import '../domain/entities/body_knowledge_object.dart';
import '../search/body_search_engine.dart';
import 'body_repository.dart';

/// In-memory implementation of BodyRepository pre-seeded with the Phase-I
/// corpus. Offline-first and JSON-compatible.
class InMemoryBodyRepository implements BodyRepository {
  final Map<String, BodyKnowledgeObject> _bodies = {};

  InMemoryBodyRepository({bool seedDefaultCorpus = true}) {
    if (seedDefaultCorpus) {
      for (final body in BodySeedCorpus.phase1Bodies) {
        _bodies[body.id] = body;
      }
    }
  }

  @override
  Future<void> saveBody(BodyKnowledgeObject object) async {
    _bodies[object.id] = object;
  }

  @override
  Future<BodyKnowledgeObject?> getBodyById(String id) async => _bodies[id];

  @override
  Future<List<BodyKnowledgeObject>> getAllBodies() async =>
      List.unmodifiable(_bodies.values.toList());

  @override
  Future<BodyKnowledgeObject?> getBodyByExactName(String name) async {
    final matches = BodySearchEngine.findByExactName(
        bodies: _bodies.values.toList(), name: name);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<BodyKnowledgeObject?> getBodyByAcronym(String acronym) async {
    final lower = acronym.toLowerCase().trim();
    for (final b in _bodies.values) {
      if (b.shortName.toLowerCase().trim() == lower) return b;
    }
    return null;
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByType(BodyType type) async {
    return _bodies.values.where((b) => b.bodyType == type).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByCategory(
      BodyCategory category) async {
    return _bodies.values.where((b) => b.category == category).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByArticle(String article) async {
    final lower = article.toLowerCase().trim();
    return _bodies.values
        .where((b) =>
            b.establishingArticleIds.any((a) => a.toLowerCase().contains(lower)) ||
            b.relatedArticleIds.any((a) => a.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByAct(String act) async {
    final lower = act.toLowerCase().trim();
    return _bodies.values
        .where((b) =>
            b.establishingActIds.any((a) => a.toLowerCase().contains(lower)) ||
            b.relatedActIds.any((a) => a.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByMinistry(String ministry) async {
    final lower = ministry.toLowerCase().trim();
    return _bodies.values
        .where((b) => b.parentMinistry.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByJurisdiction(
      BodyJurisdiction jurisdiction) async {
    return _bodies.values.where((b) => b.jurisdiction == jurisdiction).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByAppointmentAuthority(
      AppointmentAuthority authority) async {
    return _bodies.values
        .where((b) => b.appointmentAuthority == authority)
        .toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByYearEstablished(int year) async {
    return _bodies.values.where((b) => b.yearEstablished == year).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByStatus(BodyStatus status) async {
    return _bodies.values.where((b) => b.bodyStatus == status).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByUpscRelevance(
      UpscRelevanceLevel relevance) async {
    return _bodies.values.where((b) => b.upscRelevance == relevance).toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getBodiesByKeyword(String keyword) async {
    final lower = keyword.toLowerCase().trim();
    return _bodies.values
        .where((b) =>
            b.officialName.toLowerCase().contains(lower) ||
            b.shortName.toLowerCase().contains(lower) ||
            b.mandate.toLowerCase().contains(lower) ||
            b.keywords.any((k) => k.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<BodyKnowledgeObject>> getRelatedBodies(
      BodyKnowledgeObject body) async {
    return BodySearchEngine.relatedBodies(
      bodies: _bodies.values.toList(),
      body: body,
    );
  }

  @override
  Future<List<BodyKnowledgeObject>> searchBodies(
      BodySearchQuery query) async {
    return BodySearchEngine.searchRanked(
      bodies: _bodies.values.toList(),
      query: query,
    );
  }

  @override
  Future<BodyCorpusReport> generateCorpusReport() async {
    final bodies = _bodies.values.toList();
    final typeDist = <BodyType, int>{};
    final categoryDist = <BodyCategory, int>{};
    final statusDist = <BodyStatus, int>{};
    final constitutionalDist = <ConstitutionalBasis, int>{};
    final statutoryDist = <StatutoryBasis, int>{};
    final jurisdictionDist = <BodyJurisdiction, int>{};
    final relevanceDist = <UpscRelevanceLevel, int>{};

    int articleLinks = 0;
    int actLinks = 0;
    int caseLawLinks = 0;
    int doctrineLinks = 0;
    int committeeLinks = 0;
    int reportLinks = 0;
    int schemeLinks = 0;
    int pyqLinks = 0;
    int caLinks = 0;
    int bodyLinks = 0;
    int relationships = 0;
    int evidenceRefs = 0;
    int published = 0;

    for (final b in bodies) {
      typeDist[b.bodyType] = (typeDist[b.bodyType] ?? 0) + 1;
      categoryDist[b.category] = (categoryDist[b.category] ?? 0) + 1;
      statusDist[b.bodyStatus] = (statusDist[b.bodyStatus] ?? 0) + 1;
      constitutionalDist[b.constitutionalBasis] =
          (constitutionalDist[b.constitutionalBasis] ?? 0) + 1;
      statutoryDist[b.statutoryBasis] = (statutoryDist[b.statutoryBasis] ?? 0) + 1;
      jurisdictionDist[b.jurisdiction] = (jurisdictionDist[b.jurisdiction] ?? 0) + 1;
      relevanceDist[b.upscRelevance] = (relevanceDist[b.upscRelevance] ?? 0) + 1;

      articleLinks += b.establishingArticleIds.length + b.relatedArticleIds.length;
      actLinks += b.establishingActIds.length + b.relatedActIds.length;
      caseLawLinks += b.relatedCaseLawIds.length;
      doctrineLinks += b.relatedDoctrineIds.length;
      committeeLinks += b.relatedCommitteeIds.length;
      reportLinks += b.relatedReportIds.length;
      schemeLinks += b.relatedSchemeIds.length;
      pyqLinks += b.relatedPyqIds.length;
      caLinks += b.relatedCurrentAffairsIds.length;
      bodyLinks += b.relatedBodyIds.length;
      relationships += b.relationships.length;
      evidenceRefs += b.evidenceIds.length;
      if (b.editorialStatus == EditorialStatus.published) published++;
    }

    double coverage(int imported, int expected) => expected > 0
        ? double.parse(((imported / expected) * 100).toStringAsFixed(1))
        : 100.0;

    return BodyCorpusReport(
      totalExpectedBodies: BodySeedCorpus.expectedBodyCorpus,
      totalImportedBodies: bodies.length,
      bodyCoveragePercentage: coverage(
          bodies.length, BodySeedCorpus.expectedBodyCorpus),
      bodyTypeCount: typeDist.length,
      categoryCount: categoryDist.length,
      bodyTypeDistribution: Map.unmodifiable(typeDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      statusDistribution: Map.unmodifiable(statusDist),
      constitutionalBasisDistribution: Map.unmodifiable(constitutionalDist),
      statutoryBasisDistribution: Map.unmodifiable(statutoryDist),
      jurisdictionDistribution: Map.unmodifiable(jurisdictionDist),
      upscRelevanceDistribution: Map.unmodifiable(relevanceDist),
      totalArticleLinks: articleLinks,
      totalActLinks: actLinks,
      totalCaseLawLinks: caseLawLinks,
      totalDoctrineLinks: doctrineLinks,
      totalCommitteeLinks: committeeLinks,
      totalReportLinks: reportLinks,
      totalSchemeLinks: schemeLinks,
      totalPyqLinks: pyqLinks,
      totalCurrentAffairsLinks: caLinks,
      totalBodyLinks: bodyLinks,
      totalRelationships: relationships,
      totalEvidenceReferences: evidenceRefs,
      totalPublishedBodies: published,
    );
  }

  void clear() => _bodies.clear();
}
