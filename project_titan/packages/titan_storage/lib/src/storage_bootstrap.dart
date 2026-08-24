import 'package:titan_core/titan_core.dart';

import 'hive_storage_service.dart';
import 'in_memory_storage_service.dart';
import 'storage_serializer.dart';
import 'storage_service.dart';
import 'titan_cache_manager.dart';

/// Central coordinator for storage layer initialization and dependency injection.
abstract class TitanStorageBootstrap {
  /// Initializes and registers [StorageService], [TitanCacheManager], and [StorageSerializerRegistry] in [TitanServiceLocator].
  static Future<StorageService> initializeStorage({
    StorageService? storageService,
    StorageSerializerRegistry? serializerRegistry,
    String? storagePath,
    bool useInMemory = false,
    TitanServiceLocator? locator,
  }) async {
    final serviceLocator = locator ?? TitanServiceLocator();
    final registry = serializerRegistry ?? StorageSerializerRegistry();

    serviceLocator.registerSingleton<StorageSerializerRegistry>(
      registry,
      allowOverride: true,
    );

    StorageService service = storageService ??
        (useInMemory
            ? InMemoryStorageService()
            : HiveStorageService(
                path: storagePath,
                serializerRegistry: registry,
              ));

    if (!service.isInitialized) {
      try {
        await service.initialize();
      } catch (_) {
        // Resilient fallback: if default persistent Hive storage fails during startup
        // (e.g. disk permissions or OS restrictions), fallback to in-memory storage
        // to guarantee the application can always complete bootstrap and render UI.
        if (!useInMemory && storageService == null) {
          service = InMemoryStorageService();
          await service.initialize();
        } else {
          rethrow;
        }
      }
    }

    serviceLocator.registerSingleton<StorageService>(
      service,
      allowOverride: true,
    );

    final cacheManager = TitanCacheManager(storageService: service);
    serviceLocator.registerSingleton<TitanCacheManager>(
      cacheManager,
      allowOverride: true,
    );

    return service;
  }
}
