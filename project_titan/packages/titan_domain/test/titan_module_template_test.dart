import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';

class _MockSampleRepositoryRegistrar extends RepositoryRegistrationTemplate {
  @override
  void registerRepositories(TitanServiceLocator locator) {
    registerRepository<String>(locator, () => 'SampleRepositoryInstance');
  }

  @override
  void unregisterRepositories(TitanServiceLocator locator) {
    unregisterRepository<String>(locator);
  }
}

class _MockSampleModuleBootstrap implements TitanModuleBootstrap {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  void registerDependencies(TitanServiceLocator locator) {
    _MockSampleRepositoryRegistrar().registerRepositories(locator);
  }

  @override
  void validate() {
    TitanModuleValidator.validateRegisteredServices(
      TitanServiceLocator.instance,
      [AIService, StorageService, NetworkService],
    );
  }

  @override
  Future<void> initialize() async {
    validate();
    registerDependencies(TitanServiceLocator.instance);
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    _MockSampleRepositoryRegistrar()
        .unregisterRepositories(TitanServiceLocator.instance);
    _initialized = false;
  }
}

class _MockAIService implements AIService {
  @override
  bool get isInitialized => true;
  @override
  Future<void> initialize() async {}
  @override
  List<AIModel> availableModels() => const [];
  @override
  AIModel defaultModel() => throw UnimplementedError();
  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> close() async {}
}

class _MockStorageService implements StorageService {
  @override
  bool get isInitialized => true;
  @override
  Future<void> initialize() async {}
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
  Future<void> close() async {}
}

class _MockNetworkService implements NetworkService {
  @override
  bool get isInitialized => true;
  @override
  Future<void> initialize() async {}
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
  Future<void> close() async {}
}

void main() {
  group('Domain Module Template Foundation Tests', () {
    late TitanServiceLocator locator;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      TitanBootstrap.reset();
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test('1. TitanModuleConfig model immutability and equality', () {
      final config1 = TitanModuleConfig(
        moduleName: 'titan_quiz',
        moduleVersion: '1.0.0',
        enabled: true,
        metadata: const {'author': 'TITAN Team'},
      );

      final config2 = TitanModuleConfig(
        moduleName: 'titan_quiz',
        moduleVersion: '1.0.0',
        enabled: true,
        metadata: const {'author': 'TITAN Team'},
      );

      expect(config1.moduleName, equals('titan_quiz'));
      expect(config1.moduleVersion, equals('1.0.0'));
      expect(config1.enabled, isTrue);
      expect(config1.metadata['author'], equals('TITAN Team'));
      expect(config1, equals(config2));
      expect(
          config1.toString(),
          contains(
              'TitanModuleConfig(name: titan_quiz, v1.0.0, enabled: true)'));
    });

    test('2. TitanModuleInfo metadata model creation and properties', () {
      final info = TitanModuleInfo(
        name: 'titan_pdf',
        version: '0.1.0',
        description: 'PDF Parsing and Extraction Module',
        author: 'TITAN Architect',
        dependencies: const ['titan_core', 'titan_storage'],
      );

      expect(info.name, equals('titan_pdf'));
      expect(info.version, equals('0.1.0'));
      expect(info.description, contains('PDF Parsing'));
      expect(info.author, equals('TITAN Architect'));
      expect(info.dependencies, contains('titan_core'));
      expect(info.toString(),
          contains('TitanModuleInfo(titan_pdf v0.1.0 by TITAN Architect)'));
    });

    test('3. TitanModuleValidator validates config and missing dependencies',
        () {
      final invalidConfig =
          TitanModuleConfig(moduleName: '', moduleVersion: '1.0.0');
      expect(
        () => TitanModuleValidator.validateConfig(invalidConfig),
        throwsA(isA<TitanInvalidConfigException>()),
      );

      final bootstrap = _MockSampleModuleBootstrap();
      expect(
        () => TitanModuleValidator.validateBootstrap(bootstrap),
        throwsA(isA<RepositoryInitializationException>()),
      );

      expect(
        () => TitanModuleValidator.validateRegisteredServices(
            locator, [AIService]),
        throwsA(isA<TitanMissingDependencyException>()),
      );
    });

    test('4. TitanModuleBootstrap lifecycle and repository registration',
        () async {
      locator.registerSingleton<AIService>(_MockAIService());
      locator.registerSingleton<StorageService>(_MockStorageService());
      locator.registerSingleton<NetworkService>(_MockNetworkService());

      final bootstrap = _MockSampleModuleBootstrap();
      expect(bootstrap.isInitialized, isFalse);

      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<String>(), isTrue);
      expect(locator.get<String>(), equals('SampleRepositoryInstance'));

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<String>(), isFalse);
    });

    test(
        '5. Public exports strategy ensures clean access to module abstractions',
        () {
      expect(TitanModuleBootstrap, isNotNull);
      expect(TitanModuleConfig, isNotNull);
      expect(TitanModuleInfo, isNotNull);
      expect(TitanRepositoryRegistrar, isNotNull);
      expect(TitanModuleValidator, isNotNull);
    });
  });
}
