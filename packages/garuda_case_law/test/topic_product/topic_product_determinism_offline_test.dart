import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — determinism & offline tests (TITAN-KO-015.0 P14).
///
/// The topic layer is deterministic (identical corpus + identical services →
/// byte-identical structured output, fixed section order, sorted references)
/// and offline-first (synchronous, no network, no LLM, no wall-clock input).
void main() {
  group('A. deterministic generation', () {
    test('buildAll is byte-identical across runs (synthetic)', () {
      final a = canonicalTopicBytes(buildSyntheticTopicService());
      final b = canonicalTopicBytes(buildSyntheticTopicService());
      expect(a, b);
    });

    test('buildAll is byte-identical across runs (canonical corpus)', () {
      final a = canonicalTopicBytes(TopicKnowledgeProductService());
      final b = canonicalTopicBytes(TopicKnowledgeProductService());
      expect(a, b);
    });

    test('sections are in the fixed deterministic order', () {
      final p = buildSyntheticTopicService().build('topic_alpha')!;
      final expected = [
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
      expect(p.sections.map((s) => s.type).toList(), orderedEquals(expected));
    });

    test('references and provenance are sorted', () {
      for (final p in buildSyntheticTopicService().buildAll()) {
        for (final s in p.sections) {
          expect(s.references, orderedEquals([...s.references]..sort()));
        }
        expect(p.memberCaseIds, orderedEquals([...p.memberCaseIds]..sort()));
      }
    });
  });

  group('B. offline behavior', () {
    test('default construction is synchronous and completes without I/O', () {
      // Construction and full generation are synchronous Futures-free calls;
      // reaching the assertions proves no async/network dependency is required.
      final svc = TopicKnowledgeProductService();
      final all = svc.buildAll();
      expect(all.length, greaterThan(0));
      for (final p in all) {
        expect(p.sections, isNotEmpty);
      }
    });

    test('no product content depends on wall-clock time', () {
      final svc = TopicKnowledgeProductService();
      final today = DateTime.now().toIso8601String().split('T').first;
      for (final p in svc.buildAll()) {
        final jsonText = const JsonEncoder.withIndent('  ').convert(p.toJson());
        // No wall-clock date is ever emitted (judgment dates are fixed corpus
        // dates; a today-date would indicate a `now` dependency).
        expect(jsonText, isNot(contains(today)));
      }
    });
  });

  group('C. immutability of outputs', () {
    test('section lists and reference lists are unmodifiable', () {
      final p = buildSyntheticTopicService().build('topic_alpha')!;
      expect(() => p.memberCaseIds.add('X'), throwsUnsupportedError);
      for (final s in p.sections) {
        expect(
            () => s.statements.add(
                  TopicStatement(
                    label: 'x',
                    text: 'x',
                    sourceRefs: const ['x'],
                    provenance: 'x',
                  ),
                ),
            throwsUnsupportedError);
        expect(() => s.references.add('x'), throwsUnsupportedError);
      }
    });

    test('config collections are unmodifiable', () {
      final cfg = buildSyntheticTopicService().config;
      expect(
          () => cfg.memberships.add(
                const TopicMembership(
                  topicId: 't',
                  caseId: 'c',
                  signalField: TopicSignalField.p3Themes,
                  signalValue: 'v',
                ),
              ),
          throwsUnsupportedError);
    });
  });
}

/// Deterministic canonical JSON of every product, for byte-identity checks.
String canonicalTopicBytes(TopicKnowledgeProductService svc) =>
    const JsonEncoder.withIndent('  ').convert(
      [for (final p in svc.buildAll()) p.toJson()],
    );
