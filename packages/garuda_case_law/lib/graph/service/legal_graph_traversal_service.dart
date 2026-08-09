/// Legal graph traversal service (TITAN-KO-015.0 P5).
///
/// Multi-hop queries over the aggregated [LegalGraph]: neighborhood within N
/// hops, related-case expansion, shortest paths, and precedent chains. All
/// traversal stays inside the evidence-backed graph — there is no inference
/// beyond the recorded edges.
///
/// Graph-specific search delegates to the existing P4 Judgment Intelligence
/// search engine (`JudgmentIntelligenceSearchEngine`) and then expands each hit
/// into its graph neighborhood, so search and graph stay one coherent system.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show
        CaseKnowledgeObject,
        CaseSeedData,
        JudgmentIntelligenceSearchEngine,
        JudgmentIntelligenceSearchHit,
        JudgmentIntelligenceSearchQuery,
        LegalGraph,
        LegalGraphEdge,
        LegalGraphNodeRef,
        LegalGraphNodeType,
        LegalGraphPath,
        PrecedentGraphEdge,
        PrecedentRelationshipType;

import '../data/legal_graph_seed.dart';

/// A case matched by the P4 search engine plus its graph neighborhood.
class LegalGraphSearchHit {
  final String caseId;
  final String caseName;
  final double score;
  final List<String> matchedFields;

  /// Nodes reachable from the hit within [maxHops] (excludes the hit itself).
  final List<LegalGraphNodeRef> neighborhood;

  /// Edges traversed to reach [neighborhood].
  final List<LegalGraphEdge> neighborhoodEdges;

  const LegalGraphSearchHit({
    required this.caseId,
    required this.caseName,
    required this.score,
    required this.matchedFields,
    required this.neighborhood,
    required this.neighborhoodEdges,
  });
}

/// Multi-hop traversal and P4-search-integrated queries over the legal graph.
class LegalGraphTraversalService {
  final LegalGraph graph;

  LegalGraphTraversalService({LegalGraph? graph})
      : graph = graph ?? LegalGraphSeed.fromCorpus().build();

  /// The graph snapshot this service reads from.
  LegalGraph get snapshot => graph;

  // -------------------------------------------------------------------------
  // N-hop neighborhood
  // -------------------------------------------------------------------------

  /// Nodes reachable from [nodeId] within [maxHops].
  ///
  /// By default edges are traversed in both directions (undirected), which is
  /// the natural reading of "related within N hops". Set [undirected] to false
  /// to follow only the recorded direction. [edgeTypeFilter] optionally
  /// restricts traversal to specific relationship types.
  List<LegalGraphNodeRef> neighborsWithinHops(
    String nodeId, {
    required int maxHops,
    LegalGraphNodeType nodeType = LegalGraphNodeType.caseLaw,
    bool undirected = true,
    Set<String>? edgeTypeFilter,
  }) {
    if (maxHops < 1 || !graph.hasNode(nodeId, nodeType)) return const [];
    final queue = <(String, int)>[(nodeId, 0)];
    final visited = <String>{nodeId};
    final result = <LegalGraphNodeRef>[];

    while (queue.isNotEmpty) {
      final (current, depth) = queue.removeAt(0);
      if (depth >= maxHops) continue;
      final nextType =
          graph.nodeFor(current, nodeType)?.nodeType ?? nodeType;
      for (final edge
          in _adjacentEdges(current, nextType, undirected: undirected)) {
        if (edgeTypeFilter != null && !edgeTypeFilter.contains(edge.typeLabel)) {
          continue;
        }
        final neighborId =
            edge.sourceId == current ? edge.targetId : edge.sourceId;
        if (visited.add(neighborId)) {
          result.add(_resolveNode(edge, neighborId));
          queue.add((neighborId, depth + 1));
        }
      }
    }
    return result;
  }

  /// Cases related to [caseId] within [maxHops], following only `related`
  /// edges (symmetric by definition).
  List<LegalGraphNodeRef> relatedCasesWithinHops(String caseId,
          {required int maxHops}) =>
      neighborsWithinHops(
        caseId,
        maxHops: maxHops,
        nodeType: LegalGraphNodeType.caseLaw,
        undirected: true,
        edgeTypeFilter: {PrecedentRelationshipType.related.name},
      ).where((n) => n.nodeType == LegalGraphNodeType.caseLaw).toList();

