import 'package:titan_core/titan_core.dart';

import 'ports/ports.dart';

import 'cache_strategy.dart';
import 'repository_exception.dart';

/// Central startup bootstrap coordinator for Project TITAN repository foundation layer.
abstract class TitanRepositoryBootstrap {
  /// Validates infrastructure availability and registers shared repository services (e.g. [CacheStrategy]) in [TitanServiceLocator].
  static Future<void> initialize({
    TitanConfig? config,
    CacheStrategy? cacheStrategy,
    TitanServiceLocator? locator,
  }) async {
    final serviceLocator = locator ?? TitanServiceLocator.instance;

    final titanConfig = config ??
        (serviceLocator.isRegistered<TitanConfig>()
            ? serviceLocator.get<TitanConfig>()
            : TitanConfig.defaultConfig());

    titanConfig.validate();

    // Validate that infrastructure services are registered in TitanServiceLocator
    if (!serviceLocator.isRegistered<AIService>()) {
      throw const RepositoryInitializationException(
        'AIService must be registered in TitanServiceLocator before initializing Repository Foundation.',
      );
    }
    if (!serviceLocator.isRegistered<StorageService>()) {
      throw const RepositoryInitializationException(
        'StorageService must be registered in TitanServiceLocator before initializing Repository Foundation.',
      );
    }
    if (!serviceLocator.isRegistered<NetworkService>()) {
      throw const RepositoryInitializationException(
        'NetworkService must be registered in TitanServiceLocator before initializing Repository Foundation.',
      );
    }

    final defaultStrategy = cacheStrategy ??
        CacheFirstStrategy(defaultTtl: titanConfig.repositoryCacheTtl);

    serviceLocator.registerSingleton<CacheStrategy>(
      defaultStrategy,
      allowOverride: true,
    );
  }
}
