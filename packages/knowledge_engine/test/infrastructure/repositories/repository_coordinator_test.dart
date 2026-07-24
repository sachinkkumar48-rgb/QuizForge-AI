import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

class MockLocalDataSource implements KnowledgeLocalDataSource {
  final Map<String, KnowledgeObject> storage = {};

  @override
  Future<void> save(KnowledgeObject object) async {
    storage[object.id] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    if (!storage.containsKey(object.id)) {
      throw Exception('Not found locally');
    }
    storage[object.id] = object;
  }

  @override
  Future<void> delete(String id) async {
    storage.remove(id);
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    return storage[id];
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    return storage.values
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<KnowledgeObject>> getAll() async {
    return storage.values.toList();
  }

  @override
  Future<void> clear() async {
    storage.clear();
  }
}

class MockRemoteDataSource implements KnowledgeRemoteDataSource {
  final Map<String, KnowledgeObject> storage = {};
  bool shouldThrowError = false;

  @override
  Future<void> save(KnowledgeObject object) async {
    if (shouldThrowError) throw Exception('Network offline');
    storage[object.id] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    if (shouldThrowError) throw Exception('Network offline');
    storage[object.id] = object;
  }

  @override
  Future<void> delete(String id) async {
    if (shouldThrowError) throw Exception('Network offline');
    storage.remove(id);
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    if (shouldThrowError) throw Exception('Network offline');
    return storage[id];
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    if (shouldThrowError) throw Exception('Network offline');
    return storage.values
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<KnowledgeObject>> fetchUpdatedSince(DateTime timestamp) async {
    if (shouldThrowError) throw Exception('Network offline');
    return storage.values
        .where((item) => item.updatedAt.isAfter(timestamp))
        .toList();
  }
}

class MockCacheDataSource implements KnowledgeCacheDataSource {
  final Map<String, KnowledgeObject> cache = {};

  @override
  KnowledgeObject? get(String id) => cache[id];

  @override
  void put(KnowledgeObject object) {
    cache[object.id] = object;
  }

  @override
  void remove(String id) {
    cache.remove(id);
  }

  @override
  void clear() {
    cache.clear();
  }
}

class MockSyncQueue implements KnowledgeSyncQueue {
  final List<KnowledgeSyncCommand> queue = [];

  @override
  Future<void> enqueue(
    KnowledgeSyncOperation operation,
    KnowledgeObject object,
  ) async {
    queue.add(KnowledgeSyncCommand(
      id: 'cmd_${queue.length + 1}',
      operation: operation,
      knowledgeObject: object,
    ));
  }

  @override
  Future<void> dequeue(String id) async {
    queue.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<KnowledgeSyncCommand>> getPendingCommands() async {
    return List.unmodifiable(queue);
  }

  @override
  Future<void> clear() async {
    queue.clear();
  }
}

void main() {
  group('RepositoryCoordinator & Infrastructure Tests', () {
    late MockLocalDataSource localDS;
    late MockRemoteDataSource remoteDS;
    late MockCacheDataSource cacheDS;
    late MockSyncQueue syncQueue;
    late RepositoryCoordinator coordinator;
    late KnowledgeObject sample;

    setUp(() {
      localDS = MockLocalDataSource();
      remoteDS = MockRemoteDataSource();
      cacheDS = MockCacheDataSource();
      syncQueue = MockSyncQueue();
      coordinator = RepositoryCoordinator(
        localDataSource: localDS,
        remoteDataSource: remoteDS,
        cacheDataSource: cacheDS,
        syncQueue: syncQueue,
      );

      sample = KnowledgeObject(
        id: 'ko_coord_1',
        type: KnowledgeType.report,
        title: 'Economic Survey 2026',
        summary: 'Annual economic statistics and projections',
        source: 'https://gov.in/eco_survey.pdf',
      );
    });

    test('save writes to cache, local storage, and remote storage when online',
        () async {
      await coordinator.save(sample);

      expect(cacheDS.get('ko_coord_1'), equals(sample));
      expect(await localDS.findById('ko_coord_1'), equals(sample));
      expect(await remoteDS.findById('ko_coord_1'), equals(sample));
      expect(await syncQueue.getPendingCommands(), isEmpty);
    });

    test('save enqueues sync command when remote fails offline', () async {
      remoteDS.shouldThrowError = true;

      await coordinator.save(sample);

      expect(cacheDS.get('ko_coord_1'), equals(sample));
      expect(await localDS.findById('ko_coord_1'), equals(sample));
      final pending = await syncQueue.getPendingCommands();
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(KnowledgeSyncOperation.save));
      expect(pending.first.knowledgeObject, equals(sample));
    });

    test('findById retrieves from cache first, then local, then remote',
        () async {
      // 1. Remote hit
      remoteDS.storage[sample.id] = sample;
      var result = await coordinator.findById(sample.id);
      expect(result, equals(sample));
      expect(cacheDS.get(sample.id), equals(sample));
      expect(await localDS.findById(sample.id), equals(sample));

      // 2. Cache hit
      final cacheResult = await coordinator.findById(sample.id);
      expect(cacheResult, equals(sample));

      // 3. Local hit (cache cleared)
      cacheDS.clear();
      final localResult = await coordinator.findById(sample.id);
      expect(localResult, equals(sample));
      expect(cacheDS.get(sample.id), equals(sample));
    });

    test(
        'update modifies local/cache and queues sync command on remote failure',
        () async {
      await coordinator.save(sample);
      remoteDS.shouldThrowError = true;

      final updated = sample.copyWith(title: 'Updated Economic Survey');
      await coordinator.update(updated);

      expect(cacheDS.get(sample.id)?.title, equals('Updated Economic Survey'));
      expect((await localDS.findById(sample.id))?.title,
          equals('Updated Economic Survey'));
      final pending = await syncQueue.getPendingCommands();
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(KnowledgeSyncOperation.update));
    });

    test(
        'delete evicts cache/local and enqueues sync command on remote failure',
        () async {
      await coordinator.save(sample);
      remoteDS.shouldThrowError = true;

      await coordinator.delete(sample.id);

      expect(cacheDS.get(sample.id), isNull);
      expect(await localDS.findById(sample.id), isNull);
      final pending = await syncQueue.getPendingCommands();
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(KnowledgeSyncOperation.delete));
    });

    test('search returns local results and populates cache', () async {
      await localDS.save(sample);

      final results = await coordinator.search('Economic');
      expect(results.length, equals(1));
      expect(results.first, equals(sample));
      expect(cacheDS.get(sample.id), equals(sample));
    });

    test('KnowledgeDependencyContainer registers and resolves repository', () {
      final container = KnowledgeDependencyContainer.instance;
      container.reset();

      expect(() => container.repository, throwsStateError);

      container.registerLocalDataSource(localDS);
      container.registerRemoteDataSource(remoteDS);
      container.registerCacheDataSource(cacheDS);
      container.registerSyncQueue(syncQueue);

      final resolvedRepo = container.repository;
      expect(resolvedRepo, isA<RepositoryCoordinator>());

      container.reset();
      expect(() => container.repository, throwsStateError);
    });
  });
}
