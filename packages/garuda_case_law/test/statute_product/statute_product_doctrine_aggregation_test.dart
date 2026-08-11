import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Conservative, evidence-bounded doctrine aggregation (TITAN-KO-015.0
/// P13).
///
/// A doctrine is included in a provision product ONLY through a validated
/// two-step path: an associated case (itself evidenced by the provision
/// reference) is a recorded P5 member of the doctrine, and the doctrine has a
/// canonical `garuda_doctrine` record. A doctrine is never inferred from an
/// article mention alone; roles are verbatim P5 edge evidence.
void main() {
  final service = syntheticService();

  /// The doctrine IDs a product safely associates (sorted).
  List<String> doctrineIds(StatuteKnowledgeProduct p) {
    final s = p.sectionOf(StatuteSectionType.doctrines);
    if (s == null) return const [];
    return [for (final st in s.statements) st.sourceRefs.first]..sort();
  }

  group('A. safely supported doctrines only', () {
    test('Article 21 associates SYNTH_DOCTRINE and SECOND_DOCTRINE', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      expect(doctrineIds(p), ['SECOND_DOCTRINE', 'SYNTH_DOCTRINE']);
    });

    test('SPARSE_DOCTRINE is never associated (no constituent case)', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      expect(doctrineIds(p).contains('SPARSE_DOCTRINE'), isFalse);
    });

    test('a provision with no doctrine case carries no doctrines section', () {
      // Article 400 is referenced only by ZETA, which has no doctrine
      // membership. The section must be absent, not fabricated.
      final p = service.build(ProvisionType.article, 'Article 400')!;
      expect(p.hasSection(StatuteSectionType.doctrines), isFalse);
    });

    test(
        'a provision referenced by a doctrine case and a non-doctrine case '
        'includes only the doctrine-backed doctrines', () {
      // Article 100: ALPHA (doctrine member) and GAMMA (no doctrine). The
      // doctrine section must reflect only ALPHA's memberships.
      final p = service.build(ProvisionType.article, 'Article 100')!;
      expect(doctrineIds(p), ['SECOND_DOCTRINE', 'SYNTH_DOCTRINE']);
    });
  });

  group('B. roles are verbatim P5 evidence', () {
    test('each doctrine statement carries its P5 role verbatim', () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.doctrines)!;
      final synth = s.statementOf('Synthetic Doctrine')!;
      // Alpha establishes; Beta applies — roles come from P5 edges.
      expect(synth.text, contains('Alpha v. State (establishes)'));
      expect(synth.text, contains('Beta v. Union (applies)'));
      expect(synth.provenance, 'p5:caseDoctrineEdges');
    });

    test('doctrine statements are ordered deterministically by doctrine ID',
        () {
      final p = service.build(ProvisionType.article, 'Article 21')!;
      final s = p.sectionOf(StatuteSectionType.doctrines)!;
      final labels = [for (final st in s.statements) st.label];
      expect(labels, orderedEquals([...labels]..sort()));
    });
  });
}
