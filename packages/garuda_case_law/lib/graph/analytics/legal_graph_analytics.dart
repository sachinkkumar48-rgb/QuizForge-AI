/// Analytics over the Precedent & Doctrine Graph (TITAN-KO-015.0 P5).
///
/// Every metric is derived from the actual graph at compute time — nothing is
/// hard-coded. The report answers: size, edge-mix, relationship-type
/// distribution, hub cases/doctrines, isolated nodes, connectivity and the
/// longest evidence-backed precedent chain.
library;

import 'package:meta/meta.dart';

import '../domain/legal_graph.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';
import '../domain/legal_graph_path.dart';
import '../service/legal_graph_traversal_service.dart';

/// A case ranked by connectivity (hub).
@immutable
class ConnectedCase {
  final String caseId;
  final int degree;

  const ConnectedCase({required this.caseId, required this.degree});
}

/// A doctrine ranked by how many cases engage it.
@immutable
class ConnectedDoctrine {
  final String doctrineId;
  final int caseCount;

  const ConnectedDoctrine({required this.doctrineId, required this.caseCount});
}

/// Immutable analytics snapshot of a legal graph.
@immutable
class LegalGraphAnalyticsReport {
  final int totalNodes;
  final int totalEdges;
  final int caseCaseEdges;
  final int caseDoctrineEdges;
  final int caseCount;
  final int doctrineCount;

  /// Edge counts by relationship type (all edges).
  final Map<String, int> relationshipTypeDistribution;

  /// Edge counts by case → case relationship type.
  final Map<String, int> precedentTypeDistribution;

  /// Edge counts by case → doctrine relationship type.
  final Map<String, int> doctrineTypeDistribution;

  final List<ConnectedCase> mostConnectedCases;
  final List<ConnectedDoctrine> mostConnectedDoctrines;

  /// Cases that have no recorded edge of any kind.
  final List<String> isolatedCases;

  /// Number of weakly-connected components in the undirected graph.
  final int connectivityComponents;

  /// Size (node count) of the largest weakly-connected component.
  final int largestComponentSize;

  /// Longest evidence-backed precedent chain (may be null on an empty graph).
  final LegalGraphPath? longestPrecedentChain;

  const LegalGraphAnalyticsReport({
    required this.totalNodes,
    required this.totalEdges,
    required this.caseCaseEdges,
    required this.caseDoctrineEdges,
    required this.caseCount,
    required this.doctrineCount,
    required this.relationshipTypeDistribution,
    required this.precedentTypeDistribution,
    required this.doctrineTypeDistribution,
    required this.mostConnectedCases,
    required this.mostConnectedDoctrines,
    required this.isolatedCases,
    required this.connectivityComponents,
    required this.largestComponentSize,
    required this.longestPrecedentChain,
  });
}

/// Analytics engine over the legal graph.
class LegalGraphAnalytics {
  /// Computes the analytics report from the graph's actual data.
  static LegalGraphAnalyticsReport compute(
    LegalGraph graph, {
    LegalGraphTraversalService? traversal,
  }) {
    final t = traversal ?? LegalGraphTraversalService(graph: graph);

    final caseCaseEdges =
        graph.edges.where((e) => e.isCaseCaseEdge).length;
    final caseDoctrineEdges =
        graph.edges.where((e) => e.isCaseDoctrineEdge).length;

    final typeDistribution = <String, int>{};
    final precedentTypeDistribution = <String, int>{};
    final doctrineTypeDistribution = <String, int>{};
    for (final e in graph.edges) {
      typeDistribution[e.typeLabel] = (typeDistribution[e.typeLabel] ?? 0) + 1;
      if (e.isCaseCaseEdge) {
        precedentTypeDistribution[e.typeLabel] =
            (precedentTypeDistribution[e.typeLabel] ?? 0) + 1;
      } else {
        doctrineTypeDistribution[e.typeLabel] =
            (doctrineTypeDistribution[e.typeLabel] ?? 0) + 1;
      }
    }

    // Degree = all edges touching the node (in + out).
    final caseDegree = <String, int>{};
    for (final c in graph.caseNodes) {
      caseDegree[c.id] = graph
              .edgesFrom(c.id, LegalGraphNodeType.caseLaw)
              .length +
          graph.edgesTo(c.id, LegalGraphNodeType.caseLaw).length;
    }
    final rankedCases = caseDegree.entries.toList()
      ..sort((a, b) {
        final byDegree = b.value.compareTo(a.value);
        return byDegree != 0 ? byDegree : a.key.compareTo(b.key);
      });
    final mostConnectedCases = rankedCases
        .take(5)
        .map((e) => ConnectedCase(caseId: e.key, degree: e.value))
        .toList(growable: false);

    final doctrineDegree = <String, int>{};
    for (final d in graph.doctrineNodes) {
      doctrineDegree[d.id] =
          graph.edgesTo(d.id, LegalGraphNodeType.doctrine).length;
    }
    final rankedDoctrines = doctrineDegree.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final mostConnectedDoctrines = rankedDoctrines
        .take(5)
        .map((e) => ConnectedDoctrine(doctrineId: e.key, caseCount: e.value))
        .toList(growable: false);

    final isolatedCases = caseDegree.entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList()
      ..sort();

    final components = _weakComponents(graph);

    LegalGraphPath? longest;
    for (final c in graph.caseNodes) {
      final chain = t.predecessorChain(c.id);
      if (chain != null &&
          (longest == null || chain.length > longest.length)) {
        longest = chain;
      }
    }

    return LegalGraphAnalyticsReport(
      totalNodes: graph.nodeCount,
      totalEdges: graph.edgeCount,
      caseCaseEdges: caseCaseEdges,
      caseDoctrineEdges: caseDoctrineEdges,
      caseCount: graph.caseNodes.length,
      doctrineCount: graph.doctrineNodes.length,
      relationshipTypeDistribution: Map.unmodifiable(typeDistribution),
      precedentTypeDistribution: Map.unmodifiable(precedentTypeDistribution),
      doctrineTypeDistribution: Map.unmodifiable(doctrineTypeDistribution),
      mostConnectedCases: List.unmodifiable(mostConnectedCases),
      mostConnectedDoctrines: List.unmodifiable(mostConnectedDoctrines),
      isolatedCases: List.unmodifiable(isolatedCases),
      connectivityComponents: components.length,
      largestComponentSize: components.isEmpty
          ? 0
          : components.map((c) => c.length).reduce((a, b) => a > b ? a : b),
      longestPrecedentChain: longest,
    );
  }

  /// Weakly-connected components of the undirected graph (union-find).
  static List<List<LegalGraphNodeRef>> _weakComponents(LegalGraph graph) {
    final parent = <String, String>{};
    for (final n in graph.nodes) {
      parent[n.nodeKey] = n.nodeKey;
    }
    String find(String x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]]!;
        x = parent[x]!;
      }
      return x;
    }

    void union(String a, String b) => parent[find(a)] = find(b);

    for (final e in graph.edges) {
      final srcKey = LegalGraph.nodeKeyFor(e.sourceId, e.sourceNodeType);
      final tgtKey = LegalGraph.nodeKeyFor(e.targetId, e.targetNodeType);
      if (parent.containsKey(srcKey) && parent.containsKey(tgtKey)) {
        union(srcKey, tgtKey);
      }
    }

    final byRoot = <String, List<LegalGraphNodeRef>>{};
    for (final n in graph.nodes) {
      (byRoot[find(n.nodeKey)] ??= []).add(n);
    }
    return byRoot.values.toList(growable: false);
  }
}
