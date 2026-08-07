import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeLinkingService Integration & Workflow Tests', () {
    late KnowledgeGraphRepository repository;
    late KnowledgeOntology ontology;
    late KnowledgeLinkingService linkingService;
    final now = DateTime.now();

    final evidence = EvidenceObject(
      id: 'EV-PIB-2026-99',
      title: 'Parliament passes DPDP Bill 2023 for Data Protection Article 21',
      sourceName: 'PIB Press Release',
      sourceType: EvidenceSourceType.government,
      authority: const EvidenceAuthority(
        id: 'pib',
        name: 'Press Information Bureau',
        type: EvidenceSourceType.government,
        jurisdiction: 'India',
      ),
      publicationDate: now,
      retrievedDate: now,
      category: 'Governance',
      subject: 'Polity',
      topic: 'Digital Personal Data Protection',
      subtopic: 'Privacy Act',
      keywords: const ['Article 21', 'DPDP Act', 'Data Protection'],
      language: 'en',
      summary: 'Data protection framework under Article 21 rights.',
      originalUrl: 'https://pib.gov.in/dpdp2023',
      knowledgeObjectLinks: const KnowledgeObjectLinks(
        constitutionArticles: ['Art-21'],
        acts: ['DPDP Act 2023'],
      ),
      createdAt: now,
      updatedAt: now,
    );

    const artNode = KnowledgeNodeRef(
      id: 'Art-21',
      name: 'Article 21 Protection of Life and Liberty',
      nodeType: NodeType.article,
      category: 'Polity',
    );

    const actNode = KnowledgeNodeRef(
      id: 'DPDP Act 2023',
      name: 'Digital Personal Data Protection Act',
      nodeType: NodeType.act,
      category: 'Governance',
    );

    setUp(() async {
      repository = InMemoryKnowledgeGraphRepository();
      ontology = KnowledgeOntology();
      linkingService = KnowledgeLinkingService(
        repository: repository,
        ontology: ontology,
      );

      await repository.saveNode(artNode);
      await repository.saveNode(actNode);
    });

    test('suggestLinks should produce pending review links with score >= 0.60', () async {
      final links = await linkingService.suggestLinks(evidence);

      expect(links.length, greaterThanOrEqualTo(1));
      for (final link in links) {
        expect(link.status, equals(LinkStatus.linkReviewPending));
        expect(link.confidenceScore, greaterThanOrEqualTo(0.60));
        expect(link.sourceObject.id, equals(evidence.id));
      }

      expect(linkingService.emittedEvents.any((e) => e is LinkSuggested), isTrue);
    });

    test('approveLink should transition status to approved and emit LinkApproved event', () async {
      final links = await linkingService.suggestLinks(evidence);
      expect(links.isNotEmpty, isTrue);

      final linkId = links.first.id;
      final approvedLink = await linkingService.approveLink(linkId, reviewer: 'EditorChief');

      expect(approvedLink, isNotNull);
      expect(approvedLink!.status, equals(LinkStatus.approved));

      final persisted = await repository.findLinkById(linkId);
      expect(persisted?.status, equals(LinkStatus.approved));

      expect(linkingService.emittedEvents.any((e) => e is LinkApproved), isTrue);
      expect(linkingService.emittedEvents.any((e) => e is KnowledgeGraphUpdated), isTrue);
    });

    test('rejectLink should transition status to rejected and store reason', () async {
      final links = await linkingService.suggestLinks(evidence);
      expect(links.isNotEmpty, isTrue);

      final linkId = links.first.id;
      final rejectedLink = await linkingService.rejectLink(
        linkId,
        reviewer: 'Reviewer2',
        reason: 'Duplicate relation',
      );

      expect(rejectedLink, isNotNull);
      expect(rejectedLink!.status, equals(LinkStatus.rejected));
      expect(rejectedLink.reason, equals('Duplicate relation'));

      expect(linkingService.emittedEvents.any((e) => e is LinkRejected), isTrue);
    });

    test('findNeighbours, findIncoming, findOutgoing graph traversal', () async {
      await linkingService.suggestLinks(evidence);

      final incoming = await linkingService.findIncoming('Art-21');
      expect(incoming.length, greaterThanOrEqualTo(1));

      final outgoing = await linkingService.findOutgoing(evidence.id);
      expect(outgoing.length, greaterThanOrEqualTo(1));

      final neighbours = await linkingService.findNeighbours(evidence.id);
      expect(neighbours.isNotEmpty, isTrue);
    });
  });
}
