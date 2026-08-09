import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.4 — Judgment Intelligence search: ranked hits and autocomplete
/// (TITAN-KO-015.0 P4).
void main() {
  final cases = CaseSeedData.cases;

  group('search', () {
    test('returns no hits for an empty query', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(),
      );
      expect(hits, isEmpty);
    });

    test('finds the basic-structure cases by doctrine keyword', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(keyword: 'Basic Structure'),
      );
      expect(hits, isNotEmpty);
      // Ranking sums exact/prefix/substring matches across every intelligence
      // layer, so several basic-structure cases compete for the top slot.
      final topIds = hits.take(3).map((h) => h.caseId).toList();
      expect(topIds, contains('KESAVANANDA'));
      expect(topIds, contains('IR_COELHO'));
    });

    test('finds cases by article reference', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(article: 'Article 368'),
      );
      expect(hits.any((h) => h.caseId == 'KESAVANANDA'), isTrue);
      expect(hits.any((h) => h.caseId == 'GOLAKNATH'), isTrue);
    });

    test('finds cases by judge name prefix', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(judge: 'Khanna'),
      );
      expect(hits, isNotEmpty);
      expect(hits.any((h) => h.caseId == 'KESAVANANDA'), isTrue);
    });

    test('finds cases by prelims trap content', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(
            prelimsTrap: 'Golaknath is NOT current law'),
      );
      expect(hits.any((h) => h.caseId == 'KESAVANANDA'), isTrue);
    });

    test('finds cases by mains theme', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(
            mainsTheme: 'Basic structure doctrine and the limits'),
      );
      expect(hits.any((h) => h.caseId == 'KESAVANANDA'), isTrue);
    });

    test('honours the result limit', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(
            keyword: 'Article', limit: 3),
      );
      expect(hits.length, lessThanOrEqualTo(3));
    });

    test('results are sorted by descending score', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(keyword: 'right to life'),
      );
      for (var i = 1; i < hits.length; i++) {
        expect(hits[i - 1].score, greaterThanOrEqualTo(hits[i].score));
      }
    });

    test('matchedFields are reported', () {
      final hits = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(keyword: 'Basic Structure'),
      );
      expect(hits.first.matchedFields, contains('keyword'));
    });

    test('exact term ranks above substring match', () {
      final exact = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(keyword: 'Kesavananda'),
      );
      final partial = JudgmentIntelligenceSearchEngine.search(
        cases: cases,
        query: const JudgmentIntelligenceSearchQuery(keyword: 'Kesavan'),
      );
      expect(exact.first.score, greaterThanOrEqualTo(partial.first.score));
    });
  });

  group('autocomplete', () {
    test('suggests indexed terms by prefix', () {
      final suggestions = JudgmentIntelligenceSearchEngine.autocomplete(
        cases: cases,
        prefix: 'basic',
      );
      expect(suggestions, isNotEmpty);
      expect(
          suggestions.any(
              (s) => s.toLowerCase().contains('basic structure')),
          isTrue);
    });

    test('respects the result limit', () {
      final suggestions = JudgmentIntelligenceSearchEngine.autocomplete(
        cases: cases,
        prefix: 'a',
        limit: 5,
      );
      expect(suggestions.length, lessThanOrEqualTo(5));
    });

    test('is case-insensitive', () {
      final lower = JudgmentIntelligenceSearchEngine.autocomplete(
        cases: cases,
        prefix: 'golak',
      );
      final upper = JudgmentIntelligenceSearchEngine.autocomplete(
        cases: cases,
        prefix: 'GOLAK',
      );
      expect(lower, isNotEmpty);
      expect(upper, isNotEmpty);
      expect(upper.first.toLowerCase(), lower.first.toLowerCase());
    });
  });
}
