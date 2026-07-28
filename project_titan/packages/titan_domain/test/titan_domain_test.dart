import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';

class _MockAIService implements AIService {
  bool _initialized = false;
  bool shouldThrowOnInitialize = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (shouldThrowOnInitialize) {
      throw const AIInitializationException('AI Service failed to init');
    }
    _initialized = true;
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'mock-model',
        displayName: 'Mock Model',
        contextWindow: 1000,
        maxOutputTokens: 500,
      );

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    throw const AIRequestException('AI Error');
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockStorageService implements StorageService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> contains(StorageKey key) async => false;

  @override
  Future<T?> read<T>(StorageKey key) async => null;

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async => null;

  @override
  Future<void> write<T>(StorageKey key, T value) async {}

  @override
  Future<void> delete(StorageKey key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<List<StorageKey>> keys({String? namespace}) async => const [];

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockNetworkService implements NetworkService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<NetworkResponse<T>> get<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> post<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> put<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> patch<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> delete<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> head<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> request<T>(NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _TestConcreteRepository extends BaseRepository<String> {
  _TestConcreteRepository({
    required super.aiService,
    required super.storageService,
    required super.networkService,
    super.cacheStrategy,
  });

  Future<R> testGuardedCall<R>(Future<R> Function() action) {
    checkState();
    return executeGuarded(action);
  }
}

void main() {
  group('Titan Repository Foundation Tests', () {
    late TitanServiceLocator locator;
    late _MockAIService mockAI;
    late _MockStorageService mockStorage;
    late _MockNetworkService mockNetwork;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      TitanBootstrap.reset();

      mockAI = _MockAIService();
      mockStorage = _MockStorageService();
      mockNetwork = _MockNetworkService();
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test(
        '1. RepositoryResult model properties and RepositorySource enum values',
        () {
      final now = DateTime.now();
      final result = RepositoryResult<String>(
        data: 'Sample Data',
        source: RepositorySource.cache,
        metadata: const {'cachedKey': 'quiz_123'},
        timestamp: now,
      );

      expect(result.data, equals('Sample Data'));
      expect(result.hasData, isTrue);
      expect(result.source, equals(RepositorySource.cache));
      expect(result.metadata['cachedKey'], equals('quiz_123'));
      expect(result.timestamp, equals(now));

      expect(
          RepositorySource.values,
          containsAll([
            RepositorySource.cache,
            RepositorySource.network,
            RepositorySource.ai,
            RepositorySource.local,
          ]));
    });

    test('2. Repository Exception Hierarchy formatting and attributes', () {
      const initEx = RepositoryInitializationException('Init failed');
      const cacheEx = RepositoryCacheException('Cache read error');
      const netEx = RepositoryNetworkException('HTTP Error', 404);
      const aiEx = RepositoryAIException('LLM error');
      const dataEx = RepositoryDataException('Parse failure');

      expect(initEx.toString(),
          contains('RepositoryInitializationException: Init failed'));
      expect(cacheEx.toString(),
          contains('RepositoryCacheException: Cache read error'));
      expect(netEx.statusCode, equals(404));
      expect(aiEx.toString(), contains('RepositoryAIException: LLM error'));
      expect(dataEx.toString(),
          contains('RepositoryDataException: Parse failure'));
    });

    test('3. CacheFirstStrategy evaluation with valid and expired TTLs', () {
      const strategy = CacheFirstStrategy(defaultTtl: Duration(minutes: 10));
      final recentDate = DateTime.now().subtract(const Duration(minutes: 2));
      final expiredDate = DateTime.now().subtract(const Duration(minutes: 15));

      expect(strategy.shouldReadCache(cachedAt: recentDate), isTrue);
      expect(strategy.shouldRefresh(cachedAt: recentDate), isFalse);

      expect(strategy.shouldReadCache(cachedAt: expiredDate), isFalse);
      expect(strategy.shouldRefresh(cachedAt: expiredDate), isTrue);

      expect(strategy.shouldWriteCache(), isTrue);
      expect(strategy.shouldReadCache(cachedAt: null), isFalse);
    });

    test('4. BaseRepository lifecycle management', () async {
      const customCacheStrategy =
          CacheFirstStrategy(defaultTtl: Duration(minutes: 5));
      final repo = _TestConcreteRepository(
        aiService: mockAI,
        storageService: mockStorage,
        networkService: mockNetwork,
        cacheStrategy: customCacheStrategy,
      );

      expect(repo.isInitialized, isFalse);
      expect(identical(repo.cacheStrategy, customCacheStrategy), isTrue);
      await repo.initialize();
      expect(repo.isInitialized, isTrue);
      expect(mockAI.isInitialized, isTrue);
      expect(mockStorage.isInitialized, isTrue);
      expect(mockNetwork.isInitialized, isTrue);

      await repo.dispose();
      expect(repo.isInitialized, isFalse);

      expect(
        () => repo.testGuardedCall(() async => 'test'),
        throwsA(isA<RepositoryInitializationException>()),
      );
    });

    test(
        '5. BaseRepository error translation translates infrastructure exceptions',
        () async {
      final repo = _TestConcreteRepository(
        aiService: mockAI,
        storageService: mockStorage,
        networkService: mockNetwork,
      );
      await repo.initialize();

      expect(
        () => repo.testGuardedCall(
            () async => throw const AIResponseException('LLM failed', 500)),
        throwsA(isA<RepositoryAIException>()),
      );

      expect(
        () => repo.testGuardedCall(
            () async => throw const StorageReadException('Key read failed')),
        throwsA(isA<RepositoryCacheException>()),
      );

      expect(
        () => repo.testGuardedCall(() async =>
            throw const NetworkResponseException('Connection timeout',
                statusCode: 408)),
        throwsA(isA<RepositoryNetworkException>()
            .having((e) => e.statusCode, 'statusCode', 408)),
      );

      expect(
        () => repo.testGuardedCall(
            () async => throw const FormatException('Bad JSON')),
        throwsA(isA<RepositoryDataException>()),
      );
    });

    test(
        '6. TitanRepositoryBootstrap validates infrastructure services presence',
        () async {
      final config = TitanConfig.defaultConfig();
      locator.registerSingleton<TitanConfig>(config);

      expect(
        () => TitanRepositoryBootstrap.initialize(),
        throwsA(isA<RepositoryInitializationException>().having(
          (e) => e.message,
          'message',
          contains('AIService must be registered'),
        )),
      );

      locator.registerSingleton<AIService>(mockAI);
      locator.registerSingleton<StorageService>(mockStorage);
      locator.registerSingleton<NetworkService>(mockNetwork);

      await TitanRepositoryBootstrap.initialize();

      expect(locator.isRegistered<CacheStrategy>(), isTrue);
      final registeredStrategy = locator.get<CacheStrategy>();
      expect(registeredStrategy, isA<CacheFirstStrategy>());
    });

    test('7. Dependency Injection resolves registered CacheStrategy singleton',
        () async {
      locator.registerSingleton<AIService>(mockAI);
      locator.registerSingleton<StorageService>(mockStorage);
      locator.registerSingleton<NetworkService>(mockNetwork);

      const customStrategy =
          CacheFirstStrategy(defaultTtl: Duration(minutes: 30));
      await TitanRepositoryBootstrap.initialize(cacheStrategy: customStrategy);

      final resolved = locator.get<CacheStrategy>();
      expect(identical(resolved, customStrategy), isTrue);
    });
  });
}
