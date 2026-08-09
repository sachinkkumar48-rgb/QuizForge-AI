/// Traversal result model for the Precedent & Doctrine Graph
/// (TITAN-KO-015.0 P5).
library;

import 'package:meta/meta.dart';

import 'legal_graph_edge.dart';
import 'legal_graph_node_ref.dart';

/// An ordered walk through the graph — a chain of precedent authorities or a
/// multi-hop path between two nodes. Edges are the evidence-backed steps.
@immutable
class LegalGraphPath {
  /// Nodes visited in order (start → … → end).
  final List<LegalGraphNodeRef> nodes;

  /// Edges traversed between consecutive nodes.
  final List<LegalGraphEdge> edges;

  const LegalGraphPath({required this.nodes, required this.edges})
      : assert(nodes.length == edges.length + 1,
            'a path must have one more node than edges');

  /// Number of hops in the path.
  int get length => edges.length;

  bool get isEmpty => nodes.isEmpty;

  LegalGraphNodeRef? get start => nodes.isEmpty ? null : nodes.first;

  LegalGraphNodeRef? get end => nodes.isEmpty ? null : nodes.last;

  /// The canonical IDs of the nodes, in order.
  List<String> get nodeIds => nodes.map((n) => n.id).toList(growable: false);

  /// The relationship labels traversed, in order.
  List<String> get edgeLabels => edges.map((e) => e.typeLabel).toList(growable: false);

  @override
  String toString() {
    if (edges.isEmpty) return nodeIds.join(' -> ');
    final parts = <String>[nodes.first.id];
    for (var i = 0; i < edges.length; i++) {
      parts.add('${edges[i].typeLabel} ${nodes[i + 1].id}');
    }
    return parts.join(' -> ');
  }
}
