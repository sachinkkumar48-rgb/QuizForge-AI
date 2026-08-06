import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('InMemoryKnowledgeRepository CRUD and Query operations', () {
    late KnowledgeRepository repo;

    setUp(() {
      repo = InMemoryKnowledgeRepository();
    });

    KnowledgeObject createSampleObject(String idStr, KnowledgeObjectType type) {
      return KnowledgeObject(
        id: KnowledgeObjectId(idStr),
        type: type,
        title: 'Title $idStr',
        content: 'Content for $idStr',
        tags: [KnowledgeTag('Tag-$idStr')],
        relationships: [
          KnowledgeRelationship(
            id: 'REL-$idStr',
            sourceId: KnowledgeObjectId(idStr),
            targetId: const KnowledgeObjectId('OBJ-TARGET'),
            type: RelationshipType.references,
          ),
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Test',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Test',
        ),
      );
    }

    test('Create and FindById', () async {
      final obj = createSampleObject('OBJ-01', KnowledgeObjectType.constitutionArticle);
      await repo.create(obj);

      final fetched = await repo.findById(const KnowledgeObjectId('OBJ-01'));
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Title OBJ-01'));
    });

    test('Update appends version history', () async {
      final obj = createSampleObject('OBJ-02', KnowledgeObjectType.amendment);
      await repo.create(obj);

      final updated = obj.copyWith(
        title: 'Title OBJ-02 Updated',
        currentVersion: KnowledgeVersion(
          versionNumber: 2,
          commitMessage: 'Second version',
          author: 'Tester',
          timestamp: DateTime.now(),
        ),
      );

      await repo.update(updated);

      final history = await repo.versionHistory(const KnowledgeObjectId('OBJ-02'));
      expect(history.length, equals(2));
      expect(history.last.versionNumber, equals(2));
    });

    test('Delete removes object', () async {
      final obj = createSampleObject('OBJ-03', KnowledgeObjectType.act);
      await repo.create(obj);

      final deleted = await repo.delete(const KnowledgeObjectId('OBJ-03'));
      expect(deleted, isTrue);

      final fetched = await repo.findById(const KnowledgeObjectId('OBJ-03'));
      expect(fetched, isNull);
    });

    test('FindByType and FindByTag', () async {
      await repo.create(createSampleObject('OBJ-04', KnowledgeObjectType.pyq));
      await repo.create(createSampleObject('OBJ-05', KnowledgeObjectType.pyq));

      final pyqs = await repo.findByType(KnowledgeObjectType.pyq);
      expect(pyqs.length, equals(2));

      final byTag = await repo.findByTag(const KnowledgeTag('Tag-OBJ-04'));
      expect(byTag.length, equals(1));
      expect(byTag.first.id.value, equals('OBJ-04'));
    });

    test('FindRelated and BulkImport/Export', () async {
      final obj1 = createSampleObject('OBJ-06', KnowledgeObjectType.scheme);
      final obj2 = createSampleObject('OBJ-07', KnowledgeObjectType.institution);

      await repo.bulkImport([obj1, obj2]);

      final exported = await repo.bulkExport();
      expect(exported.length, equals(2));

      final rels = await repo.findRelated(const KnowledgeObjectId('OBJ-06'));
      expect(rels.length, equals(1));
      expect(rels.first.targetId.value, equals('OBJ-TARGET'));
    });
  });
}
