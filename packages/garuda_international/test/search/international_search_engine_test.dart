import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalSearchEngine', () {
    Future<List<InternationalKnowledgeObject>> corpus() async =>
        (await InMemoryInternationalRepository().getAllOrganisations());

    test('exact-name lookup is case-insensitive and matches acronyms', () async {
      final exact = InternationalSearchEngine.findByExactName(
        organisations: await corpus(),
        name: 'WORLD HEALTH ORGANIZATION',
      );
      expect(exact, hasLength(1));
      expect(exact.first.id, 'int_who');

      final byAcronym = InternationalSearchEngine.findByExactName(
        organisations: await corpus(),
        name: 'IMF',
      );
      expect(byAcronym, hasLength(1));
      expect(byAcronym.first.id, 'int_imf');
    });

    test('acronym search finds organisations by short name', () async {
      final results = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(acronym: 'UNSC'),
      );
      expect(results, hasLength(1));
      expect(results.first.id, 'int_unsc');
    });

    test('keyword search matches mandate, objectives and keywords', () async {
      final results = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(keyword: 'money laundering'),
      );
      expect(results, isNotEmpty);
      expect(results.any((o) => o.id == 'int_fatf'), isTrue);
    });

    test('treaty and category filters return the establishing organisation',
        () async {
      final byTreaty = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(
            treaty: 'Charter of the United Nations'),
      );
      expect(byTreaty.any((o) => o.id == 'int_un'), isTrue);

      final byCategory = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(
            category: InternationalCategory.developmentBank),
      );
      expect(byCategory, isNotEmpty);
      expect(byCategory.any((o) => o.id == 'int_ndb'), isTrue);
    });

    test('India-relationship and issue-area filters', () async {
      final founding = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(
            indiaRelationship: IndiaRelationshipStatus.foundingMember),
      );
      expect(founding.any((o) => o.id == 'int_un'), isTrue);

      final climate = InternationalSearchEngine.search(
        organisations: await corpus(),
        query: const InternationalSearchQuery(issueArea: GlobalIssueArea.climate),
      );
      expect(climate.any((o) => o.id == 'int_unfccc'), isTrue);
    });

    test('relevance-ranked search puts exact name matches first', () async {
      final ranked = InternationalSearchEngine.searchRanked(
        organisations: await corpus(),
        query: const InternationalSearchQuery(keyword: 'Bank'),
        maxResults: 20,
      );
      expect(ranked, isNotEmpty);
      // 'Bank' in the official name ranks higher than keyword-only matches.
      expect(
          ranked.first.officialName.toLowerCase().contains('bank'), isTrue);

      final exact = InternationalSearchEngine.searchRanked(
        organisations: await corpus(),
        query: const InternationalSearchQuery(acronym: 'IMF'),
      );
      expect(exact.first.id, 'int_imf');
    });

    test('autocomplete returns prefix matches for names, acronyms, keywords',
        () async {
      final suggestions = InternationalSearchEngine.autocomplete(
        organisations: await corpus(),
        prefix: 'United Nations',
        maxResults: 20,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.startsWith('United Nations')), isTrue);
    });

    test('keyword suggestions derive from the corpus vocabulary', () async {
      final suggestions = InternationalSearchEngine.suggestKeywords(
        organisations: await corpus(),
        prefix: 'Solar',
        maxResults: 10,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.startsWith('Solar')), isTrue);
    });

    test('related-organisation discovery never returns self', () async {
      final all = await corpus();
      final who = all.firstWhere((o) => o.id == 'int_who');
      final related = InternationalSearchEngine.relatedOrganisations(
        organisations: all,
        organisation: who,
      );
      expect(related.every((o) => o.id != 'int_who'), isTrue);
      expect(related.map((o) => o.id).toSet().contains('int_un'), isTrue);
    });
  });
}
