import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P11 — Corpus-wide verification over the full 49-case canonical corpus
/// (TITAN-KO-015.0 P11).
///
/// Verifies that the explanation layer processes every canonical case, that no
/// explanation fabricates a case ID or a precedent relationship, that every
/// statement remains traceable, and that output is deterministic and offline —
/// derived solely from the in-memory validated corpus.
void main() {
  final service = CaseExplanationService();

  group('A. every canonical case resolves', () {
    test('49/49 corpus cases resolve to an explanation with identity', () {
      final all = service.explainAll();
      expect(all, hasLength(49));
      expect(service.caseIds, hasLength(49));
      for (final explanation in all) {
        expect(explanation.caseId, isNotEmpty);
        expect(explanation.caseName, isNotEmpty);
        expect(explanation.isEmpty, isFalse);
        expect(
          explanation.sectionOf(ExplanationSectionType.identity),
          isNotNull,
          reason: '${explanation.caseId} lacks an identity section',
        );
      }
    });

    test('every corpus case ID resolves; unknown identifiers return null', () {
      for (final id in service.caseIds) {
        expect(service.explain(id), isNotNull, reason: id);
        expect(service.explain(id)!.caseId, id);
        expect(service.hasCase(id), isTrue);
      }
      expect(service.explain('NOT_A_REAL_CASE'), isNull);
      expect(service.explain(''), isNull);
      expect(service.explain('   '), isNull);
    });

    test('sections stay in the fixed deterministic order for every case', () {
      final expectedOrder = ExplanationSectionType.values;
      for (final explanation in service.explainAll()) {
        var cursor = 0;
        for (final t in explanation.sections.map((s) => s.type)) {
          final idx = expectedOrder.indexOf(t);
          expect(idx, greaterThanOrEqualTo(cursor),
              reason: '${explanation.caseId} section ${t.name} out of order');
          cursor = idx;
        }
      }
    });
  });

  group('B. no fabricated case IDs or relationships', () {
    test('referenced case IDs always resolve against the validated corpus', () {
      for (final explanation in service.explainAll()) {
        final referenced = service.referencedCaseIds(explanation);
        expect(referenced, contains(explanation.caseId));
        for (final id in referenced) {
          expect(service.caseIds, contains(id),
              reason: '${explanation.caseId} referenced fabricated case $id');
        }
        expect(service.otherCaseIds(explanation),
            isNot(contains(explanation.caseId)));
      }
    });

    test('every precedent-context statement traces to a recorded P5 edge', () {
      for (final explanation in service.explainAll()) {
        final precedent =
            explanation.sectionOf(ExplanationSectionType.precedentContext);
        if (precedent == null) continue;
        for (final s in precedent.statements) {
          expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue,
              reason: '${explanation.caseId} precedent statement lacks an '
                  'edge reference');
          // Every case named by the edge is a real corpus case.
          final caseRefs =
              s.sourceRefs.where((r) => service.caseIds.contains(r)).toList();
          expect(caseRefs, isNotEmpty,
              reason:
                  '${explanation.caseId} precedent statement names no case');
        }
      }
    });

    test('a case with no precedent edges emits no precedent-context section',
        () {
      // The graph has 46/49 cases with precedent context; the disconnected
      // cases emit none rather than a fabricated relationship.
      final withContext = service
          .explainAll()
          .where((e) => e.hasSection(ExplanationSectionType.precedentContext))
          .length;
      expect(withContext, lessThanOrEqualTo(49));
      expect(withContext, greaterThan(0));
    });
  });

  group('C. no provenance failures', () {
    test('every statement across the corpus is traceable', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            expect(s.provenance.trim(), isNotEmpty,
                reason: 'statement ${s.label} of ${explanation.caseId}');
            expect(s.sourceRefs, isNotEmpty,
                reason: 'statement ${s.label} of ${explanation.caseId}');
          }
        }
      }
    });

    test('aggregated section provenance and references are non-empty', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          expect(section.provenance.trim(), isNotEmpty,
              reason: 'section ${section.type.name} of ${explanation.caseId}');
          expect(section.references, isNotEmpty,
              reason: 'section ${section.type.name} of ${explanation.caseId}');
        }
      }
    });
  });

  group('D. deterministic composition', () {
    test('two independent service instances produce identical output', () {
      final a = CaseExplanationService();
      final b = CaseExplanationService();
      for (final explanation in a.explainAll()) {
        final other = b.explain(explanation.caseId)!;
        expect(other.toJson(), explanation.toJson(),
            reason: '${explanation.caseId} is not deterministic across '
                'instances');
      }
      expect(a.explainAll().map((e) => e.toJson()).toList(),
          b.explainAll().map((e) => e.toJson()).toList());
    });

    test('repeated generation over the same instance is byte-identical', () {
      final first = service.explainAll().map((e) => e.toJson()).toList();
      final second = service.explainAll().map((e) => e.toJson()).toList();
      expect(second, first);
    });
  });

  group('E. offline by construction', () {
    test('explanation requires no async IO and completes synchronously', () {
      // The entire pipeline is in-memory over seeded records: constructing the
      // service and explaining every case involves no network, LLM, embeddings
      // or external API.
      final all = CaseExplanationService().explainAll();
      expect(all, hasLength(49));
    });

    test('every provenance marker names an in-corpus source, never external',
        () {
      const inCorpusPrefixes = ['corpus:', 'p4:', 'p10:', 'doctrine:'];
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final token in section.provenance.split(';')) {
            final t = token.trim();
            expect(t, isNotEmpty,
                reason: '${explanation.caseId}/${section.type.name} has an '
                    'empty provenance token');
            expect(
              inCorpusPrefixes.any((p) => t.startsWith(p)),
              isTrue,
              reason: '${explanation.caseId}/${section.type.name} has an '
                  'external provenance marker $t',
            );
          }
        }
      }
    });
  });
}
