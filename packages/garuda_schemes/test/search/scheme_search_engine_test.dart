import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeSearchEngine', () {
    // Fresh corpus per test (a single-subscription stream cannot be re-listened).
    Future<List<SchemeKnowledgeObject>> corpus() async =>
        (await InMemorySchemeRepository().getAllSchemes());

    test('exact-name lookup is case-insensitive', () async {
      final exact = SchemeSearchEngine.findByExactName(
        schemes: await corpus(),
        name: 'PRADHAN MANTRI KISAN SAMMAN NIDHI',
      );
      expect(exact, hasLength(1));
      expect(exact.first.id, 'sch_pm_kisan');
    });

    test('keyword search matches across title, keywords and features',
        () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(keyword: 'rooftop solar'),
      );
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == 'sch_pm_surya_ghar'), isTrue);
    });

    test('acronym filter matches short names', () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(acronym: 'PM-JAY'),
      );
      expect(results, hasLength(1));
      expect(results.first.id, 'sch_pm_jay');
    });

    test('combined filters narrow results correctly', () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(
          ministry: SchemeMinistry.jalShakti,
          sector: SchemeSector.waterSanitation,
        ),
      );
      expect(results, isNotEmpty);
      expect(
          results.every((s) =>
              s.ministry == SchemeMinistry.jalShakti &&
              s.sector == SchemeSector.waterSanitation),
          isTrue);
    });

    test('beneficiary filter returns schemes targeting that group', () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(beneficiary: BeneficiaryGroup.girlChild),
      );
      expect(results.any((s) => s.id == 'sch_bbbp'), isTrue);
    });

    test('status filter isolates discontinued schemes', () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(status: SchemeStatus.discontinued),
      );
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == 'sch_abry'), isTrue);
    });

    test('autocomplete returns prefix matches for names and keywords',
        () async {
      final suggestions = SchemeSearchEngine.autocomplete(
        schemes: await corpus(),
        prefix: 'PM ',
        maxResults: 20,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.startsWith('PM ')), isTrue);
    });

    test('keyword suggestions derive from the corpus vocabulary', () async {
      final suggestions = SchemeSearchEngine.suggestKeywords(
        schemes: await corpus(),
        prefix: 'Irrig',
        maxResults: 10,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.startsWith('Irrig')), isTrue);
    });

    test('related-scheme discovery never returns self and prefers explicit',
        () async {
      final all = await corpus();
      final pmkisan = all.firstWhere((s) => s.id == 'sch_pm_kisan');
      final related = SchemeSearchEngine.relatedSchemes(
        schemes: all,
        scheme: pmkisan,
      );
      expect(related.every((s) => s.id != 'sch_pm_kisan'), isTrue);
      expect(related.map((s) => s.id).toSet().contains('sch_pmfby'), isTrue);
    });

    test('state/UT scope filter matches geographic coverage', () async {
      final results = SchemeSearchEngine.search(
        schemes: await corpus(),
        query: const SchemeSearchQuery(stateUt: 'Ganga basin'),
      );
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == 'sch_namami_gange'), isTrue);
    });
  });
}
