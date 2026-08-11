import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Evidence and provenance traceability (TITAN-KO-015.0 P13).
///
/// Every meaningful statute-product statement must be traceable: it carries
/// non-empty source references and a provenance string naming the validated
/// corpus field, P5 edge, P10 analysis or canonical corpus record that
/// establishes it. No fabricated identifiers may appear, and evidence
/// presentation reuses the P8 `EvidenceEntry` registry resolution.
void main() {
  final service = syntheticService();
  final corpus = syntheticStatuteCorpus();
  final corpusIds = {for (final c in corpus) c.caseId};

  Iterable<StatuteStatement> allStatements() sync* {
    for (final p in service.buildAll()) {
      for (final section in p.sections) {
        yield* section.statements;
      }
    }
  }

  group('A. every statement is traceable', () {
    test('every statement has non-empty provenance and source references', () {
      for (final s in allStatements()) {
        expect(s.provenance.trim(), isNotEmpty, reason: s.label);
        expect(s.sourceRefs, isNotEmpty, reason: s.label);
        for (final r in s.sourceRefs) {
          expect(r.trim(), isNotEmpty, reason: s.label);
        }
      }
    });

    test('every section aggregates a non-empty provenance', () {
      for (final p in service.buildAll()) {
        for (final section in p.sections) {
          expect(section.provenance.trim(), isNotEmpty,
              reason: '${section.type.name} of ${p.provisionId}');
        }
      }
    });

    test('no statement text is empty or a placeholder', () {
      for (final s in allStatements()) {
        expect(s.text.trim(), isNotEmpty, reason: s.label);
        expect(s.text.trim().toLowerCase(), isNot(contains('lorem')));
        expect(s.text.trim().toLowerCase(), isNot(contains('placeholder')));
      }
    });
  });

  group('B. no fabricated identifiers', () {
    test('every referenced case ID resolves to the validated corpus', () {
      for (final p in service.buildAll()) {
        for (final id in service.referencedCaseIds(p)) {
          expect(corpusIds.contains(id), isTrue,
              reason:
                  '$id referenced by ${p.provisionId} is not a corpus case');
        }
      }
    });

    test('the product never emits an invented provision or case key', () {
      final real = StatuteKnowledgeProductService();
      final realCaseIds = {for (final c in real.cases) c.caseId};
      for (final p in real.buildAll()) {
        expect(real.resolveProvisionId(p.provisionType, p.provisionName),
            p.provisionId);
        for (final id in real.referencedCaseIds(p)) {
          expect(realCaseIds.contains(id), isTrue,
              reason: '$id is not a real corpus case');
        }
      }
    });

    test('evidence statements resolve through the P8 registry', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.evidence);
        if (s == null) continue;
        for (final st in s.statements) {
          if (st.label.startsWith('Evidence — ')) {
            final evidenceId = st.sourceRefs.last;
            final entry = EvidenceEntry.fromId(evidenceId);
            expect(entry.evidenceId, evidenceId);
            expect(entry.typeLabel, isNotEmpty);
          }
        }
      }
    });
  });

  group('C. provenance reflects the source layer', () {
    test('associated-case statements trace to the corpus field and key', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.associatedCases)!;
      for (final st in s.statements) {
        expect(st.provenance, 'corpus:relatedArticles|key:21');
      }
    });

    test('doctrine statements trace to P5 edges', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.doctrines)!;
      for (final st in s.statements) {
        expect(st.provenance, 'p5:caseDoctrineEdges');
      }
    });

    test('chronology statements trace to P10', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.chronology)!;
      for (final st in s.statements) {
        expect(st.provenance, 'p10:chronology');
      }
    });
  });
}
