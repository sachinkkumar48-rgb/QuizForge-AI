import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P5 analytics — every metric derived from the actual graph, not hard-coded
/// (TITAN-KO-015.0 P5).
void main() {
  final graph = LegalGraphSeed.fromCorpus().build();
  final report = LegalGraphAnalytics.compute(graph);

  group('Graph size', () {
    test('node and edge totals are derived from the corpus', () {
      expect(report.totalNodes, 69);
      expect(report.totalEdges, 125);
      expect(report.caseCount, 49);
      expect(report.doctrineCount, 20);
      expect(report.caseCaseEdges, 106);
      expect(report.caseDoctrineEdges, 19);
      expect(report.caseCaseEdges + report.caseDoctrineEdges,
          report.totalEdges);
    });

    test('relationship-type distribution sums to the edge count', () {
      final sum = report.relationshipTypeDistribution.values
          .fold<int>(0, (a, b) => a + b);
      expect(sum, report.totalEdges);
    });

    test('precedent-type distribution is derived from corpus data', () {
      expect(report.precedentTypeDistribution['followed'], 18);
      expect(report.precedentTypeDistribution['overruled'], 5);
      expect(report.precedentTypeDistribution['distinguished'], 4);
      expect(report.precedentTypeDistribution['related'], 79);
    });

    test('doctrine-type distribution reflects the evidence-backed roles', () {
      expect(report.doctrineTypeDistribution['establishes'], 5);
      expect(report.doctrineTypeDistribution['applies'], 7);
      expect(report.doctrineTypeDistribution['expands'], 1);
      expect(report.doctrineTypeDistribution['follows'], 1);
      expect(report.doctrineTypeDistribution['engages'], 5);
    });
  });

  group('Connectivity', () {
    test('most connected cases are sorted by descending degree', () {
      expect(report.mostConnectedCases, isNotEmpty);
      for (var i = 1; i < report.mostConnectedCases.length; i++) {
        expect(
            report.mostConnectedCases[i - 1].degree,
            greaterThanOrEqualTo(report.mostConnectedCases[i].degree));
      }
      // The amendment-cluster hubs lead the corpus.
      final topIds = report.mostConnectedCases.map((c) => c.caseId).toSet();
      expect(topIds, contains('KESAVANANDA'));
      expect(topIds, contains('VELLORE_CITIZENS'));
      expect(report.mostConnectedCases.first.degree,
          greaterThanOrEqualTo(report.mostConnectedCases.last.degree));
    });

    test('most connected doctrines lead with BASIC_STRUCTURE', () {
      expect(report.mostConnectedDoctrines, isNotEmpty);
      expect(report.mostConnectedDoctrines.first.doctrineId,
          'BASIC_STRUCTURE');
      expect(report.mostConnectedDoctrines.first.caseCount, 8);
    });

    test('isolated cases are those with no recorded edge', () {
      expect(report.isolatedCases, contains('OLGA_TELLIS'));
      expect(report.isolatedCases, contains('SUCHITA_SRIVASTAVA'));
      // Every non-isolated case has at least one edge.
      final connected = graph.caseNodes
          .map((n) => n.id)
          .where((id) => !report.isolatedCases.contains(id))
          .toSet();
      for (final id in connected) {
        expect(
            graph.edgesFrom(id, LegalGraphNodeType.caseLaw).isNotEmpty ||
                graph.edgesTo(id, LegalGraphNodeType.caseLaw).isNotEmpty,
            isTrue,
            reason: '$id should not be isolated');
      }
    });

    test('connectivity metrics are consistent', () {
      expect(report.connectivityComponents, greaterThan(0));
      expect(report.connectivityComponents, lessThanOrEqualTo(report.totalNodes));
      expect(report.largestComponentSize, greaterThan(1));
      expect(report.largestComponentSize, lessThanOrEqualTo(report.totalNodes));
    });
  });

  group('Precedent chains', () {
    test('a real precedent chain is detected', () {
      expect(report.longestPrecedentChain, isNotNull);
      expect(report.longestPrecedentChain!.length, greaterThanOrEqualTo(2));
      final nodes = report.longestPrecedentChain!.nodeIds;
      expect(nodes.first, isNotEmpty);
    });

    test('chains are recomputed from the same graph deterministically', () {
      final again = LegalGraphAnalytics.compute(graph);
      expect(again.longestPrecedentChain!.nodeIds,
          report.longestPrecedentChain!.nodeIds);
    });
  });
}
