import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P10 — Precedent-chain analysis (TITAN-KO-015.0 P10).
///
/// Chain analysis reuses the P5 `predecessorChain` / `successorChain` paths
/// verbatim, enriched with P4 case intelligence. Relationship types must be
/// preserved exactly and must never be reinterpreted as citations.
void main() {
  final service = CrossCaseAnalysisService();

  group('A. predecessor chain', () {
    final chain = service.precedentChainAnalysis('KESAVANANDA')!;

    test('walks the P5 predecessor path verbatim', () {
      expect(chain.anchorCaseId, 'KESAVANANDA');
      expect(chain.direction, PrecedentChainDirection.predecessor);
      expect(chain.caseIds, ['KESAVANANDA', 'GOLAKNATH', 'SAJJAN_SINGH']);
      expect(chain.length, 2);
    });

    test('relationship types are preserved exactly', () {
      final golaknath = chain.entries[1];
      expect(golaknath.relationshipFromPrevious!.typeLabel, 'overruled');
      expect(golaknath.relationshipFromPrevious!.sourceId, 'KESAVANANDA');
      expect(golaknath.relationshipFromPrevious!.targetId, 'GOLAKNATH');
      expect(golaknath.relationshipFromPrevious!.provenance,
          'corpus:precedentsOverruled');
      expect(golaknath.relationshipFromPrevious!.edgeId,
          'e:KESAVANANDA|overruled|GOLAKNATH');
    });

    test('each entry carries its P4 case intelligence and chronology', () {
      for (final e in chain.entries) {
        expect(e.caseObject.caseId, e.caseId);
        expect(e.holdings, isNotEmpty);
        expect(e.ratios, isNotEmpty);
        expect(e.year, greaterThan(0));
      }
      expect(chain.entries[0].relationshipFromPrevious, isNull,
          reason: 'the anchor has no incoming step');
    });

    test('overruled edges are recorded authoritative evidence, not inference',
        () {
      // The graph itself records these overruled edges; P10 surfaces them
      // verbatim with their provenance — it does not invent them.
      final labels = chain.entries
          .skip(1)
          .map((e) => e.relationshipFromPrevious!.typeLabel);
      expect(labels, everyElement('overruled'));
      for (final e in chain.entries.skip(1)) {
        expect(e.relationshipFromPrevious!.evidenceIds, isNotEmpty);
      }
    });
  });

  group('B. successor chain', () {
    test('walks the P5 successor path verbatim', () {
      final chain = service.precedentChainAnalysis('KESAVANANDA',
          direction: PrecedentChainDirection.successor)!;
      expect(chain.direction, PrecedentChainDirection.successor);
      expect(chain.caseIds, ['KESAVANANDA', 'IR_COELHO']);
      final coelho = chain.entries[1];
      expect(coelho.relationshipFromPrevious!.typeLabel, 'followed');
      expect(coelho.relationshipFromPrevious!.sourceId, 'IR_COELHO');
      expect(coelho.relationshipFromPrevious!.targetId, 'KESAVANANDA');
      expect(coelho.relationshipFromPrevious!.provenance,
          'corpus:precedentsFollowed');
    });
  });

  group('C. chain endpoints', () {
    test('a case at the end of a chain yields a single-node predecessor chain',
        () {
      final chain = service.precedentChainAnalysis('SAJJAN_SINGH')!;
      expect(chain.caseIds, ['SAJJAN_SINGH']);
      expect(chain.length, 0);
      expect(chain.entries.single.relationshipFromPrevious, isNull);
    });

    test('a multi-hop successor chain keeps every edge verbatim', () {
      final chain = service.precedentChainAnalysis('SAJJAN_SINGH',
          direction: PrecedentChainDirection.successor)!;
      expect(chain.caseIds,
          ['SAJJAN_SINGH', 'GOLAKNATH', 'KESAVANANDA', 'IR_COELHO']);
      final labels = chain.entries
          .skip(1)
          .map((e) => e.relationshipFromPrevious!.typeLabel)
          .toList();
      expect(labels, ['overruled', 'overruled', 'followed']);
    });
  });

  group('D. edge cases', () {
    test('unknown cases yield no chain analysis', () {
      expect(service.precedentChainAnalysis('NO_SUCH_CASE'), isNull);
      expect(service.precedentChainAnalysis(''), isNull);
    });

    test('a disconnected case yields a single-node chain, not a crash', () {
      final chain = service.precedentChainAnalysis('OLGA_TELLIS')!;
      expect(chain.caseIds, ['OLGA_TELLIS']);
      expect(chain.length, 0);
    });
  });

  group('E. citation safety', () {
    test('precedent edges are never reported as citations', () {
      final chain = service.precedentChainAnalysis('SAJJAN_SINGH',
          direction: PrecedentChainDirection.successor)!;
      for (final e in chain.entries.skip(1)) {
        final step = e.relationshipFromPrevious!;
        expect(step.typeLabel, isNot(contains('cit')),
            reason: 'no citation vocabulary may be fabricated');
        const p5Vocabulary = {
          'followed',
          'overruled',
          'distinguished',
          'affirmed',
          'applied',
          'expanded',
          'limited',
          'clarified',
          'approved',
          'reversed',
          'related',
        };
        expect(p5Vocabulary, contains(step.typeLabel));
      }
    });

    test('the chain JSON exposes only verbatim P5 relationship types', () {
      const p5Vocabulary = {
        'followed',
        'overruled',
        'distinguished',
        'affirmed',
        'applied',
        'expanded',
        'limited',
        'clarified',
        'approved',
        'reversed',
        'related',
      };
      final typeLabels = <String>[];
      void walk(dynamic node) {
        if (node is Map<String, dynamic>) {
          final label = node['typeLabel'];
          if (label is String) typeLabels.add(label);
          node.values.forEach(walk);
        } else if (node is List) {
          node.forEach(walk);
        }
      }

      walk(service.precedentChainAnalysis('KESAVANANDA')!.toJson());
      expect(typeLabels, isNotEmpty);
      for (final label in typeLabels) {
        expect(p5Vocabulary, contains(label),
            reason: 'no citation vocabulary may be serialized');
      }
    });
  });

  group('F. serialization round-trip', () {
    test('a chain survives toJson/fromJson unchanged', () {
      final chain = service.precedentChainAnalysis('KESAVANANDA',
          direction: PrecedentChainDirection.successor)!;
      final restored = PrecedentChainAnalysis.fromJson(chain.toJson());
      expect(restored.toJson(), chain.toJson());
    });
  });
}
