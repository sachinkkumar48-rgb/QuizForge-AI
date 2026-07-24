import 'dart:io';
import 'package:hive/hive.dart';
import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_storage/titan_storage.dart';

class _SampleUser {
  final String id;
  final String name;
  _SampleUser(this.id, this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory _SampleUser.fromJson(Map<String, dynamic> json) =>
      _SampleUser(json['id'] as String, json['name'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SampleUser && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

void main() {
  group('Titan Storage Abstraction Foundation Tests', () {
    late InMemoryStorageService storage;
    late TitanServiceLocator locator;

    setUp(() {
      storage = InMemoryStorageService();
      locator = TitanServiceLocator();
      locator.reset();
      TitanBootstrap.reset();
    });

    tearDown(() async {
      if (storage.isInitialized && !storage.isClosed) {
        await storage.close();
      }
      locator.reset();
      TitanBootstrap.reset();
    });

    test('1. Initialization lifecycle and isInitialized flag', () async {
      expect(storage.isInitialized, isFalse);
      expect(storage.isClosed, isFalse);

      await storage.initialize();

      expect(storage.isInitialized, isTrue);
      expect(storage.isClosed, isFalse);

      await storage.close();

      expect(storage.isInitialized, isFalse);
      expect(storage.isClosed, isTrue);
    });

    test(
        '2. Operations before initialization throw StorageInitializationException',
        () async {
      const key = StorageKey('uninit_key');

      expect(() => storage.contains(key),
          throwsA(isA<StorageInitializationException>()));
      expect(() => storage.read<String>(key),
          throwsA(isA<StorageInitializationException>()));
      expect(() => storage.write<String>(key, 'val'),
          throwsA(isA<StorageInitializationException>()));
      expect(() => storage.delete(key),
          throwsA(isA<StorageInitializationException>()));
      expect(() => storage.clear(),
          throwsA(isA<StorageInitializationException>()));
      expect(
          () => storage.keys(), throwsA(isA<StorageInitializationException>()));
    });

    test('3. Operations after close throw StorageClosedException', () async {
      await storage.initialize();
      await storage.close();

      const key = StorageKey('closed_key');

      expect(
          () => storage.initialize(), throwsA(isA<StorageClosedException>()));
      expect(
          () => storage.contains(key), throwsA(isA<StorageClosedException>()));
      expect(() => storage.read<String>(key),
          throwsA(isA<StorageClosedException>()));
      expect(() => storage.write<String>(key, 'val'),
          throwsA(isA<StorageClosedException>()));
      expect(() => storage.delete(key), throwsA(isA<StorageClosedException>()));
      expect(() => storage.clear(), throwsA(isA<StorageClosedException>()));
      expect(() => storage.keys(), throwsA(isA<StorageClosedException>()));
    });

    test('4. Read and write with primitive and complex generic types',
        () async {
      await storage.initialize();

      const stringKey = StorageKey('str_key');
      const intKey = StorageKey('int_key');
      const boolKey = StorageKey('bool_key');
      const listKey = StorageKey('list_key');

      await storage.write<String>(stringKey, 'Hello TITAN');
      await storage.write<int>(intKey, 42);
      await storage.write<bool>(boolKey, true);
      await storage.write<List<String>>(listKey, ['a', 'b', 'c']);

      expect(await storage.read<String>(stringKey), equals('Hello TITAN'));
      expect(await storage.read<int>(intKey), equals(42));
      expect(await storage.read<bool>(boolKey), isTrue);
      expect(
          await storage.read<List<String>>(listKey), equals(['a', 'b', 'c']));

      expect(
          await storage.read<String>(const StorageKey('non_existent')), isNull);
    });

    test('5. Read type mismatch throws StorageReadException', () async {
      await storage.initialize();

      const key = StorageKey('mismatch_key');
      await storage.write<String>(key, 'string value');

      expect(
        () => storage.read<int>(key),
        throwsA(isA<StorageReadException>()),
      );
    });

    test(
        '6. Update semantics preserve createdAt and update updatedAt timestamp',
        () async {
      await storage.initialize();

      const key = StorageKey('timestamp_key');
      await storage.write<String>(key, 'initial value');

      final initialEntry = await storage.readEntry<String>(key);
      expect(initialEntry, isNotNull);
      expect(initialEntry!.value, equals('initial value'));
      final createdAt = initialEntry.createdAt;
      final initialUpdatedAt = initialEntry.updatedAt;

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await storage.write<String>(key, 'updated value');

      final updatedEntry = await storage.readEntry<String>(key);
      expect(updatedEntry, isNotNull);
      expect(updatedEntry!.value, equals('updated value'));
      expect(updatedEntry.createdAt, equals(createdAt));
      expect(updatedEntry.updatedAt.isAfter(initialUpdatedAt), isTrue);
    });

    test('7. Contains, Delete, and Clear operations', () async {
      await storage.initialize();

      const key1 = StorageKey('key_1', namespace: 'user');
      const key2 = StorageKey('key_2', namespace: 'user');
      const key3 = StorageKey('key_3', namespace: 'config');

      await storage.write<String>(key1, 'v1');
      await storage.write<String>(key2, 'v2');
      await storage.write<String>(key3, 'v3');

      expect(await storage.contains(key1), isTrue);
      expect(await storage.contains(const StorageKey('unknown')), isFalse);

      await storage.delete(key1);
      expect(await storage.contains(key1), isFalse);

      final userKeys = await storage.keys(namespace: 'user');
      expect(userKeys.length, equals(1));
      expect(userKeys.first, equals(key2));

      final allKeys = await storage.keys();
      expect(allKeys.length, equals(2));

      await storage.clear();
      expect((await storage.keys()).isEmpty, isTrue);
    });

    test('8. StorageKey equality and qualifiedKey representation', () {
      const k1 = StorageKey('token', namespace: 'auth');
      const k2 = StorageKey('token', namespace: 'auth');
      const k3 = StorageKey('token');

      expect(k1, equals(k2));
      expect(k1 == k3, isFalse);
      expect(k1.qualifiedKey, equals('auth:token'));
      expect(k3.qualifiedKey, equals('token'));
    });

    test('9. StorageVersion comparison and semver formatting', () {
      const v1 = StorageVersion(1, 0, 0);
      const v2 = StorageVersion(1, 1, 0);
      const v3 = StorageVersion(2, 0, 0);

      expect(StorageVersion.current, equals(v1));
      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v3 >= v1, isTrue);
      expect(v1.versionString, equals('1.0.0'));
    });

    test('10. StorageSerializer and StorageSerializerRegistry behavior', () {
      final registry = StorageSerializerRegistry();
      final userSerializer = JsonStorageSerializer<_SampleUser>(
        toJson: (user) => user.toJson(),
        fromJson: (json) => _SampleUser.fromJson(json),
      );

      registry.register<_SampleUser>(userSerializer);

      final user = _SampleUser('u1', 'Alice');
      final serialized = registry.serialize<_SampleUser>(user);
      expect(serialized, isA<Map<String, dynamic>>());
      expect(serialized['name'], equals('Alice'));

      final deserialized = registry.deserialize<_SampleUser>(serialized);
      expect(deserialized, equals(user));
    });

    test('11. TitanCacheManager store, retrieve, remove, clear, and TTL maxAge',
        () async {
      await storage.initialize();
      final cacheManager = TitanCacheManager(storageService: storage);

      const key = StorageKey('cache_key');
      await cacheManager.store<String>(key, 'cached_data');

      expect(await cacheManager.exists(key), isTrue);
      expect(await cacheManager.retrieve<String>(key), equals('cached_data'));

      // Test valid TTL
      expect(
        await cacheManager.retrieve<String>(key,
            maxAge: const Duration(minutes: 5)),
        equals('cached_data'),
      );

      // Test expired TTL
      expect(
        await cacheManager.retrieve<String>(key, maxAge: Duration.zero),
        isNull,
      );
      expect(await cacheManager.exists(key), isFalse);

      // Re-store and test remove and clear
      await cacheManager.store<String>(key, 'fresh_data');
      await cacheManager.remove(key);
      expect(await cacheManager.exists(key), isFalse);

      await cacheManager.store<String>(key, 'data');
      await cacheManager.clear();
      expect(await cacheManager.exists(key), isFalse);
    });

    test(
        '12. HiveStorageService CRUD, metadata timestamps, and exception mapping',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      final box = await Hive.openBox<dynamic>('test_box');

      final hiveStorage = HiveStorageService(box: box);
      await hiveStorage.initialize();

      expect(hiveStorage.isInitialized, isTrue);

      const key = StorageKey('hive_key', namespace: 'test');
      await hiveStorage.write<String>(key, 'hive_value');

      expect(await hiveStorage.contains(key), isTrue);
      expect(await hiveStorage.read<String>(key), equals('hive_value'));

      final entry = await hiveStorage.readEntry<String>(key);
      expect(entry, isNotNull);
      expect(entry!.value, equals('hive_value'));

      final keys = await hiveStorage.keys(namespace: 'test');
      expect(keys.length, equals(1));

      await hiveStorage.delete(key);
      expect(await hiveStorage.contains(key), isFalse);

      await hiveStorage.close();
      expect(hiveStorage.isInitialized, isFalse);

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
        '13. TitanStorageBootstrap registers StorageService, TitanCacheManager, and Registry',
        () async {
      await TitanStorageBootstrap.initializeStorage(useInMemory: true);

      final resolvedStorage = locator.get<StorageService>();
      final resolvedCache = locator.get<TitanCacheManager>();
      final resolvedRegistry = locator.get<StorageSerializerRegistry>();

      expect(resolvedStorage.isInitialized, isTrue);
      expect(resolvedCache, isNotNull);
      expect(resolvedRegistry, isNotNull);
    });
  });
}
