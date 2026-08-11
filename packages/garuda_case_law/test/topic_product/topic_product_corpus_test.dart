import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P14 — corpus-wide verification over the canonical 49-case production corpus
/// (TITAN-KO-015.0 P14).
///
/// The versioned P14 syllabus configuration must validate cleanly against the
/// real corpus: every membership cites a genuinely present P3/P4 signal, every
/// topic area is consistent, nothing is orphaned or duplicated, products are
/// complete and deterministic, and the strict all-members composition rule
/// holds against the real doctrine/provision corpora.
void main() {
  final svc = TopicKnowledgeProductService();
  final validator = TopicMappingValidator(service: svc);

  group('A. corpus-wide mapping validation', () {
    test('the real syllabus configuration validates cleanly', () {
      final r = validator.validate();
      expect(r.isValid, isTrue);
      expect(r.errors, isEmpty);
      expect(r.warnings, isEmpty);
    });

    test(
        'exactly the intended cases are left unmapped (documented, not '
        'fabricated)', () {
      final r = validator.validate();
      final unmapped = r.infos
          .where((i) => i.code == 'unmapped-case')
          .map((i) => i.subject)
          .toSet();
      expect(
        unmapped,
        {'ADM_JABALPUR', 'LILY_THOMAS', 'VINEET_NARAIN', 'LALITA_KUMARI'},
      );
    });
  });

  group('B. product completeness', () {
    test('buildAll produces one product per canonical topic', () {
      final all = svc.buildAll();
      final ids = all.map((p) => p.topicId).toList();
      expect(all.length, 12);
      // Canonical topic IDs, deterministically ordered ascending.
      expect(ids, orderedEquals([...ids]..sort()));
      expect(ids.toSet().length, ids.length);
    });

    test('every product carries the core sections on the real corpus', () {
      for (final p in svc.buildAll()) {
        expect(p.isEmpty, isFalse, reason: p.topicId);
        expect(p.hasSection(TopicSectionType.identity), isTrue,
            reason: p.topicId);
        expect(p.hasSection(TopicSectionType.overview), isTrue,
            reason: p.topicId);
        expect(p.hasSection(TopicSectionType.memberCases), isTrue,
            reason: p.topicId);
        expect(p.hasSection(TopicSectionType.chronology), isTrue,
            reason: p.topicId);
        expect(p.hasSection(TopicSectionType.structuralObservations), isTrue,
            reason: p.topicId);
        expect(p.hasSection(TopicSectionType.upscRelevance), isTrue,
            reason: p.topicId);
      }
    });

    test('every member case is in the corpus and members are unique', () {
      final corpus = {for (final c in svc.cases) c.caseId};
      for (final p in svc.buildAll()) {
        expect(p.memberCaseIds.every(corpus.contains), isTrue,
            reason: p.topicId);
        expect(p.memberCaseIds.toSet().length, p.memberCaseIds.length,
            reason: p.topicId);
      }
    });

    test('one P11 explanation per member case, in member order', () {
      for (final p in svc.buildAll()) {
        expect(p.caseExplanations.map((e) => e.caseId).toList(),
            orderedEquals(p.memberCaseIds));
      }
    });

    test('products validate cleanly', () {
      final r = validator.validateProducts();
      expect(r.isValid, isTrue);
      expect(r.issues, isEmpty);
    });
  });

  group('C. real composition outcomes', () {
    test('the strict all-members rule composes fully-contained doctrines', () {
      final env =
          svc.build('environmental_justice_and_sustainable_development')!;
      final ids = env.doctrineProducts.map((d) => d.doctrineId).toList();
      expect(ids, containsAll(['POLLUTER_PAYS', 'PRECAUTIONARY_PRINCIPLE']));
    });

    test(
        'a doctrine whose member is not UPSC-mapped does not compose '
        '(no invented membership)', () {
      final amending = svc.build('amending_power_and_basic_structure')!;
      final ids = amending.doctrineProducts.map((d) => d.doctrineId).toList();
      // BASIC_STRUCTURE's constituent M_NAGARAJ carries no validated basic-
      // structure signal, so it is not a topic member and the doctrine product
      // is deliberately NOT composed under the all-members rule.
      expect(ids, isNot(contains('BASIC_STRUCTURE')));
    });

    test('a provision composes only when all its associated cases are members',
        () {
      final federal = svc.build('federal_structure_and_presidents_rule')!;
      final keys = federal.statuteProducts.map((s) => s.provisionId).toList();
      expect(keys, containsAll(['163', '174', '356']));
      expect(federal.memberCaseIds,
          containsAll(['NABAM_REBIA', 'SR_BOMMAI', 'STATE_RAJASTHAN_V_UNION']));
    });
  });

  group('D. real-corpus determinism', () {
    test('buildAll is byte-identical across two service instances', () {
      String encode() => const JsonEncoder.withIndent('  ').convert(
            [
              for (final p in TopicKnowledgeProductService().buildAll())
                p.toJson()
            ],
          );
      expect(encode(), encode());
    });

    test('present sections appear in the fixed deterministic order', () {
      const expected = [
        TopicSectionType.identity,
        TopicSectionType.overview,
        TopicSectionType.memberCases,
        TopicSectionType.doctrines,
        TopicSectionType.provisions,
        TopicSectionType.chronology,
        TopicSectionType.structuralObservations,
        TopicSectionType.upscRelevance,
        TopicSectionType.evidence,
      ];
      for (final p in svc.buildAll()) {
        // Sections are emitted in fixed order; a section is simply absent when
        // its evidence is missing (e.g. no fully-contained doctrine).
        final actual = p.sections.map((s) => s.type).toList();
        expect(actual, orderedEquals(expected.where(actual.contains).toList()),
            reason: p.topicId);
      }
    });
  });
}
