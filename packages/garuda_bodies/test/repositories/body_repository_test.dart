import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';

void main() {
  group('InMemoryBodyRepository', () {
    test('seeds the full Phase-I corpus and reports expected counts', () async {
      final repo = InMemoryBodyRepository();
      final all = await repo.getAllBodies();
      expect(all.length, BodySeedCorpus.expectedBodyCorpus);

      final corpus = await repo.generateCorpusReport();
      expect(corpus.totalExpectedBodies, BodySeedCorpus.expectedBodyCorpus);
      expect(corpus.totalImportedBodies, all.length);
      expect(corpus.bodyCoveragePercentage, 100.0);
      expect(corpus.bodyTypeCount, greaterThan(3));
      expect(corpus.categoryCount, greaterThan(5));
      expect(corpus.totalArticleLinks, greaterThan(0));
      expect(corpus.totalActLinks, greaterThan(0));
      expect(corpus.totalEvidenceReferences, greaterThan(0));
      expect(corpus.totalBodyLinks, greaterThan(0));
    });

    test('CRUD: save, get, update', () async {
      final repo = InMemoryBodyRepository(seedDefaultCorpus: false);
      final body = BodyKnowledgeObject(
        id: 'bod_crud',
        officialName: 'CRUD Body',
        shortName: 'CRUD',
        bodyType: BodyType.statutory,
        category: BodyCategory.authority,
        yearEstablished: 2020,
        establishingArticleIds: const ['Article 21'],
        mandate: 'CRUD test body',
        officialSource: 'https://eci.gov.in/',
        evidenceIds: const ['ev_crud'],
      );

      await repo.saveBody(body);
      final fetched = await repo.getBodyById('bod_crud');
      expect(fetched, isNotNull);
      expect(fetched!.officialName, 'CRUD Body');

      final updated = body.copyWith(bodyStatus: BodyStatus.discontinued);
      await repo.saveBody(updated);
      final refetched = await repo.getBodyById('bod_crud');
      expect(refetched!.bodyStatus, BodyStatus.discontinued);
    });

    test('lookup by exact name and acronym', () async {
      final repo = InMemoryBodyRepository();
      final eci = await repo.getBodyByExactName('Election Commission of India');
      expect(eci, isNotNull);
      expect(eci!.id, 'bod_eci');

      final rbi = await repo.getBodyByAcronym('RBI');
      expect(rbi, isNotNull);
      expect(rbi!.id, 'bod_rbi');
    });

    test('filters by type, category, jurisdiction, authority, status', () async {
      final repo = InMemoryBodyRepository();

      final constitutional =
          await repo.getBodiesByType(BodyType.constitutional);
      expect(constitutional, hasLength(11));

      final commissions = await repo.getBodiesByCategory(BodyCategory.commission);
      expect(commissions, isNotEmpty);

      final national = await repo.getBodiesByJurisdiction(BodyJurisdiction.national);
      expect(national.length, greaterThan(30));

      final presidentAppointed =
          await repo.getBodiesByAppointmentAuthority(AppointmentAuthority.president);
      expect(presidentAppointed, isNotEmpty);
      expect(presidentAppointed.any((b) => b.id == 'bod_eci'), isTrue);

      final active = await repo.getBodiesByStatus(BodyStatus.active);
      expect(active.length, greaterThan(30));
    });

    test('filters by constitutional article and act', () async {
      final repo = InMemoryBodyRepository();

      final byArticle = await repo.getBodiesByArticle('Article 324');
      expect(byArticle, isNotEmpty);
      expect(byArticle.any((b) => b.id == 'bod_eci'), isTrue);

      final byAct = await repo.getBodiesByAct('Reserve Bank of India Act, 1934');
      expect(byAct, isNotEmpty);
      expect(byAct.any((b) => b.id == 'bod_rbi'), isTrue);
    });

    test('filters by ministry, keyword, year and UPSC relevance', () async {
      final repo = InMemoryBodyRepository();

      final byMinistry = await repo.getBodiesByMinistry('Ministry of Finance');
      expect(byMinistry, isNotEmpty);
      expect(byMinistry.any((b) => b.id == 'bod_rbi'), isTrue);

      final byKeyword = await repo.getBodiesByKeyword('Aadhaar');
      expect(byKeyword, isNotEmpty);
      expect(byKeyword.any((b) => b.id == 'bod_uidai'), isTrue);

      final byYear = await repo.getBodiesByYearEstablished(2005);
      expect(byYear, isNotEmpty);

      final highRelevance =
          await repo.getBodiesByUpscRelevance(UpscRelevanceLevel.high);
      expect(highRelevance, isNotEmpty);
      expect(highRelevance.any((b) => b.id == 'bod_eci'), isTrue);
    });

    test('related-body discovery returns explicit and semantic links', () async {
      final repo = InMemoryBodyRepository();
      final eci = await repo.getBodyById('bod_eci');
      final related = await repo.getRelatedBodies(eci!);
      expect(related, isNotEmpty);
      final ids = related.map((b) => b.id).toSet();
      expect(ids.contains('bod_state_election_commissions'), isTrue); // explicit
      expect(ids.contains('bod_eci'), isFalse); // never self
    });

    test('multi-criteria search via repository is relevance-ranked', () async {
      final repo = InMemoryBodyRepository();
      final results = await repo.searchBodies(
        const BodySearchQuery(bodyType: BodyType.constitutional),
      );
      expect(results, isNotEmpty);
      expect(
          results.every((b) => b.bodyType == BodyType.constitutional), isTrue);

      final ranked = await repo.searchBodies(
        const BodySearchQuery(keyword: 'Commission'),
      );
      expect(ranked, isNotEmpty);
    });

    test('saveBody enforces unique ID (last write wins, no duplicates)',
        () async {
      final repo = InMemoryBodyRepository(seedDefaultCorpus: false);
      final a = BodyKnowledgeObject(
        id: 'bod_dup',
        officialName: 'Duplicate Body',
        shortName: 'DUP',
        bodyType: BodyType.statutory,
        category: BodyCategory.board,
        yearEstablished: 2021,
        establishingActIds: const ['Test Act, 2020'],
        officialSource: 'https://eci.gov.in/',
        evidenceIds: const ['ev_dup'],
      );
      final b = a.copyWith(officialName: 'Duplicate Body v2', version: 3);
      await repo.saveBody(a);
      await repo.saveBody(b);
      final all = await repo.getAllBodies();
      expect(all.where((x) => x.id == 'bod_dup'), hasLength(1));
      expect((await repo.getBodyById('bod_dup'))!.officialName,
          'Duplicate Body v2');
    });
  });
}
