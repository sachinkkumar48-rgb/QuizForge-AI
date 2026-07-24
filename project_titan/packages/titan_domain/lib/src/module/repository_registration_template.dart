import 'package:titan_core/titan_core.dart';
import 'titan_repository_registrar.dart';

/// Reference implementation template for registering domain repositories into [TitanServiceLocator].
abstract class RepositoryRegistrationTemplate
    implements TitanRepositoryRegistrar {
  /// Protected registration helper method.
  void registerRepository<R extends Object>(
    TitanServiceLocator locator,
    R Function() factory, {
    bool isSingleton = true,
    bool allowOverride = true,
  }) {
    if (isSingleton) {
      locator.registerLazySingleton<R>(factory, allowOverride: allowOverride);
    } else {
      locator.registerFactory<R>(factory, allowOverride: allowOverride);
    }
  }

  /// Protected unregistration helper method.
  void unregisterRepository<R extends Object>(TitanServiceLocator locator) {
    if (locator.isRegistered<R>()) {
      locator.unregister<R>();
    }
  }
}
