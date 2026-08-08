library;

import '../data/scheme_seed_corpus.dart';
import '../domain/entities/scheme_beneficiary.dart';
import '../domain/entities/scheme_enums.dart';
import '../domain/entities/scheme_knowledge_object.dart';
import '../domain/entities/scheme_ministry.dart';
import '../search/scheme_search_engine.dart';
import 'scheme_repository.dart';

/// In-memory implementation of SchemeRepository pre-seeded with the Phase-I
/// corpus. Offline-first and JSON-compatible.
class InMemorySchemeRepository implements SchemeRepository {
  final Map<String, SchemeKnowledgeObject> _schemes = {};

  InMemorySchemeRepository({bool seedDefaultCorpus = true}) {
    if (seedDefaultCorpus) {
      for (final scheme in SchemeSeedCorpus.phase1Schemes) {
        _schemes[scheme.id] = scheme;
      }
    }
  }

  @override
  Future<void> saveScheme(SchemeKnowledgeObject object) async {
    _schemes[object.id] = object;
  }

  @override
  Future<SchemeKnowledgeObject?> getSchemeById(String id) async => _schemes[id];

  @override
  Future<List<SchemeKnowledgeObject>> getAllSchemes() async =>
      List.unmodifiable(_schemes.values.toList());

  @override
  Future<SchemeKnowledgeObject?> getSchemeByExactName(String name) async {
    final matches =
        SchemeSearchEngine.findByExactName(schemes: _schemes.values.toList(), name: name);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<SchemeKnowledgeObject?> getSchemeByAcronym(String acronym) async {
    final lower = acronym.toLowerCase().trim();
    for (final s in _schemes.values) {
      if (s.shortName.toLowerCase().trim() == lower) return s;
    }
    return null;
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByMinistry(
      SchemeMinistry ministry) async {
    return _schemes.values.where((s) => s.ministry == ministry).toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByDepartment(
      String department) async {
    final lower = department.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.department.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByCategory(
      SchemeCategory category) async {
    return _schemes.values.where((s) => s.category == category).toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesBySector(
      SchemeSector sector) async {
    return _schemes.values.where((s) => s.sector == sector).toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByBeneficiary(
      BeneficiaryGroup beneficiary) async {
    return _schemes.values
        .where((s) => s.beneficiaries.contains(beneficiary))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByStateUt(String stateUt) async {
    final lower = stateUt.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.geographicScope.any((g) => g.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByLaunchYear(int year) async {
    return _schemes.values.where((s) => s.launchDate?.year == year).toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByStatus(
      SchemeStatus status) async {
    return _schemes.values.where((s) => s.status == status).toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByArticle(String article) async {
    final lower = article.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.relatedArticleIds.any((a) => a.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByAct(String act) async {
    final lower = act.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.relatedActIds.any((a) => a.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByCommittee(
      String committeeId) async {
    final lower = committeeId.toLowerCase().trim();
    return _schemes.values
        .where((s) =>
            s.relatedCommitteeIds.any((c) => c.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByReport(String reportId) async {
    final lower = reportId.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.relatedReportIds.any((r) => r.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByPyq(String pyqId) async {
    final lower = pyqId.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.relatedPyqIds.any((p) => p.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getSchemesByCurrentAffairs(
      String currentAffairsId) async {
    final lower = currentAffairsId.toLowerCase().trim();
    return _schemes.values
        .where((s) => s.relatedCurrentAffairsIds
            .any((c) => c.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<SchemeKnowledgeObject>> getRelatedSchemes(
      SchemeKnowledgeObject scheme) async {
    return SchemeSearchEngine.relatedSchemes(
      schemes: _schemes.values.toList(),
      scheme: scheme,
    );
  }

  @override
  Future<List<SchemeKnowledgeObject>> searchSchemes(
      SchemeSearchQuery query) async {
    return SchemeSearchEngine.search(
      schemes: _schemes.values.toList(),
      query: query,
    );
  }

  @override
  Future<SchemeCorpusReport> generateCorpusReport() async {
    final schemes = _schemes.values.toList();
    final ministryDist = <SchemeMinistry, int>{};
    final categoryDist = <SchemeCategory, int>{};
    final typeDist = <SchemeType, int>{};
    final statusDist = <SchemeStatus, int>{};

    int articleLinks = 0;
    int actLinks = 0;
    int committeeLinks = 0;
    int reportLinks = 0;
    int caseLawLinks = 0;
    int doctrineLinks = 0;
    int pyqLinks = 0;
    int caLinks = 0;
    int sdgLinks = 0;
    int schemeRels = 0;
    int benefits = 0;
    int components = 0;

    for (final s in schemes) {
      ministryDist[s.ministry] = (ministryDist[s.ministry] ?? 0) + 1;
      categoryDist[s.category] = (categoryDist[s.category] ?? 0) + 1;
      typeDist[s.schemeType] = (typeDist[s.schemeType] ?? 0) + 1;
      statusDist[s.status] = (statusDist[s.status] ?? 0) + 1;

      articleLinks += s.relatedArticleIds.length;
      actLinks += s.relatedActIds.length;
      committeeLinks += s.relatedCommitteeIds.length;
      reportLinks += s.relatedReportIds.length;
      caseLawLinks += s.relatedCaseLawIds.length;
      doctrineLinks += s.relatedDoctrineIds.length;
      pyqLinks += s.relatedPyqIds.length;
      caLinks += s.relatedCurrentAffairsIds.length;
      sdgLinks += s.sdgGoals.length;
      schemeRels += s.relationships.length;
      benefits += s.benefits.length;
      components += s.components.length;
    }

    double coverage(int imported, int expected) => expected > 0
        ? double.parse(((imported / expected) * 100).toStringAsFixed(1))
        : 100.0;

    return SchemeCorpusReport(
      totalExpectedSchemes: SchemeSeedCorpus.expectedSchemeCorpus,
      totalImportedSchemes: schemes.length,
      schemeCoveragePercentage: coverage(
          schemes.length, SchemeSeedCorpus.expectedSchemeCorpus),
      ministryCount: ministryDist.length,
      categoryCount: categoryDist.length,
      sectorCount: schemes.map((s) => s.sector).toSet().length,
      ministryDistribution: Map.unmodifiable(ministryDist),
      categoryDistribution: Map.unmodifiable(categoryDist),
      schemeTypeDistribution: Map.unmodifiable(typeDist),
      statusDistribution: Map.unmodifiable(statusDist),
      totalConstitutionalLinks: articleLinks,
      totalActLinks: actLinks,
      totalCommitteeLinks: committeeLinks,
      totalReportLinks: reportLinks,
      totalCaseLawLinks: caseLawLinks,
      totalDoctrineLinks: doctrineLinks,
      totalPyqLinks: pyqLinks,
      totalCurrentAffairsLinks: caLinks,
      totalSdgLinks: sdgLinks,
      totalSchemeRelationships: schemeRels,
      totalBenefits: benefits,
      totalComponents: components,
    );
  }

  void clear() => _schemes.clear();
}
