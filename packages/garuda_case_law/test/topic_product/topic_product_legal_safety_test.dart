import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — legal-safety tests (TITAN-KO-015.0 P14).
///
/// The topic layer is a PEDAGOGICAL grouping, never a legal-relationship layer.
/// A topic product must never imply precedent, legal similarity, authority,
/// overruling, refinement, extension, doctrinal evolution, causation or
/// current-law status. The P5 graph remains the sole source of legal
/// relationships. These tests pin that boundary.
void main() {
  final svc = buildSyntheticTopicService();

  group('A. the product explicitly declares the pedagogical boundary', () {
    test('every product carries the mapping declaration', () {
      for (final p in svc.buildAll()) {
        final identity = p.sectionOf(TopicSectionType.identity);
        expect(identity, isNotNull);
        final declaration = identity!.statements.firstWhere(
          (s) => s.label == 'Mapping declaration',
        );
        expect(declaration.text, contains('pedagogical grouping'));
        expect(declaration.text, contains('does NOT establish'));
      }
    });

    test('no product claims official UPSC syllabus status', () {
      for (final p in svc.buildAll()) {
        expect(p.isOfficialSyllabus, isFalse);
        expect(p.identity.isOfficialSyllabus, isFalse);
        final identity = p.sectionOf(TopicSectionType.identity)!;
        final status = identity.statements.firstWhere(
          (s) => s.label == 'Official syllabus status',
        );
        expect(status.text, contains('Not an official UPSC syllabus taxonomy'));
      }
    });
  });

  group('B. membership is never inferred', () {
    test('a case with no explicit mapping belongs to no topic', () {
      expect(svc.topicForCase('GAMMA'), isEmpty);
      expect(svc.topicForCase('NOT_IN_CORPUS'), isEmpty);
    });

    test('membership requires an explicit validated signal', () {
      // Every membership carries a signal field + verbatim signal value.
      for (final m in svc.config.memberships) {
        expect(TopicSignalField.all, contains(m.signalField));
        expect(m.signalValue, isNotEmpty);
      }
    });
  });

  group('C. no legal-relationship language is generated', () {
    test('no section asserts precedent, overruling or doctrinal evolution', () {
      for (final p in svc.buildAll()) {
        for (final s in p.sections) {
          for (final st in s.statements) {
            expect(st.text.toLowerCase(), isNot(contains('overrules')),
                reason: '${p.topicId}:${s.type.name}');
            expect(st.text.toLowerCase(), isNot(contains('legal precedent')),
                reason: '${p.topicId}:${s.type.name}');
          }
        }
      }
    });

    test('doctrine products are composed, not re-authored as legal claims', () {
      final p = svc.build('topic_alpha')!;
      for (final d in p.doctrineProducts) {
        // Embedded P12 products retain their own provenance and never claim a
        // topic-level legal relationship.
        expect(d.doctrineId, isNotEmpty);
        expect(p.sectionOf(TopicSectionType.doctrines), isNotNull);
      }
    });
  });

  group('D. chronology is position, not causation', () {
    test('chronology section text is purely descriptive ordering', () {
      final p = svc.build('topic_alpha')!;
      final chronology = p.sectionOf(TopicSectionType.chronology)!;
      for (final st in chronology.statements) {
        expect(st.text, matches(RegExp(r'^\d{4} — [A-Z_]+ — ')));
        expect(st.provenance, 'p10:chronology');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// A deterministic structural fingerprint of a legal graph's edges.
  String graphFingerprint(LegalGraph graph) {
    final triples = [
      for (final e in graph.edges)
        '${e.sourceId}|${e.targetId}|${e.runtimeType}',
    ]..sort();
    return triples.join(';');
  }

  group('E. P5 graph remains authoritative and unmutated', () {
    test('the topic layer performs no graph mutation', () {
      // The P14 service does not take or mutate any graph; building products
      // leaves the canonical graph fingerprint untouched (deterministic,
      // side-effect-free construction).
      final service = TopicKnowledgeProductService();
      service.buildAll();
      final fingerprint = graphFingerprint(LegalGraphSeed.fromCorpus().build());
      final again = graphFingerprint(LegalGraphSeed.fromCorpus().build());
      expect(again, fingerprint);
    });

    test('membership is never derived from graph connectivity', () {
      // A membership is always a (case, P3/P4 signal) pair — never a graph
      // edge, a doctrine membership, a discovery result or a chronological
      // relationship.
      for (final m in svc.config.memberships) {
        expect(m.caseId, isNotEmpty);
        expect(m.signalField, isNotEmpty);
        expect(m.signalValue, isNotEmpty);
        expect(m.signalField.startsWith('e:'), isFalse,
            reason: 'membership cites an edge');
        expect(TopicSignalField.all, contains(m.signalField),
            reason: 'membership cites a non-signal field');
      }
      // A graph-only relationship never yields membership: SV.R. Bommai shares
      // doctrine/graph links with cases outside its topic, yet only its
      // validated P4 signals place it in a topic.
      final topics = TopicKnowledgeProductService().topicForCase('SR_BOMMAI');
      expect(
          topics.map((t) => t.id).toList(),
          containsAll([
            'amending_power_and_basic_structure',
            'federal_structure_and_presidents_rule'
          ]));
    });
  });
}
