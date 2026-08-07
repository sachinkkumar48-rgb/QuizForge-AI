import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeGraphEvents Tests', () {
    final now = DateTime.now();

    const srcNode = KnowledgeNodeRef(
      id: 'Node1',
      name: 'Source Node',
      nodeType: NodeType.topic,
    );

    const targetNode = KnowledgeNodeRef(
      id: 'Node2',
      name: 'Target Node',
      nodeType: NodeType.concept,
    );

    final link = KnowledgeLink(
      id: 'link_101',
      sourceObject: srcNode,
      targetObject: targetNode,
      relationshipType: KnowledgeRelationshipType.partOf,
      confidenceScore: 0.88,
      createdAt: now,
      updatedAt: now,
    );

    test('LinkSuggested serialization', () {
      final event = LinkSuggested(
        eventId: 'evt_sug_01',
        timestamp: now,
        link: link,
      );

      final json = event.toJson();
      expect(json['eventId'], equals('evt_sug_01'));
      expect(json['eventType'], equals('LinkSuggested'));
      expect(json['linkId'], equals('link_101'));
      expect(json['sourceId'], equals('Node1'));
      expect(json['targetId'], equals('Node2'));
    });

    test('LinkApproved serialization', () {
      final event = LinkApproved(
        eventId: 'evt_app_01',
        timestamp: now,
        linkId: 'link_101',
        reviewer: 'AdminUser',
      );

      final json = event.toJson();
      expect(json['eventType'], equals('LinkApproved'));
      expect(json['reviewer'], equals('AdminUser'));
    });

    test('LinkRejected serialization', () {
      final event = LinkRejected(
        eventId: 'evt_rej_01',
        timestamp: now,
        linkId: 'link_101',
        reviewer: 'AdminUser',
        reason: 'Low precision',
      );

      final json = event.toJson();
      expect(json['eventType'], equals('LinkRejected'));
      expect(json['reason'], equals('Low precision'));
    });

    test('LinkRemoved serialization', () {
      final event = LinkRemoved(
        eventId: 'evt_rem_01',
        timestamp: now,
        linkId: 'link_101',
        reason: 'Deprecation',
      );

      final json = event.toJson();
      expect(json['eventType'], equals('LinkRemoved'));
    });

    test('KnowledgeGraphUpdated serialization', () {
      final event = KnowledgeGraphUpdated(
        eventId: 'evt_upd_01',
        timestamp: now,
        nodeOrLinkId: 'link_101',
        updateType: 'NODE_ADDED',
      );

      final json = event.toJson();
      expect(json['eventType'], equals('KnowledgeGraphUpdated'));
      expect(json['updateType'], equals('NODE_ADDED'));
    });
  });
}
