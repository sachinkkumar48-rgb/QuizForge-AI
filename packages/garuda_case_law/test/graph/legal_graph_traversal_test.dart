import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P5 traversal — multi-hop queries, shortest paths, precedent chains and the
/// P4-search integration (TITAN-KO-015.0 P5).
void main() {
  final traversal = LegalGraphTraversalService();

  group('Multi-hop traversal', () {
    test('1-hop neighborhood of KESAVANANDA is evidence-backed', () {
      final neighbors = traversal.neighborsWithinHops(
        'KESAVANANDA',
        maxHops: 1,
      );
      final ids = neighbors.map((n) => n.id).toSet();
      // Directly linked cases + the Basic Structure doctrine node.
      expect(ids, contains('GOLAKNATH'));
      expect(ids, contains('MINERVA_MILLS'));
      expect(ids, contains('IR_COELHO'));
      expect(ids, contains('L_CHANDRA_KUMAR'));
      expect(ids, contains('SHANKARI_PRASAD'));
      expect(ids, contains('BERUBARI_UNION'));
      expect(ids, contains('UNNIKRISHNAN'));
      expect(ids, contains('BASIC_STRUCTURE'));
    });

    test('2-hop neighborhood is a strict superset of the 1-hop set', () {
      final oneHop = traversal
          .neighborsWithinHops('KESAVANANDA', maxHops: 1)
          .map((n) => n.id)
          .toSet();
      final twoHop = traversal
          .neighborsWithinHops('KESAVANANDA', maxHops: 2)
          .map((n) => n.id)
          .toSet();
      expect(twoHop.containsAll(oneHop), isTrue);
      expect(twoHop.length, greaterThan(oneHop.length));
    });

    test('directed traversal does not follow reverse edges', () {
      // L_CHANDRA_KUMAR followed KESAVANANDA. From KESAVANANDA that edge is
      // incoming, so a directed 1-hop walk must not surface L_CHANDRA_KUMAR.
      final directed = traversal.neighborsWithinHops(
        'KESAVANANDA',
        maxHops: 1,
        undirected: false,
      ).map((n) => n.id).toSet();
      expect(directed, isNot(contains('L_CHANDRA_KUMAR')));
      final undirected = traversal.neighborsWithinHops(
        'KESAVANANDA',
        maxHops: 1,
        undirected: true,
      ).map((n) => n.id).toSet();
      expect(undirected, contains('L_CHANDRA_KUMAR'));
    });

    test('related-cases expansion within 2 hops reaches second-degree cases', () {
      final oneHop = traversal
          .relatedCasesWithinHops('MANEKA_GANDHI', maxHops: 1)
          .map((n) => n.id)
          .toSet();
      expect(oneHop, contains('PUTTASWAMY'));
      expect(oneHop, contains('DK_BASU'));
      expect(oneHop, contains('AK_GOPALAN'));
      final twoHop = traversal
          .relatedCasesWithinHops('MANEKA_GANDHI', maxHops: 2)
          .map((n) => n.id)
          .toSet();
      // Via DK_BASU → LALITA_KUMARI / ARNESH_KUMAR.
      expect(twoHop, contains('LALITA_KUMARI'));
      expect(twoHop, contains('ARNESH_KUMAR'));
    });

    test('unknown case yields an empty neighborhood', () {
      expect(traversal.neighborsWithinHops('NO_SUCH_CASE', maxHops: 3), isEmpty);
      expect(traversal.relatedCasesWithinHops('NO_SUCH_CASE', maxHops: 2), isEmpty);
    });
  });

  group('Shortest path', () {
    test('MINERVA_MILLS → GOLAKNATH via KESAVANANDA', () {
      final path = traversal.shortestPath('MINERVA_MILLS', 'GOLAKNATH');
      expect(path, isNotNull);
      expect(path!.nodeIds, ['MINERVA_MILLS', 'KESAVANANDA', 'GOLAKNATH']);
      expect(path.edgeLabels, ['followed', 'overruled']);
      expect(path.length, 2);
    });

    test('a direct edge is a length-1 path', () {
      final path = traversal.shortestPath('KESAVANANDA', 'GOLAKNATH');
      expect(path, isNotNull);
      expect(path!.length, 1);
      expect(path.edgeLabels, ['overruled']);
    });

    test('unreachable nodes yield null', () {
      // OLGA_TELLIS has no recorded edges, so no path exists.
      expect(traversal.shortestPath('OLGA_TELLIS', 'KESAVANANDA'), isNull);
    });
  });

  group('Precedent chains', () {
    test('KESAVANANDA predecessor chain runs through the amendment cases', () {
      final chain = traversal.predecessorChain('KESAVANANDA');
      expect(chain, isNotNull);
      expect(chain!.nodeIds.first, 'KESAVANANDA');
      expect(chain.nodeIds, contains('GOLAKNATH'));
      expect(chain.length, greaterThanOrEqualTo(2));
    });

    test('GOLAKNATH successor chain reaches the cases that overruled it', () {
      final chain = traversal.successorChain('GOLAKNATH');
      expect(chain, isNotNull);
      expect(chain!.nodeIds.first, 'GOLAKNATH');
      expect(chain.nodeIds, contains('KESAVANANDA'));
    });

    test('unknown case yields no chain', () {
      expect(traversal.predecessorChain('NO_SUCH_CASE'), isNull);
      expect(traversal.successorChain('NO_SUCH_CASE'), isNull);
    });
  });

  group('P4 search integration', () {
    test('searchNeighborhood finds the privacy cluster', () {
      final hits = traversal.searchNeighborhood('privacy', maxHops: 1);
      expect(hits, isNotEmpty);
      final puttaswamy = hits.firstWhere((h) => h.caseId == 'PUTTASWAMY');
      expect(puttaswamy.score, greaterThan(0.0));
      expect(puttaswamy.neighborhood.map((n) => n.id), contains('MANEKA_GANDHI'));
    });

    test('a nonsense query returns no hits', () {
      expect(
          traversal.searchNeighborhood('zzz-not-a-real-term-xyz', maxHops: 1),
          isEmpty);
    });
  });
}
