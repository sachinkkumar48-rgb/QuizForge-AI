/// Aggregated Precedent & Doctrine Graph (TITAN-KO-015.0 P5).
///
/// An offline-first, immutable snapshot built from the verified corpus: case
/// nodes from `CaseSeedData`, doctrine nodes from the canonical
/// `garuda_doctrine` records, and edges derived only from evidence-backed
/// corpus fields (see `LegalGraphSeed`). The aggregate owns the adjacency
/// indexes used by traversal, doctrine navigation and analytics.
library;

import 'package:meta/meta.dart';

import 'legal_graph_edge.dart';
import 'legal_graph_node_ref.dart';
import 'legal_graph_node_type.dart';

/// Immutable legal graph aggregate.
@immutable
class LegalGraph {
  final Map<String, LegalGraphNodeRef> _nodesById;
  final List<LegalGraphEdge> _edges;
  final Map<String, List<LegalGraphEdge>> _outgoing;
  final Map<String, List<LegalGraphEdge>> _incoming;
  final Map<String, List<LegalGraphEdge>> _byTypeLabel;

  /// Number of unique (source, type, target) edges in the graph.
  final int edgeCount;

  /// Number of unique (source, type, target) triples that were rejected as
  /// duplicate edges at construction.
  final int duplicateEdgesRejected;

  /// Number of self-loop triples rejected at construction.
  final int selfLoopsRejected;

  const LegalGraph._({
    required Map<String, LegalGraphNodeRef> nodesById,
    required List<LegalGraphEdge> edges,
    required Map<String, List<LegalGraphEdge>> outgoing,
    required Map<String, List<LegalGraphEdge>> incoming,
    required Map<String, List<LegalGraphEdge>> byTypeLabel,
    required this.edgeCount,
    required this.duplicateEdgesRejected,
    required this.selfLoopsRejected,
  })  : _nodesById = nodesById,
        _edges = edges,
        _outgoing = outgoing,
        _incoming = incoming,
        _byTypeLabel = byTypeLabel;

  /// Builds the aggregate, de-duplicating (source, type, target) triples and
  /// dropping self-loops (a legal edge never connects a node to itself).
  ///
  /// Raw edges that are dropped are counted in [duplicateEdgesRejected] and
  /// [selfLoopsRejected] so integrity is observable, not silently swallowed.
  factory LegalGraph({
    required Iterable<LegalGraphNodeRef> nodes,
    required Iterable<LegalGraphEdge> edges,
  }) {
    final nodesById = <String, LegalGraphNodeRef>{
      for (final n in nodes) n.nodeKey: n,
    };

    final outgoing = <String, List<LegalGraphEdge>>{};
    final incoming = <String, List<LegalGraphEdge>>{};
    final byTypeLabel = <String, List<LegalGraphEdge>>{};
    final seen = <String>{};
    final unique = <LegalGraphEdge>[];
    var dupRejected = 0;
    var selfLoopRejected = 0;

    void index(LegalGraphEdge e) {
      (outgoing[nodeKeyFor(e.sourceId, e.sourceNodeType)] ??= []).add(e);
      (incoming[nodeKeyFor(e.targetId, e.targetNodeType)] ??= []).add(e);
      (byTypeLabel[e.typeLabel] ??= []).add(e);
    }

    for (final e in edges) {
      if (e.sourceId == e.targetId) {
        selfLoopRejected++;
        continue;
      }
      if (!seen.add(e.tripleKey)) {
        dupRejected++;
        continue;
      }
      unique.add(e);
      index(e);
    }

    return LegalGraph._(
      nodesById: nodesById,
      edges: List.unmodifiable(unique),
      outgoing: _freeze(outgoing),
      incoming: _freeze(incoming),
      byTypeLabel: _freeze(byTypeLabel),
      edgeCount: unique.length,
      duplicateEdgesRejected: dupRejected,
      selfLoopsRejected: selfLoopRejected,
    );
  }

