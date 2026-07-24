import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('KnowledgeRelationship Entity Tests', () {
    final now = DateTime.parse('2026-07-22T12:00:00Z');

    KnowledgeRelationship createSampleRelationship({
      String relationshipId = 'rel_001',
      String sourceKnowledgeId = 'cko_article_10',
      String targetKnowledgeId = 'cko_pyq_2025_q1',
      RelationshipType relationshipType = RelationshipType.appearedIn,
      double confidence = 0.95,
      Map<String, dynamic> metadata = const {'examYear': 2025},
      DateTime? createdAt,
    }) {
      return KnowledgeRelationship(
        relationshipId: relationshipId,
        sourceKnowledgeId: sourceKnowledgeId,
        targetKnowledgeId: targetKnowledgeId,
        relationshipType: relationshipType,
        confidence: confidence,
        metadata: metadata,
        createdAt: createdAt ?? now,
      );
    }

    test('initializes with correct properties', () {
      final rel = createSampleRelationship();

      expect(rel.relationshipId, equals('rel_001'));
      expect(rel.sourceKnowledgeId, equals('cko_article_10'));
      expect(rel.targetKnowledgeId, equals('cko_pyq_2025_q1'));
      expect(rel.relationshipType, equals(RelationshipType.appearedIn));
      expect(rel.confidence, equals(0.95));
      expect(rel.metadata, equals({'examYear': 2025}));
      expect(rel.createdAt, equals(now));
    });

    test('throws assertion error for self-referential relationship', () {
      expect(
        () => KnowledgeRelationship(
          relationshipId: 'rel_err',
          sourceKnowledgeId: 'cko_same',
          targetKnowledgeId: 'cko_same',
          relationshipType: RelationshipType.relatedTo,
        ),
        throwsAssertionError,
      );
    });

    test('throws assertion error for invalid confidence score', () {
      expect(
        () => KnowledgeRelationship(
          relationshipId: 'rel_err',
          sourceKnowledgeId: 'cko_1',
          targetKnowledgeId: 'cko_2',
          relationshipType: RelationshipType.relatedTo,
          confidence: 1.5,
        ),
        throwsAssertionError,
      );
    });

    test('guarantees immutability by returning unmodifiable metadata', () {
      final rel = createSampleRelationship();
      expect(() => rel.metadata['new'] = 'val', throwsUnsupportedError);
    });

    test('value equality evaluates identical relationships as equal', () {
      final rel1 = createSampleRelationship();
      final rel2 = createSampleRelationship();

      expect(rel1, equals(rel2));
      expect(rel1.hashCode, equals(rel2.hashCode));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final original = createSampleRelationship();
      final map = original.toMap();
      final restored = KnowledgeRelationship.fromMap(map);

      expect(restored, equals(original));
    });
  });
}
