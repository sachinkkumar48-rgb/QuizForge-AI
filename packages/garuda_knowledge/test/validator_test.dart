import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Knowledge Base Integrity Validators', () {
    KnowledgeObject createMockObj({
      required String id,
      KnowledgeObjectType type = KnowledgeObjectType.concept,
      List<KnowledgeRelationship> relationships = const [],
      List<KnowledgeReference> references = const [],
      List<KnowledgeEvidenceReference> evidence = const [],
      List<KnowledgeCitation> citations = const [],
      List<KnowledgeSource> sources = const [],
      int version = 1,
      List<KnowledgeVersion> versionHistory = const [],
    }) {
      return KnowledgeObject(
        id: KnowledgeObjectId(id),
        type: type,
        title: 'Title $id',
        content: 'Content $id',
        relationships: relationships,
        references: references,
        evidenceReferences: evidence,
        citations: citations,
        sources: sources,
        currentVersion: KnowledgeVersion(
          versionNumber: version,
          commitMessage: 'Init',
          author: 'Test',
          timestamp: DateTime.now(),
        ),
        versionHistory: versionHistory,
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Test',
        ),
      );
    }

    test('DuplicateIdValidator flags duplicate IDs', () {
      final val = DuplicateIdValidator();
      final res = val.validate([
        createMockObj(id: 'OBJ-1'),
        createMockObj(id: 'OBJ-1'),
      ]);
      expect(res.isValid, isFalse);
      expect(res.errors.first.code, equals('DUPLICATE_ID'));
    });

    test('CircularReferenceValidator flags relationship cycles', () {
      final val = CircularReferenceValidator();
      final res = val.validate([
        createMockObj(id: 'A', relationships: [
          const KnowledgeRelationship(
            id: 'R1',
            sourceId: KnowledgeObjectId('A'),
            targetId: KnowledgeObjectId('B'),
            type: RelationshipType.dependsOn,
          )
        ]),
        createMockObj(id: 'B', relationships: [
          const KnowledgeRelationship(
            id: 'R2',
            sourceId: KnowledgeObjectId('B'),
            targetId: KnowledgeObjectId('A'),
            type: RelationshipType.dependsOn,
          )
        ]),
      ]);
      expect(res.isValid, isFalse);
      expect(res.errors.first.code, equals('CIRCULAR_REFERENCE'));
    });

    test('BrokenReferenceValidator flags missing target IDs', () {
      final val = BrokenReferenceValidator();
      final res = val.validate([
        createMockObj(id: 'A', references: [
          const KnowledgeReference(
            targetId: KnowledgeObjectId('MISSING_TARGET'),
            label: 'Ref',
          )
        ]),
      ]);
      expect(res.isValid, isFalse);
      expect(res.errors.first.code, equals('BROKEN_REFERENCE'));
    });

    test('MissingEvidenceValidator warns on evidence-required types lacking evidence', () {
      final val = MissingEvidenceValidator();
      final res = val.validate([
        createMockObj(id: 'CASE-1', type: KnowledgeObjectType.caseLaw),
      ]);
      expect(res.isValid, isTrue); // warnings do not make isValid false
      expect(res.warnings.first.code, equals('MISSING_EVIDENCE'));
    });

    test('InvalidRelationshipValidator flags self-referencing relationships', () {
      final val = InvalidRelationshipValidator();
      final res = val.validate([
        createMockObj(id: 'A', relationships: [
          const KnowledgeRelationship(
            id: 'SELF-1',
            sourceId: KnowledgeObjectId('A'),
            targetId: KnowledgeObjectId('A'),
            type: RelationshipType.relatedTo,
          )
        ]),
      ]);
      expect(res.isValid, isFalse);
      expect(res.errors.first.code, equals('INVALID_SELF_RELATIONSHIP'));
    });

    test('InvalidVersionValidator flags invalid version sequence', () {
      final val = InvalidVersionValidator();
      final res = val.validate([
        createMockObj(
          id: 'A',
          version: 1,
          versionHistory: [
            KnowledgeVersion(
              versionNumber: 2,
              commitMessage: 'V2',
              author: 'A',
              timestamp: DateTime.now(),
            )
          ],
        ),
      ]);
      expect(res.isValid, isFalse);
    });

    test('DuplicateRelationshipValidator flags duplicate relationship keys', () {
      final val = DuplicateRelationshipValidator();
      final res = val.validate([
        createMockObj(id: 'A', relationships: [
          const KnowledgeRelationship(
            id: 'R1',
            sourceId: KnowledgeObjectId('A'),
            targetId: KnowledgeObjectId('B'),
            type: RelationshipType.dependsOn,
          ),
          const KnowledgeRelationship(
            id: 'R2',
            sourceId: KnowledgeObjectId('A'),
            targetId: KnowledgeObjectId('B'),
            type: RelationshipType.dependsOn,
          ),
        ]),
      ]);
      expect(res.warnings.first.code, equals('DUPLICATE_RELATIONSHIP'));
    });
  });
}
