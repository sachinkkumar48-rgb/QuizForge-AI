import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

class MockKnowledgeRepository implements KnowledgeRepository {
  final Map<String, KnowledgeObject> _storage = {};

  @override
  Future<void> save(KnowledgeObject object) async {
    _storage[object.id] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    if (!_storage.containsKey(object.id)) {
      throw Exception('Object not found');
    }
    _storage[object.id] = object;
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    final lower = query.toLowerCase();
    return _storage.values
        .where((obj) =>
            obj.title.toLowerCase().contains(lower) ||
            obj.summary.toLowerCase().contains(lower) ||
            obj.keywords.any((k) => k.toLowerCase().contains(lower)))
        .toList();
  }
}

void main() {
  group('Knowledge Engine Package Integration Tests', () {
    late MockKnowledgeRepository repository;
    late KnowledgeObject sampleObject;

    setUp(() {
      repository = MockKnowledgeRepository();
      sampleObject = KnowledgeObject(
        id: 'ko_test_1',
        type: KnowledgeType.article,
        title: 'Editorial on Digital India',
        summary: 'Analysis of digital infrastructure and governance in India',
        source: 'https://example.com/editorial/digital-india',
        keywords: ['Digital India', 'Governance', 'UPSC Mains'],
      );
    });

    test('verifies exported domain components interact seamlessly', () async {
      // Save
      await repository.save(sampleObject);

      // findById
      final retrieved = await repository.findById('ko_test_1');
      expect(retrieved, isNotNull);
      expect(retrieved, equals(sampleObject));

      // search
      final searchResults = await repository.search('Governance');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('ko_test_1'));

      // update
      final updatedObject =
          sampleObject.copyWith(title: 'Updated Editorial Title');
      await repository.update(updatedObject);
      final afterUpdate = await repository.findById('ko_test_1');
      expect(afterUpdate?.title, equals('Updated Editorial Title'));

      // delete
      await repository.delete('ko_test_1');
      final afterDelete = await repository.findById('ko_test_1');
      expect(afterDelete, isNull);
    });
  });
}
