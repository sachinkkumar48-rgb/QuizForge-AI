import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Publication Service', () {
    late KnowledgeRepository repo;
    late KnowledgeAuditTrail auditTrail;
    late KnowledgePublicationService pubService;
    late KnowledgeObject testObject;

    setUp(() async {
      repo = InMemoryKnowledgeRepository();
      auditTrail = KnowledgeAuditTrail();
      pubService = KnowledgePublicationService(repository: repo, auditTrail: auditTrail);

      testObject = KnowledgeObject(
        id: const KnowledgeObjectId('OBJ-PUB-01'),
        type: KnowledgeObjectType.report,
        title: 'Economic Survey Chapter 1',
        content: 'Survey content',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial commit',
          author: 'System',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'System',
        ),
      );

      await repo.create(testObject);
    });

    test('Queues object with initial status draft', () {
      pubService.queueForReview(testObject);
      expect(pubService.getStatus(testObject.id.value), equals(KnowledgeEditorialStatus.draft));
    });

    test('Transitions status through valid workflow (Draft -> Review -> Approved -> Published)', () async {
      pubService.queueForReview(testObject);

      final t1 = await pubService.transitionStatus(
        objectId: testObject.id.value,
        newStatus: KnowledgeEditorialStatus.editorialReview,
      );
      expect(t1, isTrue);
      expect(pubService.getStatus(testObject.id.value), equals(KnowledgeEditorialStatus.editorialReview));

      final t2 = await pubService.transitionStatus(
        objectId: testObject.id.value,
        newStatus: KnowledgeEditorialStatus.approved,
      );
      expect(t2, isTrue);

      final t3 = await pubService.transitionStatus(
        objectId: testObject.id.value,
        newStatus: KnowledgeEditorialStatus.published,
      );
      expect(t3, isTrue);

      // Verify repository updated metadata
      final updatedObj = await repo.findById(testObject.id);
      expect(updatedObj?.metadata.customAttributes['editorialStatus'], equals('published'));
    });

    test('Rejects invalid transition state changes', () async {
      pubService.queueForReview(testObject); // status: draft

      // Try to jump directly from Draft to Published (invalid transition)
      final tInvalid = await pubService.transitionStatus(
        objectId: testObject.id.value,
        newStatus: KnowledgeEditorialStatus.published,
      );

      expect(tInvalid, isFalse);
      expect(pubService.getStatus(testObject.id.value), equals(KnowledgeEditorialStatus.draft));
    });
  });
}
