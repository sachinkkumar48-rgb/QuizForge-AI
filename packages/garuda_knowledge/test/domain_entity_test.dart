import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Domain Entities & Value Objects', () {
    test('KnowledgeObjectId equality and assertions', () {
      const id1 = KnowledgeObjectId('OBJ-001');
      const id2 = KnowledgeObjectId('OBJ-001');
      const id3 = KnowledgeObjectId('OBJ-002');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1.toString(), equals('OBJ-001'));
      expect(() => KnowledgeObjectId(''), throwsA(isA<AssertionError>()));
    });

    test('KnowledgeObject instantiation and copyWith', () {
      final obj = KnowledgeObject(
        id: const KnowledgeObjectId('OBJ-100'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 14',
        content: 'Equality before law',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'System',
          timestamp: DateTime(2026, 1, 1),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          createdBy: 'DevOps',
        ),
      );

      expect(obj.id.value, equals('OBJ-100'));
      expect(obj.type, equals(KnowledgeObjectType.constitutionArticle));

      final updated = obj.copyWith(title: 'Article 14 - Right to Equality');
      expect(updated.title, equals('Article 14 - Right to Equality'));
      expect(updated.id, equals(obj.id));
    });

    test('KnowledgeObjectType and RelationshipType enum serialization', () {
      expect(
        KnowledgeObjectType.fromJson('constitutionArticle'),
        equals(KnowledgeObjectType.constitutionArticle),
      );
      expect(
        RelationshipType.fromJson('dependsOn'),
        equals(RelationshipType.dependsOn),
      );
    });
  });
}
