import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Transactions & Rollback Manager', () {
    late KnowledgeRepository repo;
    late KnowledgeEventBus bus;
    late KnowledgeRollbackManager rollbackManager;

    setUp(() {
      repo = InMemoryKnowledgeRepository();
      bus = KnowledgeEventBus();
      rollbackManager = KnowledgeRollbackManager(repo, bus);
    });

    test('Rolls back created object on failure', () async {
      final obj = KnowledgeObject(
        id: const KnowledgeObjectId('TX-OBJ-1'),
        type: KnowledgeObjectType.act,
        title: 'Right to Education Act',
        content: 'RTE Act 2009',
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

      await repo.create(obj);
      expect(await repo.findById(obj.id), isNotNull);

      final tx = KnowledgeTransaction(
        transactionId: 'TX-100',
        targetObject: obj,
        originalState: null,
        startedAt: DateTime.now(),
      );

      rollbackManager.startTransaction(tx);
      await rollbackManager.rollbackTransaction('TX-100', 'Simulated failure');

      expect(await repo.findById(obj.id), isNull);
    });
  });
}
