import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('KnowledgeRepositoryImpl Tests', () {
    late KnowledgeRepository repository;
    late StorageService storageService;

    setUp(() async {
      storageService = InMemoryStorageService();
      await storageService.initialize();
      repository = KnowledgeRepositoryImpl(storageService: storageService);
    });

    test('Saves, retrieves, and deletes KnowledgeObjects', () async {
      final obj = KnowledgeObject(
        id: 'obj_101',
        title: 'Fundamental Rights',
        source: 'constitution.md',
        contentBlocks: const [
          ParagraphBlock(id: 'b1', text: 'Article 14 to 32')
        ],
      );

      await repository.saveKnowledgeObject(obj);

      final retrieved = await repository.getKnowledgeObjectById('obj_101');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Fundamental Rights'));

      final all = await repository.getAllKnowledgeObjects();
      expect(all.length, equals(1));

      await repository.deleteKnowledgeObject('obj_101');
      final deleted = await repository.getKnowledgeObjectById('obj_101');
      expect(deleted, isNull);
    });
  });
}
