import 'package:titan_core/titan_core.dart';

/// Abstract contract that every TITAN domain module bootstrap must implement.
abstract class TitanModuleBootstrap {
  /// Initializes the domain module and its internal services.
  Future<void> initialize();

  /// Returns true if the module has been successfully initialized.
  bool get isInitialized;

  /// Registers module dependencies (repositories, services, factories) into [TitanServiceLocator].
  void registerDependencies(TitanServiceLocator locator);

  /// Validates module configuration and prerequisite service availability.
  void validate();

  /// Disposes of module resources and unregisters or closes internal services.
  Future<void> dispose();
}
