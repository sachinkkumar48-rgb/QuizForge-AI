import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P10 — Legal-safety boundaries (TITAN-KO-015.0 P10).
///
/// P10 must never fabricate citations, never reinterpret a precedent edge as a
/// citation, never infer overruling/refinement/extension from holding
/// differences alone, never emit "legally similar", and never invent evidence.
/// Authoritative graph edges (e.g. `MANEKA_GANDHI overruled AK_GOPALAN`) are
/// surfaced verbatim with their provenance — they are recorded evidence, not an
/// inference.
void main() {
  final service = CrossCaseAnalysisService();

  group('A. precedent relationship is never a citation', () {
    test('a followed edge is exposed as followed, never as cited', () {
      final result = service.compareTwo('MINERVA_MILLS', 'KESAVANANDA');
      final edgeLabels = result.observations
          .where((o) => o.type == StructuralObservationType.graphRelationship)
          .map((o) => o.label)
          .toList();
      expect(edgeLabels, contains('MINERVA_MILLS followed KESAVANANDA'));
      for (final label in edgeLabels) {
        expect(label, isNot(contains('cited')));
        expect(label, isNot(contains('citation')));
        expect(label, isNot(contains('cites')));
      }
    });

    test('the graph has no generic cites relationship anywhere', () {
      // P9 established citation safety because the graph exposes relationship
      // types, not citations. Every relationship type in the corpus is from
      // the P5 vocabulary.
      const p5Vocabulary = {
        'followed',
        'overruled',
        'distinguished',
        'related',
        'affirmed',
        'reversed',
        'applied',
        'expanded',
        'limited',
        'clarified',
        'approved',
      };
      for (final id in service.caseIds) {
        for (final e in [
          ...service.precedentService.outgoingRelationships(id),
          ...service.precedentService.incomingRelationships(id),
        ]) {
          expect(p5Vocabulary, contains(e.typeLabel),
              reason: 'P5 relationship type must stay in the P5 vocabulary');
        }
      }
    });
  });

  group('B. no inferred overruling', () {
    test('different holdings alone never produce an overruling claim', () {
      // MANEKA_GANDHI and KESAVANANDA share articles and differ in holdings but
      // have no authoritative overruling edge between them.
      final result = service.compareTwo('MANEKA_GANDHI', 'KESAVANANDA');
      expect(result.observations, isNotEmpty);
      for (final o in result.observations) {
        expect(o.label.toLowerCase(), isNot(contains('overruled')));
        expect(o.type, isNot(StructuralObservationType.graphRelationship),
            reason: 'no graph edge between MANEKA_GANDHI and KESAVANANDA');
      }
      // The structural differences are still observable.
      final types = result.observations.map((o) => o.type).toSet();
      expect(types, contains(StructuralObservationType.holdingDifference));
    });

    test('an authoritative overruling edge is surfaced verbatim', () {
      final result = service.compareTwo('MANEKA_GANDHI', 'AK_GOPALAN');
      final overruled = result.observations
          .where((o) => o.type == StructuralObservationType.graphRelationship)
          .map((o) => o.label)
          .toList();
      expect(overruled, contains('MANEKA_GANDHI overruled AK_GOPALAN'));
      final edge = result.observations
          .firstWhere((o) => o.label == 'MANEKA_GANDHI overruled AK_GOPALAN');
      expect(edge.provenance, 'corpus:precedentsOverruled');
    });
  });

  group('C. no inferred refinement or extension', () {
    test('refined/refinement never appears in comparison output', () {
      final result =
          service.compareCases(['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA']);
      final json = result.toJson().toString().toLowerCase();
      expect(json, isNot(contains('refined')));
      expect(json, isNot(contains('refinement')));
    });

    test('extended/extension never appears in synthesis output', () {
      final result = service.synthesize(['IR_COELHO', 'MINERVA_MILLS']);
      final json = result.toJson().toString().toLowerCase();
      expect(json, isNot(contains('extended')));
      expect(json, isNot(contains('extension')));
      expect(json, isNot(contains('evolved from')));
    });
  });

  group('D. no unsupported legal conclusions', () {
    test('no legal-similarity or similarity-score claim is emitted', () {
      final result =
          service.compareCases(['MANEKA_GANDHI', 'KESAVANANDA', 'GOLAKNATH']);
      final json = result.toJson().toString().toLowerCase();
      expect(json, isNot(contains('legally similar')));
      expect(json, isNot(contains('similarity score')));
      expect(json, isNot(contains('legally')));
    });

    test('shared attributes are exposed, not turned into similarity verdicts',
        () {
      final result = service.compareTwo('MANEKA_GANDHI', 'KESAVANANDA');
      final articles =
          result.sharedAttributes.map((s) => s.displayValue).toList();
      expect(articles, contains('Article 14'));
      expect(articles, contains('Article 19'));
      for (final s in result.sharedAttributes) {
        expect(s.kind, isA<SharedAttributeKind>());
        expect(s.value, isNotEmpty);
      }
    });
  });

  group('E. no fabricated evidence', () {
    test(
        'every observation and shared attribute carries references and '
        'provenance', () {
      final result = service.compareTwo('MINERVA_MILLS', 'KESAVANANDA');
      for (final o in result.observations) {
        expect(o.references, isNotEmpty);
        expect(o.provenance, isNotEmpty);
      }
      for (final s in result.sharedAttributes) {
        expect(s.provenance, isNotEmpty);
      }
    });

    test('a synthetic pair with no graph produces no invented relationships',
        () {
      final a = syntheticCase(
        caseId: 'SYN_SAFE_A',
        caseName: 'Safe A',
        year: 1990,
        holdings: const ['Holding A'],
        articles: const ['Article 21'],
        evidenceIds: const ['ev_SYN_SAFE_A_official'],
      );
      final b = syntheticCase(
        caseId: 'SYN_SAFE_B',
        caseName: 'Safe B',
        year: 2000,
        holdings: const ['Holding B'],
        articles: const ['Article 21'],
        evidenceIds: const ['ev_SYN_SAFE_B_official'],
      );
      final svc = CrossCaseAnalysisService(cases: [a, b]);
      final result = svc.compareTwo('SYN_SAFE_A', 'SYN_SAFE_B');
      expect(result.sharedAttributes.map((s) => s.value), contains('21'));
      for (final o in result.observations) {
        expect(o.label.toLowerCase(), isNot(contains('overruled')));
        expect(o.label.toLowerCase(), isNot(contains('refined')));
        expect(o.label.toLowerCase(), isNot(contains('extended')));
        expect(o.type, isNot(StructuralObservationType.graphRelationship),
            reason: 'no graph edges exist in the synthetic corpus');
      }
    });
  });
}
