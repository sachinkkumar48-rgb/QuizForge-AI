import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_core/titan_core.dart';

class _TestService {
  final String id;
  _TestService(this.id);
}

class _CounterService {
  static int count = 0;
  final int instanceId;
  _CounterService() : instanceId = ++count;
}

class _MockErrorReporter implements ErrorReporter {
  final List<TitanLogEntry> reportedEntries = [];

  @override
  void report(TitanLogEntry entry) {
    reportedEntries.add(entry);
  }
}

class _MockLogSink implements LogSink {
  final List<TitanLogEntry> writtenEntries = [];

  @override
  void write(TitanLogEntry entry) {
    writtenEntries.add(entry);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TitanServiceLocator Dependency Injection Foundation Tests', () {
    late TitanServiceLocator locator;

    setUp(() {
      locator = TitanServiceLocator();
      locator.reset();
      TitanBootstrap.reset();
      _CounterService.count = 0;
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test('1. Singleton registration returns exact same instance', () {
      final service = _TestService('s1');
      locator.registerSingleton<_TestService>(service);

      expect(locator.isRegistered<_TestService>(), isTrue);
      expect(locator.getLifetime<_TestService>(),
          equals(DependencyLifetime.singleton));

      final resolved1 = locator.get<_TestService>();
      final resolved2 = locator<_TestService>();

      expect(identical(resolved1, service), isTrue);
      expect(identical(resolved2, service), isTrue);
    });

    test('2. Lazy singleton registration defers creation until first get()',
        () {
      bool factoryCalled = false;

      locator.registerLazySingleton<_TestService>(() {
        factoryCalled = true;
        return _TestService('lazy_1');
      });

      expect(locator.isRegistered<_TestService>(), isTrue);
      expect(factoryCalled, isFalse);

      final instance1 = locator.get<_TestService>();
      expect(factoryCalled, isTrue);
      expect(instance1.id, equals('lazy_1'));

      final instance2 = locator.get<_TestService>();
      expect(identical(instance1, instance2), isTrue);
    });

    test('3. Factory registration creates new instance on every get()', () {
      locator.registerFactory<_CounterService>(() => _CounterService());

      expect(locator.isRegistered<_CounterService>(), isTrue);
      expect(locator.getLifetime<_CounterService>(),
          equals(DependencyLifetime.factory));

      final instance1 = locator.get<_CounterService>();
      final instance2 = locator.get<_CounterService>();

      expect(instance1.instanceId, equals(1));
      expect(instance2.instanceId, equals(2));
      expect(identical(instance1, instance2), isFalse);
    });

    test(
        '4. Duplicate registration protection throws TitanDuplicateDependencyException',
        () {
      locator.registerSingleton<_TestService>(_TestService('orig'));

      expect(
        () => locator.registerSingleton<_TestService>(_TestService('dup')),
        throwsA(isA<TitanDuplicateDependencyException>()),
      );
    });

    test('5. Duplicate registration with allowOverride succeeds', () {
      locator.registerSingleton<_TestService>(_TestService('orig'));
      locator.registerSingleton<_TestService>(_TestService('new'),
          allowOverride: true);

      expect(locator.get<_TestService>().id, equals('new'));
    });

    test(
        '6. Missing dependency resolution throws TitanMissingDependencyException',
        () {
      expect(
        () => locator.get<_TestService>(),
        throwsA(isA<TitanMissingDependencyException>()),
      );
    });

    test('7. Unregister and Reset functionality clears registered instances',
        () {
      locator.registerSingleton<_TestService>(_TestService('temp'));
      expect(locator.isRegistered<_TestService>(), isTrue);

      locator.unregister<_TestService>();
      expect(locator.isRegistered<_TestService>(), isFalse);

      locator.registerSingleton<TitanConfig>(TitanConfig.defaultConfig());
      locator.reset();
      expect(locator.isRegistered<TitanConfig>(), isFalse);
    });
  });

  group('TitanConfig & Environment Foundation Tests', () {
    test('1. TitanEnvironment enum helpers and parsing', () {
      expect(TitanEnvironment.development.isDevelopment, isTrue);
      expect(TitanEnvironment.staging.isStaging, isTrue);
      expect(TitanEnvironment.production.isProduction, isTrue);
      expect(TitanEnvironment.testing.isTesting, isTrue);

      expect(TitanEnvironment.fromString('STAGING'),
          equals(TitanEnvironment.staging));
      expect(TitanEnvironment.fromString('unknown'),
          equals(TitanEnvironment.development));
    });

    test('2. Feature flag evaluation', () {
      final config = TitanConfig.defaultConfig();
      expect(config.isFeatureEnabled('enable_ai_tutor'), isTrue);
      expect(config.isFeatureEnabled('enable_cloud_sync'), isFalse);
      expect(config.isFeatureEnabled('non_existent_flag'), isFalse);
    });

    test('3. Invalid configuration detection', () {
      final invalidConfig = TitanConfig(
        titanEnvironment: TitanEnvironment.development,
        appName: '   ',
        version: '1.0.0',
        buildNumber: 1,
        isDebug: true,
        featureFlags: const {},
        apiBaseUrl: 'https://api.quizforge.ai',
        enableLogging: true,
        enableAnalytics: false,
      );

      expect(
        () => invalidConfig.validate(),
        throwsA(isA<TitanInvalidConfigException>()),
      );
    });

    test('4. Configuration immutability', () {
      final flags = {'flag_1': true};
      final config = TitanConfig(
        titanEnvironment: TitanEnvironment.development,
        appName: 'QuizForge AI',
        version: '1.0.0',
        buildNumber: 1,
        isDebug: true,
        featureFlags: flags,
        apiBaseUrl: 'https://api.quizforge.ai',
        enableLogging: true,
        enableAnalytics: true,
      );

      expect(
        () => config.featureFlags['flag_1'] = false,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('5. TitanConfigLoader behavior and environment default construction',
        () async {
      const loader = TitanConfigLoader();

      final prodConfig =
          await loader.load(environment: TitanEnvironment.production);
      expect(prodConfig.titanEnvironment, equals(TitanEnvironment.production));
      expect(prodConfig.isDebug, isFalse);
      expect(prodConfig.enableLogging, isFalse);
      expect(prodConfig.apiBaseUrl, equals('https://api.quizforge.ai'));
    });

    test('6. TitanBootstrap integration with TitanConfigLoader', () async {
      TitanBootstrap.reset();
      TitanServiceLocator().reset();

      final config = await TitanBootstrap.initialize(
          environment: TitanEnvironment.staging);

      expect(TitanBootstrap.isInitialized, isTrue);
      expect(config.titanEnvironment, equals(TitanEnvironment.staging));
      expect(TitanServiceLocator().get<TitanConfig>(), equals(config));
    });
  });

  group('Navigation Foundation Tests', () {
    setUp(() {
      TitanServiceLocator().reset();
      TitanBootstrap.reset();
    });

    test('1. TitanRoutes strongly typed route constants', () {
      expect(TitanRoutes.initial, equals('/'));
      expect(TitanRoutes.home, equals('/home'));
      expect(TitanRoutes.notFound, equals('/404'));
      expect(TitanRoutes.allRoutes, containsAll(['/', '/home', '/404']));
    });

    test('2. TitanRouteGenerator resolves registered and unknown routes', () {
      final homeRoute = TitanRouteGenerator.generateRoute(
          const RouteSettings(name: TitanRoutes.home));
      expect(homeRoute, isA<MaterialPageRoute<dynamic>>());

      final unknownRoute = TitanRouteGenerator.generateRoute(
          const RouteSettings(name: '/non_existent_route'));
      expect(unknownRoute, isA<MaterialPageRoute<dynamic>>());
      expect(unknownRoute.settings.name, equals('/non_existent_route'));
    });

    test('3. TitanBootstrap registers NavigationService in TitanServiceLocator',
        () async {
      await TitanBootstrap.initialize();

      expect(TitanServiceLocator().isRegistered<NavigationService>(), isTrue);
      final navService = TitanServiceLocator().get<NavigationService>();
      expect(navService, isA<FlutterNavigationService>());
      expect(navService.navigatorKey, isNotNull);
    });
  });

  group('Global Error Handling & Logging Foundation Tests', () {
    setUp(() {
      TitanServiceLocator().reset();
      TitanBootstrap.reset();
    });

    test('1. TitanLogLevel ordering and priority comparison', () {
      expect(TitanLogLevel.critical >= TitanLogLevel.error, isTrue);
      expect(TitanLogLevel.error >= TitanLogLevel.warning, isTrue);
      expect(TitanLogLevel.warning >= TitanLogLevel.info, isTrue);
      expect(TitanLogLevel.info >= TitanLogLevel.debug, isTrue);
      expect(TitanLogLevel.debug >= TitanLogLevel.trace, isTrue);

      expect(TitanLogLevel.trace < TitanLogLevel.debug, isTrue);
      expect(TitanLogLevel.trace <= TitanLogLevel.critical, isTrue);
      expect(TitanLogLevel.critical > TitanLogLevel.error, isTrue);
      expect(TitanLogLevel.debug.compareTo(TitanLogLevel.info), lessThan(0));

      expect(TitanLogLevel.defaultForEnvironment(TitanEnvironment.development),
          equals(TitanLogLevel.trace));
      expect(TitanLogLevel.defaultForEnvironment(TitanEnvironment.staging),
          equals(TitanLogLevel.debug));
      expect(TitanLogLevel.defaultForEnvironment(TitanEnvironment.production),
          equals(TitanLogLevel.warning));
      expect(TitanLogLevel.defaultForEnvironment(TitanEnvironment.testing),
          equals(TitanLogLevel.info));
    });

    test('2. TitanLogEntry creation and formatting', () {
      final now = DateTime(2026, 8, 10, 11, 5, 31);
      final entry = TitanLogEntry.constEntry(
        timestamp: now,
        level: TitanLogLevel.error,
        message: 'Test Error Message',
        tag: 'TestTag',
        exception: 'SampleException',
      );

      expect(entry.level, equals(TitanLogLevel.error));
      expect(entry.message, equals('Test Error Message'));
      expect(entry.tag, equals('TestTag'));
      expect(entry.exception, equals('SampleException'));
      expect(entry.error, equals('SampleException'));
      expect(
          entry.toString(), contains('[ERROR] [TestTag] Test Error Message'));
    });

    test('3. ConsoleLogSink clean formatting output', () {
      final now = DateTime(2026, 8, 10, 11, 5, 31);
      final entry = TitanLogEntry.constEntry(
        timestamp: now,
        level: TitanLogLevel.warning,
        message: 'Configuration missing...',
        tag: 'Bootstrap',
      );

      const sink = ConsoleLogSink();
      final formatted = sink.formatEntry(entry);

      expect(
        formatted,
        equals(
            '2026-08-10 11:05:31\n[WARNING]\n[Bootstrap]\nConfiguration missing...'),
      );
    });

    test('4. Logger filtering by minLogLevel and sink delegation', () {
      final mockSink = _MockLogSink();
      final mockReporter = _MockErrorReporter();
      final logger = ConsoleTitanLogger(
        minLogLevel: TitanLogLevel.warning,
        logSink: mockSink,
        errorReporter: mockReporter,
      );

      logger.trace('Trace Msg');
      logger.debug('Debug Msg');
      logger.info('Info Msg');

      expect(mockSink.writtenEntries.isEmpty, isTrue);
      expect(mockReporter.reportedEntries.isEmpty, isTrue);

      logger.warning('Warning Msg');
      logger.error('Error Msg');

      expect(mockSink.writtenEntries.length, equals(2));
      expect(mockSink.writtenEntries[0].message, equals('Warning Msg'));
      expect(mockSink.writtenEntries[1].message, equals('Error Msg'));

      expect(mockReporter.reportedEntries.length, equals(1));
      expect(mockReporter.reportedEntries.first.message, equals('Error Msg'));
    });

    test('5. Error classification and TitanError creation', () {
      final now = DateTime.now();
      final error = TitanError(
        errorType: TitanErrorType.configuration,
        exception: const FormatException('Bad config format'),
        stackTrace: StackTrace.current,
        message: 'Config load failed',
        timestamp: now,
      );

      expect(error.errorType, equals(TitanErrorType.configuration));
      expect(error.exception, isA<FormatException>());
      expect(error.message, equals('Config load failed'));
      expect(error.toString(),
          contains('TitanError[configuration]: Config load failed'));
    });

    test('6. TitanErrorHandler 5-step pipeline execution and error forwarding',
        () {
      final mockSink = _MockLogSink();
      final mockReporter = _MockErrorReporter();
      final logger = ConsoleTitanLogger(
        minLogLevel: TitanLogLevel.trace,
        logSink: mockSink,
        errorReporter: mockReporter,
      );
      final errorHandler = TitanErrorHandler(
        logger: logger,
        errorReporter: mockReporter,
      );

      final frameworkError = errorHandler.captureFrameworkError(
        FlutterErrorDetails(
          exception: Exception('Framework Fail'),
          stack: StackTrace.current,
          context: ErrorDescription('Widget Crash'),
        ),
      );

      final asyncError = errorHandler.captureAsyncError(
        Exception('Async Fail'),
        StackTrace.current,
      );

      final uncaughtError = errorHandler.captureUncaughtError(
        Exception('Uncaught Fail'),
        StackTrace.current,
        'CustomModule',
        TitanErrorType.navigation,
      );

      expect(frameworkError.errorType, equals(TitanErrorType.framework));
      expect(asyncError.errorType, equals(TitanErrorType.async));
      expect(uncaughtError.errorType, equals(TitanErrorType.navigation));

      // Each error should produce a log entry sent to logger and reported to errorReporter
      expect(mockSink.writtenEntries.length, equals(3));
      expect(mockSink.writtenEntries[0].tag, equals('FrameworkError'));
      expect(mockSink.writtenEntries[1].tag, equals('AsyncPlatformError'));
      expect(mockSink.writtenEntries[2].tag, equals('CustomModule'));

      // Both errorHandler forwarding AND logger level >= error forwarding call reporter
      expect(mockReporter.reportedEntries.length, greaterThanOrEqualTo(3));
    });

    test('7. NoOpErrorReporter does not throw when reporting', () {
      const reporter = NoOpErrorReporter();
      final entry = TitanLogEntry(
        level: TitanLogLevel.critical,
        message: 'NoOp Test',
      );

      expect(() => reporter.report(entry), returnsNormally);
    });

    test(
        '8. TitanBootstrap registers LogSink, ErrorReporter, TitanLogger, TitanErrorHandler',
        () async {
      final mockSink = _MockLogSink();
      final mockReporter = _MockErrorReporter();

      await TitanBootstrap.initialize(
        logSink: mockSink,
        errorReporter: mockReporter,
      );

      final locator = TitanServiceLocator();
      expect(locator.isRegistered<LogSink>(), isTrue);
      expect(locator.isRegistered<ErrorReporter>(), isTrue);
      expect(locator.isRegistered<TitanLogger>(), isTrue);
      expect(locator.isRegistered<TitanErrorHandler>(), isTrue);

      expect(locator.get<LogSink>(), equals(mockSink));
      expect(locator.get<ErrorReporter>(), equals(mockReporter));
    });
  });
}
