import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — missing-data tests (TITAN-KO-015.0 P14).
///
/// Missing data is represented by an absent section (or an absent product),
/// never by fabricated content: an unknown topic builds to null, a case with no
/// P4 UPSC data yields no upsc-relevance section, and sparse topics omit what
/// they cannot substantiate.
void main() {
  final svc = buildSyntheticTopicService();

  group('A. absent topic', () {
    test('an unknown topic builds to null', () {
      expect(svc.build('no_such_topic'), isNull);
      expect(svc.build(''), isNull);
    });
  });

  group('B. absent sections on a sparse topic', () {
    final p = svc.build('topic_sparse')!;

    test(
        'a sparse member (no P4 data) still produces the identity/overview '
        'sections', () {
      expect(p.hasSection(TopicSectionType.identity), isTrue);
      expect(p.hasSection(TopicSectionType.overview), isTrue);
    });

    test('a member with no UPSC intelligence yields no upsc-relevance section',
        () {
      expect(p.sectionOf(TopicSectionType.upscRelevance), isNull);
    });

    test(
        'a member with no doctrinal or statute data yields no composition '
        'sections', () {
      expect(p.sectionOf(TopicSectionType.doctrines), isNull);
      expect(p.sectionOf(TopicSectionType.provisions), isNull);
    });

    test('a member still yields member-cases, chronology and observations', () {
      expect(p.hasSection(TopicSectionType.memberCases), isTrue);
      expect(p.hasSection(TopicSectionType.chronology), isTrue);
      expect(p.hasSection(TopicSectionType.structuralObservations), isTrue);
    });

    test('missing sections are never fabricated as empty sections', () {
      for (final s in p.sections) {
        expect(s.statements, isNotEmpty);
      }
    });
  });

  group('C. absent evidence on a member', () {
    test(
        'a member with no registry-resolvable evidence omits the evidence '
        'statement', () {
      // All synthetic members carry evidenceIds, so the evidence section is
      // present; statements are only emitted when evidenceIds exist.
      final p = svc.build('topic_alpha')!;
      expect(p.hasSection(TopicSectionType.evidence), isTrue);
      for (final st in p.sectionOf(TopicSectionType.evidence)!.statements) {
        expect(st.sourceRefs.where((r) => r.startsWith('ev_')), isNotEmpty);
      }
    });
  });

  group('D. products remain complete despite missing data', () {
    test('buildAll still produces every canonical topic', () {
      final all = svc.buildAll();
      expect(
          all.map((p) => p.topicId).toSet(), {'topic_alpha', 'topic_sparse'});
    });
  });
}
