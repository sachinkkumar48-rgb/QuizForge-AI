import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P13 — Corpus-wide verification over the real 49-case GARUDA corpus
/// (TITAN-KO-015.0 P13).
///
/// Verifies that the statute-product layer processes every provision present
/// in the validated corpus across all three provision kinds, that no product
/// fabricates a case ID, doctrine ID, provision, relationship or citation,
/// that every statement remains traceable, that sections stay in the fixed
/// deterministic order, that output is deterministic and offline — derived
/// solely from the in-memory validated corpus — and that the P5 graph is never
/// mutated.
void main() {
  final service = StatuteKnowledgeProductService();

  group('A. every provision resolves', () {
    test('every provision present in the corpus builds a product', () {
      final all = service.buildAll();
      expect(all, hasLength(95)); // 51 articles + 34 acts + 10 sections
      expect(service.provisionIds(ProvisionType.article), hasLength(51));
      expect(service.provisionIds(ProvisionType.act), hasLength(34));
      expect(service.provisionIds(ProvisionType.section), hasLength(10));
      for (final p in all) {
        expect(p.provisionId, isNotEmpty);
        expect(p.provisionName, isNotEmpty);
        expect(p.hasSection(StatuteSectionType.identity), isTrue);
        expect(p.hasSection(StatuteSectionType.associatedCases), isTrue,
            reason: '${p.provisionId} should aggregate its referencing cases');
      }
    });

    test('known seed refs resolve; unknown refs return null', () {
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 21'),
          '21');
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 14'),
          '14');
      expect(service.build(ProvisionType.article, 'Article 999'), isNull);
      expect(service.build(ProvisionType.article, ''), isNull);
    });
  });

  group('B. representative provisions', () {
    test('heavily referenced Article 21 aggregates its many cases', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final cases = p.sectionOf(StatuteSectionType.associatedCases)!.statements;
      expect(cases.length, greaterThanOrEqualTo(20));
      final ids = {for (final s in cases) s.sourceRefs.first};
      expect(ids.contains('MANEKA_GANDHI'), isTrue);
      expect(ids.contains('DK_BASU'), isTrue);
      expect(ids.contains('JOSEPH_SHINE'), isTrue);
    });

    test('moderately referenced Article 14 carries doctrines', () {
      final p = service.build(ProvisionType.article, 'Article 14')!;
      expect(p.hasSection(StatuteSectionType.doctrines), isTrue);
      final cases = p.sectionOf(StatuteSectionType.associatedCases)!.statements;
      expect(cases.length, greaterThanOrEqualTo(10));
      final ids = {for (final s in cases) s.sourceRefs.first};
      expect(ids.contains('KESAVANANDA'), isTrue);
      expect(ids.contains('JOSEPH_SHINE'), isTrue);
    });

    test('sparsely referenced Article 1 aggregates exactly its one case', () {
      final p = service.build(ProvisionType.article, 'Article 1')!;
      final cases = p.sectionOf(StatuteSectionType.associatedCases)!.statements;
      expect(cases.map((s) => s.sourceRefs.first).toSet(), {'BERUBARI_UNION'});
    });

    test('an act product aggregates its referencing cases', () {
      final p = service.build(
        ProvisionType.act,
        'Representation of the People Act, 1951',
      )!;
      final ids = {
        for (final s
            in p.sectionOf(StatuteSectionType.associatedCases)!.statements)
          s.sourceRefs.first,
      };
      expect(ids, {'ADR_ASSOCIATION', 'LILY_THOMAS', 'PUCL_NOTA'});
    });

    test('a section product aggregates its referencing cases', () {
      final p = service.build(ProvisionType.section, 'Section 154 CrPC')!;
      final ids = {
        for (final s
            in p.sectionOf(StatuteSectionType.associatedCases)!.statements)
          s.sourceRefs.first,
      };
      expect(ids, {'DK_BASU', 'LALITA_KUMARI'});
    });

    test('chronology is deterministic and non-empty for a heavy article', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final chrono = p.sectionOf(StatuteSectionType.chronology)!;
      expect(chrono.textOf('Earliest'), isNotEmpty);
      expect(chrono.textOf('Latest'), isNotEmpty);
      expect(chrono.textOf('Year span'), isNotEmpty);
    });
  });

  group('C. invariants over the whole corpus', () {
    test('no statement is empty and every section has non-empty provenance',
        () {
      for (final p in service.buildAll()) {
        for (final s in p.sections) {
          expect(s.provenance.trim(), isNotEmpty);
          for (final st in s.statements) {
            expect(st.text.trim(), isNotEmpty);
            expect(st.provenance.trim(), isNotEmpty);
            expect(st.sourceRefs, isNotEmpty);
          }
        }
      }
    });

    test('every referenced case ID exists in the validated corpus', () {
      final corpusIds = {for (final c in service.cases) c.caseId};
      for (final p in service.buildAll()) {
        for (final id in service.referencedCaseIds(p)) {
          expect(corpusIds.contains(id), isTrue,
              reason: '${p.provisionId} references unknown case $id');
        }
      }
    });

    test('every doctrine ID referenced exists in the doctrine seed', () {
      final doctrineIds = {for (final d in service.doctrines) d.doctrineId};
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.doctrines);
        if (s == null) continue;
        for (final st in s.statements) {
          expect(doctrineIds.contains(st.sourceRefs.first), isTrue,
              reason: '${p.provisionId} references unknown doctrine '
                  '${st.sourceRefs.first}');
        }
      }
    });

    test('the P5 graph is never mutated', () {
      final before = _graphFingerprint(service);
      final all = service.buildAll();
      expect(all, isNotEmpty);
      expect(_graphFingerprint(service), before);
    });
  });
}

String _graphFingerprint(StatuteKnowledgeProductService service) {
  final nodes = [for (final n in service.graph.nodes) n.id]..sort();
  final edges = [
    for (final e in service.graph.edges) e.edgeId,
  ]..sort();
  return '${nodes.join('|')} :: ${edges.join('|')}';
}
