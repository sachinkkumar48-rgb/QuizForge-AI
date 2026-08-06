import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeSerializer', () {
    test('Roundtrip KnowledgeObject JSON serialization', () {
      final original = KnowledgeObject(
        id: const KnowledgeObjectId('OBJ-SER-1'),
        type: KnowledgeObjectType.caseLaw,
        title: 'Kesavananda Bharati v. State of Kerala',
        content: 'Basic structure doctrine established.',
        summary: 'Landmark constitutional law precedent.',
        tags: const [KnowledgeTag('Basic Structure'), KnowledgeTag('Polity')],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial creation',
          author: 'Architect',
          timestamp: DateTime.parse('2026-08-01T12:00:00.000Z'),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.parse('2026-08-01T12:00:00.000Z'),
          updatedAt: DateTime.parse('2026-08-01T12:00:00.000Z'),
          createdBy: 'Architect',
        ),
      );

      final jsonStr = KnowledgeSerializer.serializeObject(original);
      final deserialized = KnowledgeSerializer.deserializeObject(jsonStr);

      expect(deserialized.id, equals(original.id));
      expect(deserialized.type, equals(original.type));
      expect(deserialized.title, equals(original.title));
      expect(deserialized.tags.length, equals(2));
      expect(deserialized.tags.first.name, equals('Basic Structure'));
    });

    test('Roundtrip KnowledgeRelationship JSON serialization', () {
      const rel = KnowledgeRelationship(
        id: 'REL-001',
        sourceId: KnowledgeObjectId('OBJ-1'),
        targetId: KnowledgeObjectId('OBJ-2'),
        type: RelationshipType.interprets,
        description: 'Case interprets constitutional article',
      );

      final jsonStr = KnowledgeSerializer.serializeRelationship(rel);
      final deserialized = KnowledgeSerializer.deserializeRelationship(jsonStr);

      expect(deserialized.id, equals(rel.id));
      expect(deserialized.sourceId, equals(rel.sourceId));
      expect(deserialized.type, equals(RelationshipType.interprets));
    });
  });
}
