import 'package:titan_core/titan_core.dart';

/// Abstract contract for registering a domain module's repositories into [TitanServiceLocator].
abstract class TitanRepositoryRegistrar {
  /// Registers all repositories owned by this domain module.
  void registerRepositories(TitanServiceLocator locator);

  /// Unregisters all repositories owned by this domain module.
  void unregisterRepositories(TitanServiceLocator locator);
}
