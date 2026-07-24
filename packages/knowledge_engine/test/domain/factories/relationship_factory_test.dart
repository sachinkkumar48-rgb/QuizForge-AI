import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('RelationshipFactory Tests', () {
    late RelationshipFactory factory;

    setUp(() {
      factory = RelationshipFactory();
    });

    test('creates valid KnowledgeRelationship with explicit ID', () {
      final rel = factory.createRelationship(
        relationshipId: 'rel_custom_1',
        sourceKnowledgeId: 'cko_book_1',
        targetKnowledgeId: 'cko_note_1',
        relationshipType: RelationshipType.explains,
        confidence: 0.85,
      );

      expect(rel.relationshipId, equals('rel_custom_1'));
      expect(rel.sourceKnowledgeId, equals('cko_book_1'));
      expect(rel.targetKnowledgeId, equals('cko_note_1'));
      expect(rel.relationshipType, equals(RelationshipType.explains));
      expect(rel.confidence, equals(0.85));
    });

    test('generates deterministic relationshipId if omitted', () {
      final rel1 = factory.createRelationship(
        sourceKnowledgeId: 'cko_book_1',
        targetKnowledgeId: 'cko_note_1',
        relationshipType: RelationshipType.explains,
      );
      final rel2 = factory.createRelationship(
        sourceKnowledgeId: 'cko_book_1',
        targetKnowledgeId: 'cko_note_1',
        relationshipType: RelationshipType.explains,
      );

      expect(rel1.relationshipId, startsWith('rel_'));
      expect(rel1.relationshipId, equals(rel2.relationshipId));
    });

    test('throws ArgumentError on empty source or target ID', () {
      expect(
        () => factory.createRelationship(
          sourceKnowledgeId: '',
          targetKnowledgeId: 'cko_2',
          relationshipType: RelationshipType.relatedTo,
        ),
        throwsArgumentError,
      );
      expect(
        () => factory.createRelationship(
          sourceKnowledgeId: 'cko_1',
          targetKnowledgeId: '   ',
          relationshipType: RelationshipType.relatedTo,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on self-referential loop', () {
      expect(
        () => factory.createRelationship(
          sourceKnowledgeId: 'cko_same',
          targetKnowledgeId: 'cko_same',
          relationshipType: RelationshipType.relatedTo,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on out-of-bound confidence scores', () {
      expect(
        () => factory.createRelationship(
          sourceKnowledgeId: 'cko_1',
          targetKnowledgeId: 'cko_2',
          relationshipType: RelationshipType.relatedTo,
          confidence: -0.1,
        ),
        throwsArgumentError,
      );
      expect(
        () => factory.createRelationship(
          sourceKnowledgeId: 'cko_1',
          targetKnowledgeId: 'cko_2',
          relationshipType: RelationshipType.relatedTo,
          confidence: 1.1,
        ),
        throwsArgumentError,
      );
    });
  });
}
