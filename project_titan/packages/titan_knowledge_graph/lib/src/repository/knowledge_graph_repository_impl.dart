import '../engine/knowledge_graph_engine.dart';
import '../models/knowledge_edge.dart';
import '../models/knowledge_graph.dart';
import '../models/knowledge_node.dart';
import '../models/knowledge_path.dart';
import 'knowledge_graph_repository.dart';

/// Concrete implementation of [KnowledgeGraphRepository] backed by [KnowledgeGraphEngine].
class KnowledgeGraphRepositoryImpl implements KnowledgeGraphRepository {
  final KnowledgeGraphEngine _engine;
  KnowledgeGraph _activeGraph;

  KnowledgeGraphRepositoryImpl({
    KnowledgeGraphEngine engine = const KnowledgeGraphEngine(),
    KnowledgeGraph? initialGraph,
  })  : _engine = engine,
        _activeGraph = initialGraph ?? _seedUpscKnowledgeGraph();

  @override
  Future<KnowledgeGraph> getGraph() async {
    return _activeGraph;
  }

  @override
  Future<KnowledgeNode?> getNode(String nodeId) async {
    return _activeGraph.getNode(nodeId);
  }

  @override
  Future<List<KnowledgeNode>> traverseBfs(
    String startNodeId, {
    int maxDepth = 3,
  }) async {
    return _engine.bfsTraversal(
      graph: _activeGraph,
      startNodeId: startNodeId,
      maxDepth: maxDepth,
    );
  }

  @override
  Future<List<KnowledgeNode>> findRelatedTopics(
    String rootNodeId, {
    int topN = 5,
  }) async {
    return _engine.rankRelatedTopics(
      graph: _activeGraph,
      rootNodeId: rootNodeId,
      topN: topN,
    );
  }

  @override
  Future<KnowledgePath?> getLearningPath(
    String startNodeId,
    String targetNodeId,
  ) async {
    return _engine.findShortestLearningPath(
      graph: _activeGraph,
      startNodeId: startNodeId,
      targetNodeId: targetNodeId,
    );
  }

  @override
  Future<KnowledgeGraph> addNode(KnowledgeNode node) async {
    final updatedNodes = Map<String, KnowledgeNode>.from(_activeGraph.nodes)
      ..[node.id] = node;
    _activeGraph = _activeGraph.copyWith(nodes: updatedNodes);
    return _activeGraph;
  }

  @override
  Future<KnowledgeGraph> addEdge(KnowledgeEdge edge) async {
    final updatedEdges = List<KnowledgeEdge>.from(_activeGraph.edges)
      ..add(edge);
    _activeGraph = _activeGraph.copyWith(edges: updatedEdges);
    return _activeGraph;
  }

  static KnowledgeGraph _seedUpscKnowledgeGraph() {
    final nodes = <String, KnowledgeNode>{
      'sub_polity': KnowledgeNode(
        id: 'sub_polity',
        title: 'Indian Polity & Governance',
        type: KnowledgeNodeType.subject,
        subjectCategory: 'Polity',
        masteryWeight: 0.75,
      ),
      'top_const': KnowledgeNode(
        id: 'top_const',
        title: 'Constitutional Framework',
        type: KnowledgeNodeType.topic,
        subjectCategory: 'Polity',
        masteryWeight: 0.8,
      ),
      'subtop_fund_rights': KnowledgeNode(
        id: 'subtop_fund_rights',
        title: 'Fundamental Rights (Articles 12-35)',
        type: KnowledgeNodeType.subtopic,
        subjectCategory: 'Polity',
        masteryWeight: 0.65,
      ),
      'concept_art21': KnowledgeNode(
        id: 'concept_art21',
        title: 'Article 21: Right to Life & Personal Liberty',
        type: KnowledgeNodeType.concept,
        subjectCategory: 'Polity',
        masteryWeight: 0.6,
      ),
      'pdf_laxmikanth_ch7': KnowledgeNode(
        id: 'pdf_laxmikanth_ch7',
        title: 'Laxmikanth Chapter 7 - Fundamental Rights.pdf',
        type: KnowledgeNodeType.pdf,
        subjectCategory: 'Polity',
        masteryWeight: 0.9,
      ),
      'pyq_polity_2023_q12': KnowledgeNode(
        id: 'pyq_polity_2023_q12',
        title: 'UPSC Prelims 2023 Q12: Right to Privacy Judgements',
        type: KnowledgeNodeType.pyq,
        subjectCategory: 'Polity',
        masteryWeight: 0.4,
      ),
      'ca_puttaswamy_case': KnowledgeNode(
        id: 'ca_puttaswamy_case',
        title: 'Current Affairs: Puttaswamy Supreme Court Ruling',
        type: KnowledgeNodeType.currentAffairs,
        subjectCategory: 'Polity',
        masteryWeight: 0.7,
      ),
      'notes_art21_summary': KnowledgeNode(
        id: 'notes_art21_summary',
        title: 'Personal Study Notes - Article 21 Judgements',
        type: KnowledgeNodeType.notes,
        subjectCategory: 'Polity',
        masteryWeight: 0.85,
      ),
      'rev_art21_active_recall': KnowledgeNode(
        id: 'rev_art21_active_recall',
        title: 'Active Recall Item: Exceptions to Right to Life',
        type: KnowledgeNodeType.revisionItem,
        subjectCategory: 'Polity',
        masteryWeight: 0.5,
      ),
    };

    final edges = <KnowledgeEdge>[
      KnowledgeEdge(
        id: 'edge_polity_const',
        sourceId: 'sub_polity',
        targetId: 'top_const',
        relationType: KnowledgeRelationType.contains,
        weight: 1.0,
      ),
      KnowledgeEdge(
        id: 'edge_const_fr',
        sourceId: 'top_const',
        targetId: 'subtop_fund_rights',
        relationType: KnowledgeRelationType.contains,
        weight: 1.0,
      ),
      KnowledgeEdge(
        id: 'edge_fr_art21',
        sourceId: 'subtop_fund_rights',
        targetId: 'concept_art21',
        relationType: KnowledgeRelationType.contains,
        weight: 1.0,
      ),
      KnowledgeEdge(
        id: 'edge_pdf_fr',
        sourceId: 'pdf_laxmikanth_ch7',
        targetId: 'subtop_fund_rights',
        relationType: KnowledgeRelationType.derivedFrom,
        weight: 0.9,
      ),
      KnowledgeEdge(
        id: 'edge_pyq_art21',
        sourceId: 'pyq_polity_2023_q12',
        targetId: 'concept_art21',
        relationType: KnowledgeRelationType.assesses,
        weight: 0.95,
      ),
      KnowledgeEdge(
        id: 'edge_ca_art21',
        sourceId: 'ca_puttaswamy_case',
        targetId: 'concept_art21',
        relationType: KnowledgeRelationType.relatedTo,
        weight: 0.85,
      ),
      KnowledgeEdge(
        id: 'edge_notes_art21',
        sourceId: 'notes_art21_summary',
        targetId: 'concept_art21',
        relationType: KnowledgeRelationType.relatedTo,
        weight: 0.9,
      ),
      KnowledgeEdge(
        id: 'edge_rev_art21',
        sourceId: 'rev_art21_active_recall',
        targetId: 'concept_art21',
        relationType: KnowledgeRelationType.assesses,
        weight: 1.0,
      ),
    ];

    return KnowledgeGraph(nodes: nodes, edges: edges);
  }
}
