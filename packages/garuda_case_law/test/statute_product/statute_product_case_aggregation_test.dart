import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Evidence-bounded case aggregation (TITAN-KO-015.0 P13).
///
/// A case appears in a provision product ONLY when the case's own validated
/// corpus field (`relatedArticles` / `relatedActs` / `sections`) references the
/// provision. Association is never inferred from doctrine membership, graph
/// connectivity, legal similarity, chronology or discovery. Aggregations carry
/// no duplicates, use canonical case IDs, and are deterministically ordered.
void main() {
  final service = syntheticService();
  final corpus = syntheticStatuteCorpus();

  /// The canonical case IDs a product associates, from the associatedCases
  /// section's source references (chronological order).
  List<String> associatedCaseIds(StatuteKnowledgeProduct p) {
    final s = p.sectionOf(StatuteSectionType.associatedCases)!;
    return [for (final st in s.statements) st.sourceRefs.first];
  }

  group('A. evidence-backed association only', () {
    test('Article 21 aggregates exactly the cases that reference it', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final ids = associatedCaseIds(p).toSet();
      expect(ids, {'ALPHA', 'BETA', 'DELTA'});
      // Cases that do NOT reference Article 21 are excluded even though they
      // are corpus members or doctrine-linked.
      expect(ids.contains('GAMMA'), isFalse);
      expect(ids.contains('EPSILON'), isFalse);
      expect(ids.contains('ZETA'), isFalse);
    });

    test('Article 100 aggregates ALPHA and GAMMA only', () {
      final p = service.build(ProvisionType.article, 'Article 100')!;
      expect(associatedCaseIds(p).toSet(), {'ALPHA', 'GAMMA'});
    });

    test('an act aggregates only cases referencing that act', () {
      final p = service.build(
        ProvisionType.act,
        'Representation of the People Act, 1951',
      )!;
      expect(associatedCaseIds(p).toSet(), {'ALPHA'});
    });

    test('a section aggregates only cases referencing that section', () {
      final p = service.build(ProvisionType.section, 'Section 154 CrPC')!;
      expect(associatedCaseIds(p).toSet(), {'ALPHA'});
      final q = service.build(ProvisionType.section, 'Section 41 CrPC')!;
      expect(associatedCaseIds(q).toSet(), {'DELTA'});
    });

    test('doctrine membership alone never associates a case', () {
      // GAMMA and EPSILON and ZETA have no Article 21 reference; none appear.
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final ids = associatedCaseIds(p).toSet();
      for (final c in corpus) {
        if (!c.relatedArticles
            .any((r) => CaseSearchNormalizer.normalizeArticle(r) == '21')) {
          expect(ids.contains(c.caseId), isFalse,
              reason: '${c.caseId} does not reference Article 21');
        }
      }
    });
  });

  group('B. no duplicates / canonical IDs', () {
    test('associated cases carry no duplicates', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final ids = associatedCaseIds(p);
      expect(ids.toSet().length, ids.length);
    });

    test('every associated case ID is a canonical corpus ID', () {
      final corpusIds = {for (final c in corpus) c.caseId};
      for (final type in ProvisionType.values) {
        for (final key in service.provisionIds(type)) {
          final p = service.build(type, key)!;
          for (final id in associatedCaseIds(p)) {
            expect(corpusIds.contains(id), isTrue,
                reason: '$id of $key is not a corpus case');
          }
        }
      }
    });
  });

  group('C. deterministic chronological ordering', () {
    test('Article 21 orders cases chronologically', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      expect(
          associatedCaseIds(p), ['DELTA', 'ALPHA', 'BETA']); // 1995, 2000, 2005
    });

    test('Article 100 orders ALPHA before GAMMA', () {
      final p = service.build(ProvisionType.article, 'Article 100')!;
      expect(associatedCaseIds(p), ['ALPHA', 'GAMMA']); // 2000, 2010
    });

    test('chronology is position, never causation', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final chrono = p.sectionOf(StatuteSectionType.chronology)!;
      expect(chrono.textOf('Earliest'), 'Delta v. Union (1995)');
      expect(chrono.textOf('Latest'), 'Beta v. Union (2005)');
      expect(chrono.textOf('Year span'), '1995–2005');
      for (final st in chrono.statements) {
        final hay = '${st.label} ${st.text}'.toLowerCase();
        expect(hay, isNot(contains('evolved')));
        expect(hay, isNot(contains('overruled')));
        expect(hay, isNot(contains('refined')));
        expect(hay, isNot(contains('extended')));
      }
    });
  });
}
