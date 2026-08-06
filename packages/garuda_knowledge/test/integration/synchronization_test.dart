import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeSynchronizationService', () {
    test('Synchronizes adapter objects and relationships into repository', () async {
      final repo = InMemoryKnowledgeRepository();
      final bus = KnowledgeEventBus();
      final syncService = KnowledgeSynchronizationService(repo, bus);

      final adapter = ConstitutionPackageAdapter();
      final result = await syncService.synchronizeAdapter(adapter);

      expect(result.objectsAdded, equals(2));
      expect(result.relationshipsAdded, equals(1));
      expect(result.conflicts.isEmpty, isTrue);

      final exported = await repo.bulkExport();
      expect(exported.length, equals(2));
    });
  });
}