  static Map<String, List<LegalGraphEdge>> _freeze(
      Map<String, List<LegalGraphEdge>> m) {
    final result = <String, List<LegalGraphEdge>>{};
    for (final entry in m.entries) {
      result[entry.key] = List<LegalGraphEdge>.unmodifiable(entry.value);
    }
    return Map<String, List<LegalGraphEdge>>.unmodifiable(result);
  }

  // -------------------------------------------------------------------------
  // Node access
  // -------------------------------------------------------------------------

  int get nodeCount => _nodesById.length;

  List<LegalGraphNodeRef> get nodes => List.unmodifiable(_nodesById.values);

  List<LegalGraphNodeRef> get caseNodes => _nodesById.values
      .where((n) => n.nodeType == LegalGraphNodeType.caseLaw)
      .toList(growable: false);

  List<LegalGraphNodeRef> get doctrineNodes => _nodesById.values
      .where((n) => n.nodeType == LegalGraphNodeType.doctrine)
      .toList(growable: false);

  bool hasNode(String id, LegalGraphNodeType nodeType) =>
      _nodesById.containsKey(nodeKeyFor(id, nodeType));

  bool hasCase(String caseId) =>
      _nodesById.containsKey(nodeKeyFor(caseId, LegalGraphNodeType.caseLaw));

  bool hasDoctrine(String doctrineId) =>
      _nodesById.containsKey(nodeKeyFor(doctrineId, LegalGraphNodeType.doctrine));

  LegalGraphNodeRef? nodeFor(String id, LegalGraphNodeType nodeType) =>
      _nodesById[nodeKeyFor(id, nodeType)];

  /// The graph-wide node key for a canonical ID + node type.
  static String nodeKeyFor(String id, LegalGraphNodeType t) =>
      t == LegalGraphNodeType.caseLaw ? 'case:$id' : 'doctrine:$id';

  // -------------------------------------------------------------------------
  // Edge access
  // -------------------------------------------------------------------------

  List<LegalGraphEdge> get edges => List.unmodifiable(_edges);

  /// All edges whose type label matches (e.g. all `followed` edges).
  List<LegalGraphEdge> edgesOfType(String typeLabel) =>
      List.unmodifiable(_byTypeLabel[typeLabel] ?? const []);

  /// Edges that originate from a given node (by canonical ID + node type).
  List<LegalGraphEdge> edgesFrom(String id, LegalGraphNodeType nodeType) =>
      List.unmodifiable(_outgoing[nodeKeyFor(id, nodeType)] ?? const []);

  /// Edges that terminate at a given node (by canonical ID + node type).
  List<LegalGraphEdge> edgesTo(String id, LegalGraphNodeType nodeType) =>
      List.unmodifiable(_incoming[nodeKeyFor(id, nodeType)] ?? const []);

  /// Directed edges from [sourceId] to [targetId] (any type).
  List<LegalGraphEdge> edgesBetween(String sourceId, String targetId,
          {LegalGraphNodeType sourceNodeType = LegalGraphNodeType.caseLaw,
          LegalGraphNodeType targetNodeType = LegalGraphNodeType.caseLaw}) =>
      edgesFrom(sourceId, sourceNodeType)
          .where((e) => e.targetId == targetId &&
              e.targetNodeType == targetNodeType)
          .toList(growable: false);

  /// Whether a (source, type, target) triple exists.
  bool hasEdge(String sourceId, String typeLabel, String targetId) => _edges
      .any((e) =>
          e.sourceId == sourceId &&
          e.typeLabel == typeLabel &&
          e.targetId == targetId);

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'nodes': _nodesById.values.map((n) => n.toJson()).toList(),
        'edges': _edges.map((e) => e.toJson()).toList(),
      };

  factory LegalGraph.fromJson(Map<String, dynamic> json) => LegalGraph(
        nodes: (json['nodes'] as List? ?? const [])
            .map((n) => LegalGraphNodeRef.fromJson(n as Map<String, dynamic>)),
        edges: (json['edges'] as List? ?? const [])
            .map((e) => LegalGraphEdge.fromJson(e as Map<String, dynamic>)),
      );
}