  /// All nodes within [maxHops] of a case through any recorded relationship.
  List<LegalGraphNodeRef> caseNeighborhood(String caseId,
          {required int maxHops}) =>
      neighborsWithinHops(
        caseId,
        maxHops: maxHops,
        nodeType: LegalGraphNodeType.caseLaw,
        undirected: true,
      );

  // -------------------------------------------------------------------------
  // Shortest path
  // -------------------------------------------------------------------------

  /// Shortest directed path from [fromId] to [toId], or null when unreachable.
  ///
  /// Direction follows the recorded edges (source → target).
  LegalGraphPath? shortestPath(
    String fromId,
    String toId, {
    LegalGraphNodeType fromNodeType = LegalGraphNodeType.caseLaw,
    LegalGraphNodeType toNodeType = LegalGraphNodeType.caseLaw,
  }) {
    if (!graph.hasNode(fromId, fromNodeType)) return null;
    if (fromId == toId) {
      return LegalGraphPath(
        nodes: [graph.nodeFor(fromId, fromNodeType)!],
        edges: const [],
      );
    }

    // BFS with parent pointers for path reconstruction.
    final parent = <String, (String, LegalGraphEdge)>{};
    final queue = <(String, LegalGraphNodeType)>[(fromId, fromNodeType)];
    final visited = <String>{fromId};

    while (queue.isNotEmpty) {
      final (current, currentType) = queue.removeAt(0);
      for (final edge in graph.edgesFrom(current, currentType)) {
        final nextId = edge.targetId;
        final nextType = edge.targetNodeType;
        if (!visited.add(nextId)) continue;
        if (graph.nodeFor(nextId, nextType) == null) continue;
        parent[nextId] = (current, edge);
        if (nextId == toId && nextType == toNodeType) {
          return _reconstructPath(
              fromId, fromNodeType, toId, toNodeType, parent);
        }
        queue.add((nextId, nextType));
      }
    }
    return null;
  }

  /// Rebuilds the [LegalGraphPath] from BFS parent pointers (target ← … ← start).
  static LegalGraphPath _reconstructPath(
    String fromId,
    LegalGraphNodeType fromNodeType,
    String toId,
    LegalGraphNodeType toNodeType,
    Map<String, (String, LegalGraphEdge)> parent,
  ) {
    final edgeIds = <LegalGraphEdge>[];
    final nodeIds = <(String, LegalGraphNodeType)>[(toId, toNodeType)];
    var current = toId;
    while (parent.containsKey(current)) {
      final (prev, edge) = parent[current]!;
      edgeIds.add(edge);
      nodeIds.add((prev, edge.sourceNodeType));
      current = prev;
    }
    final orderedNodeIds = nodeIds.reversed.toList(growable: false);
    final orderedEdgeIds = edgeIds.reversed.toList(growable: false);
    return LegalGraphPath(
      nodes: [
        for (final (id, type) in orderedNodeIds)
          LegalGraphNodeRef(
            id: id,
            name: id,
            nodeType: type,
          ),
      ],
      edges: orderedEdgeIds,
    );
  }

  // -------------------------------------------------------------------------
  // Precedent chains
  // -------------------------------------------------------------------------

  /// Relationship types that express a precedent chain (everything except
  /// the symmetric `related` affinity).
  static const Set<PrecedentRelationshipType> _chainTypes = {
    PrecedentRelationshipType.followed,
    PrecedentRelationshipType.overruled,
    PrecedentRelationshipType.distinguished,
    PrecedentRelationshipType.affirmed,
    PrecedentRelationshipType.reversed,
    PrecedentRelationshipType.applied,
    PrecedentRelationshipType.expanded,
    PrecedentRelationshipType.limited,
    PrecedentRelationshipType.clarified,
    PrecedentRelationshipType.approved,
  };

  /// Longest simple chain of precedent authorities rooted at [caseId],
  /// following `followed`-style edges forward (the cases [caseId] relies on,
  /// then the cases those rely on, …). Deterministic (tie-broken).
  LegalGraphPath? predecessorChain(String caseId) {
    if (!graph.hasCase(caseId)) return null;
    final best = _longestSimplePathFrom(
      caseId,
      LegalGraphNodeType.caseLaw,
      forward: true,
    );
    return best;
  }

