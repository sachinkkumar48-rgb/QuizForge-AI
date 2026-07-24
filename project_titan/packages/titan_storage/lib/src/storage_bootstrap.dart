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

    final StorageService service = storageService ??
        (useInMemory
            ? InMemoryStorageService()
            : HiveStorageService(
                path: storagePath,
                serializerRegistry: registry,
              ));

    if (!service.isInitialized) {
      await service.initialize();
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
