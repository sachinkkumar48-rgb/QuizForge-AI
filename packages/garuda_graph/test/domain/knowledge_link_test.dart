import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeLink & Node Ref Domain Entity Tests', () {
    final now = DateTime.now();

    const srcNode = KnowledgeNodeRef(
      id: 'EV-PIB-2026-001',
      name: 'Cabinet approves Green Hydrogen Mission',
      nodeType: NodeType.evidence,
      category: 'Environment',
    );

    const targetNode = KnowledgeNodeRef(
      id: 'Art-48A',
      name: 'Article 48A - Protection of environment',
      nodeType: NodeType.article,
      category: 'Polity',
    );

    test('KnowledgeLink creation, JSON serialization, and equality', () {
      final link = KnowledgeLink(
        id: 'link_001',
        sourceObject: srcNode,
        targetObject: targetNode,
        relationshipType: KnowledgeRelationshipType.interprets,
        confidenceScore: 0.95,
        createdAt: now,
        updatedAt: now,
        status: LinkStatus.linkReviewPending,
        evidenceReferences: const ['https://pib.gov.in/001'],
        reason: 'Article 48A environment interpretation',
      );

      expect(link.id, equals('link_001'));
      expect(link.relationshipType, equals(KnowledgeRelationshipType.interprets));
      expect(link.status, equals(LinkStatus.linkReviewPending));

      final json = link.toJson();
      final restored = KnowledgeLink.fromJson(json);

      expect(restored.id, equals(link.id));
      expect(restored.relationshipType, equals(KnowledgeRelationshipType.interprets));
      expect(restored.sourceObject.id, equals('EV-PIB-2026-001'));
      expect(restored.targetObject.id, equals('Art-48A'));
    });

    test('All 15 KnowledgeRelationshipType enums must be valid', () {
      expect(KnowledgeRelationshipType.values.length, equals(15));
      expect(KnowledgeRelationshipType.values, contains(KnowledgeRelationshipType.interprets));
      expect(KnowledgeRelationshipType.values, contains(KnowledgeRelationshipType.overrules));
      expect(KnowledgeRelationshipType.values, contains(KnowledgeRelationshipType.testedIn));
    });
  });
}
