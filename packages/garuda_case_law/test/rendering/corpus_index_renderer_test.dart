import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P8 — corpus index rendering (TITAN-KO-015.0 P8).
///
/// The index is a deterministic summary derived only from existing case
/// metadata. Verifies coverage, ordering, grouping, format integrity, and
/// determinism.
void main() {
  final corpus = CaseSeedData.cases;

  group('1. index build', () {
    test('covers all 49 cases', () {
      final index = CorpusIndex.build(corpus);
      expect(index.totalCases, 49);
      expect(index.entries.map((e) => e.caseId), contains('KESAVANANDA'));
    });

    test('entries are sorted by (year, caseId)', () {
      final index = CorpusIndex.build(corpus);
      for (var i = 1; i < index.entries.length; i++) {
        final prev = index.entries[i - 1];
        final cur = index.entries[i];
        expect(
          prev.year < cur.year ||
              (prev.year == cur.year && prev.caseId.compareTo(cur.caseId) <= 0),
          isTrue,
          reason:
              '${prev.caseId}(${prev.year}) before ${cur.caseId}(${cur.year})',
        );
      }
    });

    test('groups by doctrine, article and UPSC relevance', () {
      final index = CorpusIndex.build(corpus);
      expect(index.byDoctrine['BASIC_STRUCTURE'], contains('KESAVANANDA'));
      expect(index.byArticle['Article 14'], contains('KESAVANANDA'));
      expect(index.byPrelimsRelevance['critical'], contains('KESAVANANDA'));
      // notApplicable cases are excluded from the UPSC grouping.
      expect(index.byPrelimsRelevance.containsKey('notApplicable'), isFalse);
    });

    test('groups are internally sorted', () {
      final index = CorpusIndex.build(corpus);
      for (final list in index.byDoctrine.values) {
        expect(List.of(list)..sort(), list);
      }
    });
  });

  group('2. markdown', () {
    test('renders header, chronology and group sections', () {
      final md = CorpusIndexRenderer.renderMarkdown(corpus);
      expect(md, startsWith('# GARUDA Landmark Case Corpus Index'));
      expect(md, contains('49 landmark cases'));
      expect(md, contains('## Chronology'));
      expect(md, contains('## By Doctrine'));
      expect(md, contains('## By Constitutional Article'));
      expect(md, contains('## By UPSC Relevance'));
      expect(md, contains('- **KESAVANANDA** —'));
    });
  });

  group('3. html', () {
    test('renders semantic sections with escaped content', () {
      final html = CorpusIndexRenderer.renderHtml(corpus);
      expect(html, contains('<section class="corpus-index"'));
      expect(html, contains('<h2>Chronology</h2>'));
      expect(html, contains('<strong>KESAVANANDA</strong>'));
      expect(html, isNot(contains('<script')));
    });
  });

  group('4. json', () {
    test('renders a deterministic machine-readable index', () {
      final m = CorpusIndexRenderer.renderJson(corpus);
      expect(m['totalCases'], 49);
      expect(m['entries'], hasLength(49));
      final entries = m['entries'] as List<dynamic>;
      expect(entries.first, isA<Map<String, dynamic>>());
      expect((entries.first as Map)['caseId'], isA<String>());
      final groupings = m['groupings'] as Map<String, dynamic>;
      expect(groupings['byDecade'], isA<Map<String, dynamic>>());
      expect(groupings['byDoctrine'], isA<Map<String, dynamic>>());
      expect(groupings['byArticle'], isA<Map<String, dynamic>>());
      expect(groupings['byPrelimsRelevance'], isA<Map<String, dynamic>>());
    });
  });

  group('5. determinism', () {
    test('markdown / html / json are byte-identical across calls', () {
      expect(CorpusIndexRenderer.renderMarkdown(corpus),
          CorpusIndexRenderer.renderMarkdown(corpus));
      expect(CorpusIndexRenderer.renderHtml(corpus),
          CorpusIndexRenderer.renderHtml(corpus));
      expect(CorpusIndexRenderer.renderJson(corpus),
          CorpusIndexRenderer.renderJson(corpus));
    });

    test('CorpusIndex.build is deterministic', () {
      final a = CorpusIndex.build(corpus);
      final b = CorpusIndex.build(corpus);
      expect(a.entries.map((e) => e.caseId), b.entries.map((e) => e.caseId));
      expect(a.byDoctrine, b.byDoctrine);
      expect(a.byArticle, b.byArticle);
      expect(a.byPrelimsRelevance, b.byPrelimsRelevance);
    });
  });
}
