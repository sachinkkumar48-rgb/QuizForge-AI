import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';

void main() {
  group('BodySearchEngine', () {
    Future<List<BodyKnowledgeObject>> corpus() async =>
        (await InMemoryBodyRepository().getAllBodies());

    test('exact-name lookup is case-insensitive', () async {
      final exact = BodySearchEngine.findByExactName(
        bodies: await corpus(),
        name: 'ELECTION COMMISSION OF INDIA',
      );
      expect(exact, hasLength(1));
      expect(exact.first.id, 'bod_eci');
    });

    test('acronym search finds bodies by short name', () async {
      final results = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(acronym: 'RBI'),
      );
      expect(results, hasLength(1));
      expect(results.first.id, 'bod_rbi');
    });

    test('keyword search matches mandate, powers and keywords', () async {
      final results = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(keyword: 'green tribunal'),
      );
      expect(results, isNotEmpty);
      expect(results.any((b) => b.id == 'bod_ngt'), isTrue);
    });

    test('article and act filters return the establishing body', () async {
      final byArticle = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(article: 'Article 324'),
      );
      expect(byArticle.any((b) => b.id == 'bod_eci'), isTrue);

      final byAct = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(act: 'Securities and Exchange Board of India Act'),
      );
      expect(byAct.any((b) => b.id == 'bod_sebi'), isTrue);
    });

    test('body-type and category filters combine', () async {
      final results = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(
          bodyType: BodyType.quasiJudicial,
          category: BodyCategory.tribunal,
        ),
      );
      expect(results, isNotEmpty);
      expect(results.any((b) => b.id == 'bod_ngt'), isTrue);
      expect(
          results.every((b) =>
              b.bodyType == BodyType.quasiJudicial &&
              b.category == BodyCategory.tribunal),
          isTrue);
    });

    test('ministry filter matches the oversight arrangement', () async {
      final results = BodySearchEngine.search(
        bodies: await corpus(),
        query: const BodySearchQuery(ministry: 'Ministry of Tribal Affairs'),
      );
      expect(results.any((b) => b.id == 'bod_ncst'), isTrue);
    });

    test('relevance-ranked search puts name matches ahead of keyword-only',
        () async {
      final ranked = BodySearchEngine.searchRanked(
        bodies: await corpus(),
        query: const BodySearchQuery(keyword: 'Commission'),
        maxResults: 20,
      );
      expect(ranked, isNotEmpty);
      // Bodies named "... Commission" score higher than keyword-only matches,
      // so the top result must carry 'Commission' in its official name.
      expect(ranked.first.officialName.toLowerCase().contains('commission'),
          isTrue);
      // Exact acronym search ranks the acronym holder first.
      final rbi = BodySearchEngine.searchRanked(
        bodies: await corpus(),
        query: const BodySearchQuery(acronym: 'RBI'),
      );
      expect(rbi.first.id, 'bod_rbi');
    });

    test('autocomplete returns prefix matches for names and keywords', () async {
      final suggestions = BodySearchEngine.autocomplete(
        bodies: await corpus(),
        prefix: 'National',
        maxResults: 20,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.startsWith('National')), isTrue);
    });

    test('keyword suggestions derive from the corpus vocabulary', () async {
      final suggestions = BodySearchEngine.suggestKeywords(
        bodies: await corpus(),
        prefix: 'Elec',
        maxResults: 10,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.startsWith('Elec')), isTrue);
    });

    test('related-body discovery never returns self and prefers explicit',
        () async {
      final all = await corpus();
      final eci = all.firstWhere((b) => b.id == 'bod_eci');
      final related = BodySearchEngine.relatedBodies(
        bodies: all,
        body: eci,
      );
      expect(related.every((b) => b.id != 'bod_eci'), isTrue);
      expect(related.map((b) => b.id).toSet().contains('bod_state_election_commissions'),
          isTrue);
    });
  });
}
