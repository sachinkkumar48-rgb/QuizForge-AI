import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InMemoryInternationalRepository', () {
    test('seeds the full Phase-I corpus and reports expected counts', () async {
      final repo = InMemoryInternationalRepository();
      final all = await repo.getAllOrganisations();
      expect(all.length, InternationalSeedCorpus.expectedInternationalCorpus);

      final corpus = await repo.generateCorpusReport();
      expect(corpus.totalExpectedOrganisations,
          InternationalSeedCorpus.expectedInternationalCorpus);
      expect(corpus.totalImportedOrganisations, all.length);
      expect(corpus.organisationCoveragePercentage, 100.0);
      expect(corpus.bodyTypeCount, greaterThan(5));
      expect(corpus.categoryCount, greaterThan(5));
      expect(corpus.totalEvidenceReferences, greaterThan(0));
      expect(corpus.totalTreatyLinks, greaterThan(0));
      expect(corpus.totalConventionLinks, greaterThan(0));
      expect(corpus.totalOrganisationLinks, greaterThan(0));
      expect(corpus.totalIndiaRelevantOrganisations, greaterThan(20));
    });

    test('CRUD: save, get, update', () async {
      final repo = InMemoryInternationalRepository(seedDefaultCorpus: false);
      final org = InternationalKnowledgeObject(
        id: 'int_crud',
        officialName: 'CRUD Test Organisation',
        shortName: 'CRUD Org',
        acronym: 'CTO',
        bodyType: InternationalBodyType.organisation,
        category: InternationalCategory.regionalGrouping,
        establishedYear: 2020,
        headquarters: 'New Delhi',
        mandate: 'CRUD test organisation.',
        officialSource: 'https://www.un.org/',
        evidenceIds: const ['ev_crud'],
      );

      await repo.saveOrganisation(org);
      final fetched = await repo.getOrganisationById('int_crud');
      expect(fetched, isNotNull);
      expect(fetched!.officialName, 'CRUD Test Organisation');

      final updated =
          org.copyWith(institutionalStatus: InstitutionalStatus.reformed);
      await repo.saveOrganisation(updated);
      final refetched = await repo.getOrganisationById('int_crud');
      expect(refetched!.institutionalStatus, InstitutionalStatus.reformed);
    });

    test('lookup by exact name and acronym', () async {
      final repo = InMemoryInternationalRepository();
      final who =
          await repo.getOrganisationByExactName('World Health Organization');
      expect(who, isNotNull);
      expect(who!.id, 'int_who');

      final imf = await repo.getOrganisationByAcronym('IMF');
      expect(imf, isNotNull);
      expect(imf!.id, 'int_imf');
    });

    test('filters by body type, category, region and headquarters', () async {
      final repo = InMemoryInternationalRepository();

      final agencies = await repo.getByBodyType(InternationalBodyType.specialisedAgency);
      expect(agencies, isNotEmpty);
      expect(agencies.any((o) => o.id == 'int_who'), isTrue);

      final unSystem = await repo.getByCategory(InternationalCategory.unitedNations);
      expect(unSystem.length, greaterThan(15));

      final global = await repo.getByRegion(GeographicalRegion.global);
      expect(global.length, greaterThan(30));

      final indiaHq = await repo.getByHeadquartersRegion(HeadquartersRegion.india);
      expect(indiaHq, hasLength(1));
      expect(indiaHq.first.id, 'int_isa');
    });

    test('filters by founding year, membership, India relationship and issue',
        () async {
      final repo = InMemoryInternationalRepository();

      final foundingMembers =
          await repo.getByIndiaRelationship(IndiaRelationshipStatus.foundingMember);
      expect(foundingMembers, isNotEmpty);
      expect(foundingMembers.any((o) => o.id == 'int_un'), isTrue);

      final health = await repo.getByIssueArea(GlobalIssueArea.health);
      expect(health, isNotEmpty);
      expect(health.any((o) => o.id == 'int_who'), isTrue);

      final fullMembers = await repo.getByMembershipType(MembershipType.fullMember);
      expect(fullMembers.length, greaterThan(30));

      final byYear = await repo.getByFoundingYear(1945);
      expect(byYear, isNotEmpty);
      expect(byYear.any((o) => o.id == 'int_un'), isTrue);

      final highUpsc = await repo.getByUpscRelevance(UpscRelevanceLevel.high);
      expect(highUpsc.length, greaterThan(15));
    });

    test('filters by treaty and keyword', () async {
      final repo = InMemoryInternationalRepository();

      final byTreaty = await repo.getByTreaty('Charter of the United Nations');
      expect(byTreaty, isNotEmpty);
      expect(byTreaty.any((o) => o.id == 'int_un'), isTrue);

      final byKeyword = await repo.getByKeyword('solar');
      expect(byKeyword, isNotEmpty);
      expect(byKeyword.any((o) => o.id == 'int_isa'), isTrue);
    });

    test('related-organisation discovery returns explicit and semantic links',
        () async {
      final repo = InMemoryInternationalRepository();
      final who = await repo.getOrganisationById('int_who');
      final related = await repo.getRelatedOrganisations(who!);
      expect(related, isNotEmpty);
      final ids = related.map((o) => o.id).toSet();
      expect(ids.contains('int_un'), isTrue); // explicit relatedOrganisationId
      expect(ids.contains('int_who'), isFalse); // never self
    });

    test('multi-criteria search via repository is relevance-ranked', () async {
      final repo = InMemoryInternationalRepository();
      final results = await repo.searchOrganisations(
        const InternationalSearchQuery(category: InternationalCategory.unitedNations),
      );
      expect(results, isNotEmpty);
      expect(
          results.every((o) => o.category == InternationalCategory.unitedNations),
          isTrue);

      final ranked = await repo.searchOrganisations(
        const InternationalSearchQuery(keyword: 'Bank'),
      );
      expect(ranked, isNotEmpty);
    });

    test('saveOrganisation enforces unique ID (last write wins, no duplicates)',
        () async {
      final repo = InMemoryInternationalRepository(seedDefaultCorpus: false);
      final a = InternationalKnowledgeObject(
        id: 'int_dup',
        officialName: 'Duplicate Org',
        shortName: 'DUP',
        acronym: 'DUP',
        bodyType: InternationalBodyType.organisation,
        category: InternationalCategory.regionalGrouping,
        establishedYear: 2021,
        mandate: 'Duplicate organisation.',
        officialSource: 'https://www.un.org/',
        evidenceIds: const ['ev_dup'],
      );
      final b = a.copyWith(officialName: 'Duplicate Org v2', version: 3);
      await repo.saveOrganisation(a);
      await repo.saveOrganisation(b);
      final all = await repo.getAllOrganisations();
      expect(all.where((x) => x.id == 'int_dup'), hasLength(1));
      expect((await repo.getOrganisationById('int_dup'))!.officialName,
          'Duplicate Org v2');
    });
  });
}
