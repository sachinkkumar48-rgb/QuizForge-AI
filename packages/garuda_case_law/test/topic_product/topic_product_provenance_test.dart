import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — provenance tests (TITAN-KO-015.0 P14).
///
/// Every statement in a topic product must trace to an existing validated
/// source (P3/P4 corpus data, P10 chronology, P11 explanations, P12/P13
/// products, the P14 syllabus configuration, P8 evidence registry). Nothing is
/// presented without a provenance and a source reference.
void main() {
  final svc = buildSyntheticTopicService();

  group('A. statement provenance', () {
    test('every statement carries non-empty provenance and source refs', () {
      for (final p in svc.buildAll()) {
        for (final s in p.sections) {
          for (final st in s.statements) {
            expect(st.provenance.trim(), isNotEmpty,
                reason: '${p.topicId}:${s.type.name}');
            expect(st.sourceRefs, isNotEmpty,
                reason: '${p.topicId}:${s.type.name}');
          }
        }
      }
    });

    test('identity statements trace to the P14 syllabus configuration', () {
      final p = svc.build('topic_alpha')!;
      final identity = p.sectionOf(TopicSectionType.identity)!;
      expect(
        identity.statements.any(
          (s) => s.provenance.startsWith('p14:syllabusConfig'),
        ),
        isTrue,
      );
      expect(
        identity.statements.any(
          (s) =>
              s.label == 'Mapping declaration' &&
              s.text.contains('pedagogical grouping'),
        ),
        isTrue,
      );
    });

    test('member statements trace to P14 mapping and their signal', () {
      final p = svc.build('topic_alpha')!;
      final memberCases = p.sectionOf(TopicSectionType.memberCases)!;
      final alphaStmt = memberCases.statements.firstWhere(
        (s) => s.sourceRefs.contains('ALPHA'),
      );
      expect(alphaStmt.provenance, contains('p14:membership'));
      // The signal that justified the membership is surfaced verbatim.
      expect(alphaStmt.text, contains('p4:mainsThemes'));
      expect(alphaStmt.text, contains('Alpha mains theme'));
    });

    test('UPSC-relevance statements trace to P4 intelligence', () {
      final p = svc.build('topic_alpha')!;
      final relevance = p.sectionOf(TopicSectionType.upscRelevance)!;
      expect(
        relevance.statements.every(
          (s) => s.provenance == 'p4:upscIntelligence.mainsThemes',
        ),
        isTrue,
      );
      expect(
          relevance.statements.any((s) => s.text.contains('Alpha mains theme')),
          isTrue);
    });

    test('doctrine statements trace to the P12 product', () {
      final p = svc.build('topic_alpha')!;
      final doctrines = p.sectionOf(TopicSectionType.doctrines)!;
      expect(
        doctrines.statements.every(
          (s) => s.provenance == 'p12:DoctrineKnowledgeProduct',
        ),
        isTrue,
      );
    });

    test('provision statements trace to the P13 product', () {
      final p = svc.build('topic_alpha')!;
      final provisions = p.sectionOf(TopicSectionType.provisions)!;
      expect(
        provisions.statements.every(
          (s) => s.provenance == 'p13:StatuteKnowledgeProduct',
        ),
        isTrue,
      );
    });
  });

  group('B. section-level provenance aggregation', () {
    test('section.provenance aggregates unique provenance strings', () {
      final p = svc.build('topic_alpha')!;
      final identity = p.sectionOf(TopicSectionType.identity)!;
      expect(identity.provenance, isNotEmpty);
      expect(identity.provenance.split(';').toSet().length,
          identity.provenance.split(';').length);
    });

    test('section.references are unique and sorted', () {
      final p = svc.build('topic_alpha')!;
      final memberCases = p.sectionOf(TopicSectionType.memberCases)!;
      final refs = memberCases.references;
      expect(refs, orderedEquals([...refs]..sort()));
      expect(refs.toSet().length, refs.length);
    });
  });

  group('C. product-level provenance', () {
    test('referencedIds aggregate topic, members, sections and products', () {
      final p = svc.build('topic_alpha')!;
      final ids = p.referencedIds;
      expect(ids, contains('topic_alpha'));
      expect(ids, containsAll(['ALPHA', 'BETA']));
      expect(ids, contains('SYNTH_DOCTRINE'));
      expect(ids, contains('21'));
      expect(ids, orderedEquals([...ids]..sort()));
    });
  });
}
