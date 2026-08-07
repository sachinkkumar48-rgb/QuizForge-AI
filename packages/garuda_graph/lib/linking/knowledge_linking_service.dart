library;

import 'package:garuda_evidence/garuda_evidence.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/knowledge_link.dart';
import '../domain/entities/knowledge_node_ref.dart';
import '../domain/repositories/knowledge_graph_repository.dart';
import '../events/knowledge_graph_events.dart';
import '../infrastructure/in_memory_knowledge_graph_repository.dart';
import '../ontology/knowledge_ontology.dart';
import '../scoring/link_scoring_engine.dart';
import '../validators/link_validation_result.dart';
import '../validators/link_validator_engine.dart';

/// Primary Master Service for deterministic Knowledge Graph linking in Project TITAN.
/// Transforms Evidence Objects into interconnected Knowledge Links using deterministic rules.
class KnowledgeLinkingService {
  final KnowledgeGraphRepository repository;
  final KnowledgeOntology ontology;
  final List<KnowledgeGraphEvent> _emittedEvents = [];

  KnowledgeLinkingService({
    KnowledgeGraphRepository? repository,
    KnowledgeOntology? ontology,
  })  : repository = repository ?? InMemoryKnowledgeGraphRepository(),
        ontology = ontology ?? KnowledgeOntology();

  List<KnowledgeGraphEvent> get emittedEvents => List.unmodifiable(_emittedEvents);

  /// Deterministically suggest links for an EvidenceObject against candidate Knowledge Nodes.
  Future<List<KnowledgeLink>> suggestLinks(
    EvidenceObject evidence, {
    List<KnowledgeNodeRef>? targetCandidates,
  }) async {
    final suggestions = <KnowledgeLink>[];
    final now = DateTime.now();

    final sourceNode = KnowledgeNodeRef(
      id: evidence.id,
      name: evidence.title,
      nodeType: NodeType.evidence,
      category: evidence.category,
    );

    final candidates = targetCandidates ?? await repository.listNodes();

    for (final candidate in candidates) {
      if (candidate.id == evidence.id) continue;

      final scoreRes = LinkScoringEngine.scoreLink(
        evidence: evidence,
        targetNode: candidate,
      );

      // Threshold: suggest links with confidence score >= 0.60
      if (scoreRes.score >= 0.60) {
        KnowledgeRelationshipType relType;

        if (candidate.nodeType == NodeType.article) {
          relType = KnowledgeRelationshipType.interprets;
        } else if (candidate.nodeType == NodeType.caseLaw) {
          relType = KnowledgeRelationshipType.references;
        } else if (candidate.nodeType == NodeType.act) {
          relType = KnowledgeRelationshipType.implements;
        } else if (candidate.nodeType == NodeType.pyq) {
          relType = KnowledgeRelationshipType.testedIn;
        } else {
          relType = KnowledgeRelationshipType.relatedTo;
        }

        final link = KnowledgeLink(
          id: 'link_${evidence.id}_to_${candidate.id}',
          sourceObject: sourceNode,
          targetObject: candidate,
          relationshipType: relType,
          confidenceScore: scoreRes.score,
          createdAt: now,
          updatedAt: now,
          status: LinkStatus.linkReviewPending, // Mandatory Editorial Review Pending
          evidenceReferences: [evidence.originalUrl],
          reason: scoreRes.primaryReason,
        );

        final valRes = await LinkValidatorEngine.validateLink(link, repository: repository);
        if (valRes.isValid) {
          await repository.saveLink(link);
          suggestions.add(link);

          _emittedEvents.add(LinkSuggested(
            eventId: 'evt_suggest_${link.id}',
            timestamp: now,
            link: link,
          ));
        }
      }
    }

    return suggestions;
  }

  /// Validate a link for integrity, broken nodes, duplicates, and cycles.
  Future<LinkValidationResult> validateLinks(KnowledgeLink link) async {
    return await LinkValidatorEngine.validateLink(link, repository: repository);
  }

  /// Approve a pending Knowledge Link.
  Future<KnowledgeLink?> approveLink(
    String linkId, {
    required String reviewer,
  }) async {
    final link = await repository.findLinkById(linkId);
    if (link == null) return null;

    final now = DateTime.now();
    final updated = link.copyWith(
      status: LinkStatus.approved,
      updatedAt: now,
    );

    await repository.updateLink(updated);

    _emittedEvents.add(LinkApproved(
      eventId: 'evt_appr_${link.id}',
      timestamp: now,
      linkId: link.id,
      reviewer: reviewer,
    ));

    _emittedEvents.add(KnowledgeGraphUpdated(
      eventId: 'evt_upd_${link.id}',
      timestamp: now,
      nodeOrLinkId: link.id,
      updateType: 'LINK_APPROVED',
    ));

    return updated;
  }

  /// Reject a pending Knowledge Link.
  Future<KnowledgeLink?> rejectLink(
    String linkId, {
    required String reviewer,
    required String reason,
  }) async {
    final link = await repository.findLinkById(linkId);
    if (link == null) return null;

    final now = DateTime.now();
    final updated = link.copyWith(
      status: LinkStatus.rejected,
      updatedAt: now,
      reason: reason,
    );

    await repository.updateLink(updated);

    _emittedEvents.add(LinkRejected(
      eventId: 'evt_rej_${link.id}',
      timestamp: now,
      linkId: link.id,
      reviewer: reviewer,
      reason: reason,
    ));

    return updated;
  }

  /// Find all related links connected to a node (incoming or outgoing).
  Future<List<KnowledgeLink>> findRelated(String nodeId) async {
    return await repository.findLinksByNode(nodeId);
  }

  /// Find incoming links targeting a node.
  Future<List<KnowledgeLink>> findIncoming(String nodeId) async {
    return await repository.searchLinks(targetId: nodeId);
  }

  /// Find outgoing links originating from a node.
  Future<List<KnowledgeLink>> findOutgoing(String nodeId) async {
    return await repository.searchLinks(sourceId: nodeId);
  }

  /// Find neighbouring nodes directly connected via links.
  Future<List<KnowledgeNodeRef>> findNeighbours(String nodeId) async {
    final links = await findRelated(nodeId);
    final neighbours = <KnowledgeNodeRef>[];

    for (final l in links) {
      if (l.sourceObject.id == nodeId) {
        neighbours.add(l.targetObject);
      } else {
        neighbours.add(l.sourceObject);
      }
    }
    return neighbours;
  }
}
