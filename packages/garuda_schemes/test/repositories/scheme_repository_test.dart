import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('InMemorySchemeRepository', () {
    test('seeds the full Phase-I corpus and reports expected counts', () async {
      final repo = InMemorySchemeRepository();
      final all = await repo.getAllSchemes();
      expect(all.length, SchemeSeedCorpus.expectedSchemeCorpus);

      final corpus = await repo.generateCorpusReport();
      expect(corpus.totalExpectedSchemes, SchemeSeedCorpus.expectedSchemeCorpus);
      expect(corpus.totalImportedSchemes, all.length);
      expect(corpus.schemeCoveragePercentage, 100.0);
      expect(corpus.ministryCount, greaterThan(10));
      expect(corpus.categoryCount, greaterThan(10));
      expect(corpus.totalConstitutionalLinks, greaterThan(0));
      expect(corpus.totalActLinks, greaterThan(0));
      expect(corpus.totalPyqLinks, greaterThan(0));
      expect(corpus.totalSdgLinks, greaterThan(0));
    });

    test('CRUD: save, get, update', () async {
      final repo = InMemorySchemeRepository(seedDefaultCorpus: false);
      final scheme = SchemeKnowledgeObject(
        id: 'sch_crud',
        officialName: 'CRUD Scheme',
        shortName: 'CRUD',
        ministry: SchemeMinistry.healthFamilyWelfare,
        category: SchemeCategory.health,
        sector: SchemeSector.health,
        launchDate: DateTime(2021, 1, 1),
        officialSource: 'https://nhm.gov.in/',
        evidenceIds: const ['ev_crud'],
      );

      await repo.saveScheme(scheme);
      final fetched = await repo.getSchemeById('sch_crud');
      expect(fetched, isNotNull);
      expect(fetched!.officialName, 'CRUD Scheme');

      final updated = scheme.copyWith(
          status: SchemeStatus.discontinued, version: 2);
      await repo.saveScheme(updated);
      final refetched = await repo.getSchemeById('sch_crud');
      expect(refetched!.status, SchemeStatus.discontinued);
      expect(refetched.version, 2);
    });

    test('lookup by exact name and acronym', () async {
      final repo = InMemorySchemeRepository();
      final pmkisan = await repo.getSchemeByExactName(
          'Pradhan Mantri Kisan Samman Nidhi');
      expect(pmkisan, isNotNull);
      expect(pmkisan!.id, 'sch_pm_kisan');

      final byAcronym = await repo.getSchemeByAcronym('PMFBY');
      expect(byAcronym, isNotNull);
      expect(byAcronym!.id, 'sch_pmfby');
    });

    test('filters by ministry, category, sector, beneficiary and status',
        () async {
      final repo = InMemorySchemeRepository();

      final byMinistry = await repo.getSchemesByMinistry(
          SchemeMinistry.agricultureFarmersWelfare);
      expect(byMinistry, isNotEmpty);

      final byCategory = await repo.getSchemesByCategory(SchemeCategory.health);
      expect(byCategory, isNotEmpty);
      expect(byCategory.every((s) => s.category == SchemeCategory.health), isTrue);

      final bySector = await repo.getSchemesBySector(SchemeSector.energy);
      expect(bySector, isNotEmpty);
      expect(bySector.every((s) => s.sector == SchemeSector.energy), isTrue);

      final byBeneficiary =
          await repo.getSchemesByBeneficiary(BeneficiaryGroup.women);
      expect(byBeneficiary, isNotEmpty);
      expect(byBeneficiary.any((s) => s.id == 'sch_bbbp'), isTrue);

      final byStatus = await repo.getSchemesByStatus(SchemeStatus.operational);
      expect(byStatus.length, greaterThan(50));

      final byYear = await repo.getSchemesByLaunchYear(2015);
      expect(byYear, isNotEmpty);
    });

    test('filters by cross-package references', () async {
      final repo = InMemorySchemeRepository();

      final byArticle = await repo.getSchemesByArticle('Article 21');
      expect(byArticle, isNotEmpty);
      expect(byArticle.any((s) => s.id == 'sch_pm_jay'), isTrue);

      final byAct = await repo.getSchemesByAct('National Food Security Act');
      expect(byAct, isNotEmpty);
      expect(byAct.any((s) => s.id == 'sch_pmgkay'), isTrue);

      final byCommittee =
          await repo.getSchemesByCommittee('comm_swaminathan_2004');
      expect(byCommittee, isNotEmpty);
      expect(byCommittee.any((s) => s.id == 'sch_pm_kisan'), isTrue);

      final byReport = await repo.getSchemesByReport('rep_es_2025_official');
      expect(byReport, isNotEmpty);

      final byPyq = await repo.getSchemesByPyq('PYQ_UPSC_CSE_2020_GS2_Q010');
      expect(byPyq, isNotEmpty);
      expect(byPyq.any((s) => s.id == 'sch_pm_kisan'), isTrue);
    });

    test('related-scheme discovery returns explicit and semantic links',
        () async {
      final repo = InMemorySchemeRepository();
      final pmkisan = await repo.getSchemeById('sch_pm_kisan');
      final related = await repo.getRelatedSchemes(pmkisan!);
      expect(related, isNotEmpty);
      final ids = related.map((s) => s.id).toSet();
      expect(ids.contains('sch_pmfby'), isTrue); // explicit relatedSchemeId
      expect(ids.contains('sch_pm_kisan'), isFalse); // never self
    });

    test('multi-field search via repository', () async {
      final repo = InMemorySchemeRepository();
      final results = await repo.searchSchemes(
        const SchemeSearchQuery(
          ministry: SchemeMinistry.jalShakti,
          category: SchemeCategory.waterSanitation,
        ),
      );
      expect(results, isNotEmpty);
      expect(results.every((s) => s.ministry == SchemeMinistry.jalShakti),
          isTrue);
    });

    test('saveScheme enforces unique ID (last write wins, no duplicates)',
        () async {
      final repo = InMemorySchemeRepository(seedDefaultCorpus: false);
      final a = SchemeKnowledgeObject(
        id: 'sch_dup',
        officialName: 'Duplicate Scheme',
        shortName: 'DUP',
        ministry: SchemeMinistry.finance,
        category: SchemeCategory.financialInclusion,
        sector: SchemeSector.financialInclusion,
        officialSource: 'https://pmjdy.gov.in/',
        evidenceIds: const ['ev_dup'],
      );
      final b = a.copyWith(version: 3, officialName: 'Duplicate Scheme v2');
      await repo.saveScheme(a);
      await repo.saveScheme(b);
      final all = await repo.getAllSchemes();
      expect(all.where((s) => s.id == 'sch_dup'), hasLength(1));
      expect((await repo.getSchemeById('sch_dup'))!.officialName,
          'Duplicate Scheme v2');
    });
  });
}
