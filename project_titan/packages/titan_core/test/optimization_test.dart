import 'package:flutter_test/flutter_test.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Titan Core Performance Optimization Suite Unit Tests', () {
    test('StartupOptimizer measures phase execution and defers tasks',
        () async {
      final optimizer = StartupOptimizer()..start();
      final result = await optimizer.runPhase('config_load', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'loaded';
      });

      expect(result, equals('loaded'));
      expect(optimizer.metrics.length, equals(1));
      expect(optimizer.metrics.first.phaseName, equals('config_load'));
      expect(optimizer.metrics.first.success, isTrue);

      optimizer.stop();
      expect(optimizer.totalStartupDuration.inMilliseconds,
          greaterThanOrEqualTo(0));
    });

    test('MemoryManager registers listeners and handles pressure events', () {
      final manager = MemoryManager(cacheSizeLimit: 50);
      int pressureLevelCaptured = 0;

      manager.registerTrimListener((level) {
        pressureLevelCaptured = level;
      });

      expect(manager.updateCacheCount(30), isFalse);
      expect(manager.updateCacheCount(60), isTrue);

      manager.triggerMemoryPressure(2);
      expect(pressureLevelCaptured, equals(2));

      manager.reset();
      expect(manager.cacheSizeLimit, equals(50));
    });

    test('LazyLoader initializes instance on demand and allows reset',
        () async {
      int initCount = 0;
      final loader = LazyLoader<String>(() {
        initCount++;
        return 'initialized_value_$initCount';
      });

      expect(loader.isInitialized, isFalse);
      expect(loader.instanceOrNull, isNull);

      final val1 = await loader.instance;
      expect(val1, equals('initialized_value_1'));
      expect(loader.isInitialized, isTrue);
      expect(initCount, equals(1));

      final val2 = await loader.instance;
      expect(val2, equals('initialized_value_1'));
      expect(initCount, equals(1));

      loader.reset();
      expect(loader.isInitialized, isFalse);
    });

    test('BackgroundWorker batches item processing without UI thread lockup',
        () async {
      final items = List.generate(100, (i) => i);
      final results = await BackgroundWorker.processBatch<int, int>(
        items: items,
        worker: (item) => item * 2,
        chunkSize: 20,
      );

      expect(results.length, equals(100));
      expect(results.first, equals(0));
      expect(results.last, equals(198));
    });

    test(
        'TitanCacheOptimizer handles put, get, LRU eviction, and TTL expiration',
        () {
      final cache = TitanCacheOptimizer<String, String>(
        maxCapacity: 2,
        defaultTtl: const Duration(minutes: 5),
      );

      cache.put('k1', 'v1');
      cache.put('k2', 'v2');
      expect(cache.get('k1'), equals('v1'));
      expect(cache.get('k2'), equals('v2'));

      // Third put triggers LRU eviction
      cache.put('k3', 'v3');
      expect(cache.length, equals(2));

      cache.clear();
      expect(cache.length, equals(0));
    });
  });
}