  /// Longest simple chain of cases that rely on [caseId], walking `followed`-style
  /// edges backward (cases that follow [caseId], then cases that follow those, …).
  LegalGraphPath? successorChain(String caseId) {
    if (!graph.hasCase(caseId)) return null;
    final best = _longestSimplePathFrom(
      caseId,
      LegalGraphNodeType.caseLaw,
      forward: false,
    );
    return best;
  }

  // -------------------------------------------------------------------------
  // P4 search integration
  // -------------------------------------------------------------------------

  /// Runs the P4 Judgment Intelligence search and expands each hit into its
  /// graph neighborhood, returning hits with their [maxHops] neighborhood.
  List<LegalGraphSearchHit> searchNeighborhood(
    String query, {
    int maxHops = 1,
    int? limit,
    List<CaseKnowledgeObject>? cases,
  }) {
    final corpus = cases ?? CaseSeedData.cases;
    final hits = JudgmentIntelligenceSearchEngine.search(
      cases: corpus,
      query: JudgmentIntelligenceSearchQuery(
        keyword: query,
        limit: limit,
      ),
    );
    if (hits.isEmpty) return const [];
    return hits
        .map((hit) => _expandHit(hit, maxHops: maxHops))
        .toList(growable: false);
  }

  LegalGraphSearchHit _expandHit(JudgmentIntelligenceSearchHit hit,
      {required int maxHops}) {
    final neighborhood = neighborsWithinHops(
      hit.caseId,
      maxHops: maxHops,
      nodeType: LegalGraphNodeType.caseLaw,
      undirected: true,
    );
    return LegalGraphSearchHit(
      caseId: hit.caseId,
      caseName: hit.caseName,
      score: hit.score,
      matchedFields: hit.matchedFields,
      neighborhood: neighborhood,
      neighborhoodEdges: _edgesTouching(hit.caseId),
    );
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  List<LegalGraphEdge> _adjacentEdges(String nodeId, LegalGraphNodeType type,
          {required bool undirected}) =>
      undirected
          ? [
              ...graph.edgesFrom(nodeId, type),
              ...graph.edgesTo(nodeId, type),
            ]
          : graph.edgesFrom(nodeId, type);

  List<LegalGraphEdge> _edgesTouching(String nodeId) => [
        ...graph.edgesFrom(nodeId, LegalGraphNodeType.caseLaw),
        ...graph.edgesTo(nodeId, LegalGraphNodeType.caseLaw),
      ];

  LegalGraphNodeRef _resolveNode(LegalGraphEdge edge, String id) =>
      graph.nodeFor(id, edge.sourceId == id ? edge.sourceNodeType : edge.targetNodeType) ??
      LegalGraphNodeRef(
          id: id, name: id, nodeType: LegalGraphNodeType.caseLaw);

  /// Longest simple path over chain edges, in [forward] (outgoing authority
  /// edges) or reverse (incoming) direction, rooted at [startId]. Backtracking
  /// DFS with deterministic ordering; the subgraph is tiny (~28 edges).
  LegalGraphPath? _longestSimplePathFrom(
    String startId,
    LegalGraphNodeType startType, {
    required bool forward,
  }) {
    LegalGraphPath? best;
    final nodesOnPath = <LegalGraphNodeRef>[];
    final edgesOnPath = <LegalGraphEdge>[];
    final visited = <String>{startId};

    nodesOnPath.add(graph.nodeFor(startId, startType)!);

    void dfs(String current) {
      final type = graph.nodeFor(current, startType)?.nodeType ?? startType;
      final edges = forward
          ? graph.edgesFrom(current, type).whereType<PrecedentGraphEdge>()
          : graph.edgesTo(current, type).whereType<PrecedentGraphEdge>();
      final candidates = edges
          .where((e) => _chainTypes.contains(e.type))
          .map((e) =>
              forward ? (e.targetId, e) : (e.sourceId, e))
          .where((c) => !visited.contains(c.$1))
          .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));

      if (candidates.isEmpty) {
        final candidate = LegalGraphPath(
          nodes: List.of(nodesOnPath),
          edges: List.of(edgesOnPath),
        );
        if (best == null || candidate.length > best!.length) {
          best = candidate;
        }
        return;
      }

      for (final (nextId, edge) in candidates) {
        visited.add(nextId);
        nodesOnPath.add(graph.nodeFor(nextId, startType)!);
        edgesOnPath.add(edge);
        dfs(nextId);
        edgesOnPath.removeLast();
        nodesOnPath.removeLast();
        visited.remove(nextId);
      }
    }

    dfs(startId);
    return best;
  }
}
