import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Composition of existing validated capabilities (TITAN-KO-015.0 P13).
///
/// P13 composes P5 (graph edges), P6 (normalization), P8 (evidence registry),
/// P10 (chronology) and P11 (case explanations) — it never re-implements them.
/// These tests pin that the composed sections agree with the underlying
/// services.
void main() {
  final service = syntheticService();

  group('A. P6 normalization is reused', () {
    test('the provision key equals P6 normalizeArticle output', () {
      expect(CaseSearchNormalizer.normalizeArticle('Article 21'), '21');
      expect(
        service.resolveProvisionId(ProvisionType.article, 'Art. 21'),
        CaseSearchNormalizer.normalizeArticle('Art. 21'),
      );
      expect(
        service.resolveProvisionId(ProvisionType.section, 'Section 154 CrPC'),
        CaseSearchNormalizer.normalizeText('Section 154 CrPC'),
      );
    });
  });

  group('B. P5 graph backs precedent relationships', () {
    test('every precedent statement matches a P5 outgoing edge', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.precedentRelationships);
      expect(s, isNotNull);
      for (final st in s!.statements) {
        final edgeId = st.sourceRefs.first;
        // The edge exists in the graph snapshot, verbatim.
        final exists = service.graph.edges.any((e) => e.edgeId == edgeId);
        expect(exists, isTrue, reason: '$edgeId not present in the P5 graph');
      }
    });

    test('doctrine roles agree with P5 case → doctrine edges', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.doctrines)!;
      for (final st in s.statements) {
        final doctrineId = st.sourceRefs.first;
        for (final cid in st.sourceRefs.skip(1)) {
          final roles = {
            for (final e in service.doctrineService.getDoctrinesForCase(cid))
              if (e.targetId == doctrineId) e.typeLabel,
          };
          expect(roles, isNotEmpty,
              reason: 'no P5 edge from $cid to $doctrineId');
        }
      }
    });
  });

  group('C. P10 chronology is reused', () {
    test('the product chronology equals P10 chronologicalAnalysis', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final caseIds = [
        for (final st
            in p.sectionOf(StatuteSectionType.associatedCases)!.statements)
          st.sourceRefs.first,
      ];
      final analysis = service.analysisService.chronologicalAnalysis(caseIds);
      expect(
        [for (final e in analysis.entries) e.caseId],
        caseIds,
        reason: 'product order must equal P10 order',
      );
      final chrono = p.sectionOf(StatuteSectionType.chronology)!;
      expect(chrono.textOf('Earliest'),
          '${analysis.earliest!.caseName} (${analysis.earliest!.year})');
      expect(chrono.textOf('Latest'),
          '${analysis.latest!.caseName} (${analysis.latest!.year})');
    });
  });

  group('D. P11 case explanations are reused', () {
    test('embedded explanations equal CaseExplanationService.explain', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final explanations = p.caseExplanations;
      expect(explanations, isNotEmpty);
      for (final ex in explanations) {
        final direct = service.explanationService.explain(ex.caseId);
        expect(direct, isNotNull);
        expect(ex, direct);
      }
    });

    test('explanation order matches the associated-case order', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final caseIds = [
        for (final st
            in p.sectionOf(StatuteSectionType.associatedCases)!.statements)
          st.sourceRefs.first,
      ];
      expect([for (final ex in p.caseExplanations) ex.caseId], caseIds);
    });
  });

  group('E. P8 evidence registry is reused', () {
    test('evidence labels come from EvidenceEntry resolution', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.evidence)!;
      for (final st in s.statements) {
        if (!st.label.startsWith('Evidence — ')) continue;
        final evidenceId = st.sourceRefs.last;
        final entry = EvidenceEntry.fromId(evidenceId);
        expect(st.text, entry.verified ? 'Official court record' : anything);
        expect(st.provenance, 'corpus:evidenceIds');
      }
    });
  });
}
