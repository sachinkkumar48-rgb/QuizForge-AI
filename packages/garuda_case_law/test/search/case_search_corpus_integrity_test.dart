import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P6.3 — corpus-wide search integrity (TITAN-KO-015.0 P6).
///
/// Every assertion runs against the real 49-case corpus. Nothing is required
/// to be populated that the corpus does not already carry; everything the
/// corpus carries must be reachable through the search engine.
void main() {
  final engine = CaseSearchEngine();
  final cases = CaseSeedData.cases;

  group('AC. corpus-wide coverage', () {
    test('all 49 cases are indexed exactly once', () {
      expect(engine.indexedCaseCount, cases.length);
      expect(engine.indexedCaseIds,
          cases.map((c) => c.caseId).toSet());
    });

    test('no fabricated records appear in any result surface', () {
      final indexed = engine.indexedCaseIds;
      final results = <CaseSearchResult>[
        ...engine.search(const CaseSearchQuery()),
        ...engine.search(const CaseSearchQuery(term: 'basic structure')),
        ...engine.findByArticle('21'),
        ...engine.findByDoctrine('BASIC_STRUCTURE'),
        ...engine.findByRelationship('KESAVANANDA'),
        ...engine.findByUpscRelevance(CaseSearchUpscDimension.mains),
      ];
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(indexed, contains(r.caseId),
            reason: '${r.caseId} must be an indexed corpus case');
        expect(engine.index.byCaseId(r.caseId), isNotNull);
      }
    });

    test('all searchable aliases are reachable through search', () {
      for (final c in cases) {
        for (final alias in c.aliases) {
          final hits = engine.search(CaseSearchQuery(term: alias));
          expect(hits.map((r) => r.caseId), contains(c.caseId),
              reason: 'alias "$alias" of ${c.caseId} must be searchable');
        }
      }
    });

    test('unique aliases resolve exactly via findExact', () {
      // Some aliases are legitimately shared by two real cases (e.g.
      // "Capitation Fee Case" → UNNIKRISHNAN & MOHINI_JAIN); only aliases
      // unique to one case can resolve as an exact lookup.
      final counts = <String, List<String>>{};
      for (final c in cases) {
        for (final alias in c.aliases) {
          (counts[CaseSearchNormalizer.normalizeText(alias)] ??= [])
              .add(c.caseId);
        }
      }
      for (final c in cases) {
        for (final alias in c.aliases) {
          if (counts[CaseSearchNormalizer.normalizeText(alias)]!.length == 1) {
            expect(engine.findExact(alias)?.caseId, c.caseId,
                reason: 'unique alias "$alias" must resolve exactly to ${c.caseId}');
          }
        }
      }
    });

    test('a shared alias surfaces every owning case', () {
      final hits =
          engine.search(const CaseSearchQuery(term: 'Capitation Fee Case'));
      expect(hits.map((r) => r.caseId),
          containsAll(['UNNIKRISHNAN', 'MOHINI_JAIN']));
    });

    test('all populated Articles are searchable', () {
      for (final c in cases) {
        for (final article in c.relatedArticles) {
          final hits = engine.findByArticle(article);
          expect(hits.map((r) => r.caseId), contains(c.caseId),
              reason: '${c.caseId} must be found for "$article"');
        }
      }
    });

    test('all populated Acts and Sections are searchable', () {
      for (final c in cases) {
        for (final act in [...c.relatedActs, ...c.sections]) {
          final hits = engine.findByAct(act);
          expect(hits.map((r) => r.caseId), contains(c.caseId),
              reason: '${c.caseId} must be found for "$act"');
        }
      }
    });

    test('all populated doctrines are searchable', () {
      for (final c in cases) {
        for (final doctrine in c.doctrines) {
          final hits = engine.findByDoctrine(doctrine);
          expect(hits.map((r) => r.caseId), contains(c.caseId),
              reason: '${c.caseId} must be found for doctrine "$doctrine"');
        }
      }
    });

    test('all populated judges are searchable', () {
      for (final c in cases) {
        for (final judge in c.judges) {
          final hits = engine.findByJudge(judge);
          expect(hits.map((r) => r.caseId), contains(c.caseId),
              reason: '${c.caseId} must be found for judge "$judge"');
        }
      }
    });

    test('all populated UPSC intelligence is searchable per dimension', () {
      for (final dim in CaseSearchUpscDimension.values) {
        final hitIds =
            engine.findByUpscRelevance(dim).map((r) => r.caseId).toSet();
        for (final c in cases) {
          final level = switch (dim) {
            CaseSearchUpscDimension.prelims => c.prelimsRelevance,
            CaseSearchUpscDimension.mains => c.mainsRelevance,
            CaseSearchUpscDimension.essay => c.essayRelevance,
            CaseSearchUpscDimension.interview => c.interviewRelevance,
          };
          if (relevanceRank(level) >= 1) {
            expect(hitIds, contains(c.caseId),
                reason: '${c.caseId} must be searchable on ${dim.name}');
          }
        }
      }
    });

    test('no duplicate case IDs are returned by any search surface', () {
      final surfaces = <List<CaseSearchResult>>[
        engine.search(const CaseSearchQuery()),
        engine.search(const CaseSearchQuery(term: 'rights')),
        engine.findByArticle('21'),
        engine.findByDoctrine('Basic Structure'),
        engine.findByRelationship('KESAVANANDA'),
        engine.findByYearRange(1950, 2022),
        engine.findByUpscRelevance(CaseSearchUpscDimension.mains),
      ];
      for (final results in surfaces) {
        final ids = results.map((r) => r.caseId).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'duplicate case IDs detected: $ids');
      }
    });

    test('P5 relationship discovery remains intact', () {
      final engineFollowers = engine
          .findByRelationship('KESAVANANDA',
              type: PrecedentRelationshipType.followed)
          .map((r) => r.caseId)
          .toSet();
      final p5Followers = engine.precedentService
          .casesFollowing('KESAVANANDA')
          .map((e) => e.sourceId)
          .toSet();
      expect(engineFollowers, p5Followers);
      expect(p5Followers, {'IR_COELHO', 'L_CHANDRA_KUMAR', 'MINERVA_MILLS'});

      // Doctrine navigation through P5 still resolves.
      expect(
          engine.doctrineService
              .getCasesEstablishing('BASIC_STRUCTURE')
              .map((e) => e.sourceId),
          contains('KESAVANANDA'));
    });

    test('every suggestion resolves to indexed cases', () {
      for (final prefix in ['golak', 'khanna', '21', 'basic', 'passports']) {
        final suggestions = engine.suggestions(prefix);
        expect(suggestions, isNotEmpty,
            reason: 'prefix "$prefix" must yield suggestions');
        for (final s in suggestions) {
          expect(s.caseIds, isNotEmpty);
          for (final id in s.caseIds) {
            expect(engine.indexedCaseIds, contains(id),
                reason: 'suggestion "${s.term}" references unknown case $id');
          }
        }
      }
    });
  });
}
