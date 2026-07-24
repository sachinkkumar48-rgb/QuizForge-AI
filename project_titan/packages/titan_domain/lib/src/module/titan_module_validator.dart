import 'package:titan_core/titan_core.dart';
import '../repository_exception.dart';
import 'titan_module_bootstrap.dart';
import 'titan_module_config.dart';

/// Helper utility for validating TITAN domain module configuration, bootstrap readiness, and DI registrations.
abstract class TitanModuleValidator {
  /// Validates that a module bootstrap is initialized.
  static void validateBootstrap(TitanModuleBootstrap bootstrap) {
    if (!bootstrap.isInitialized) {
      throw RepositoryInitializationException(
        'Module bootstrap [${bootstrap.runtimeType}] is not initialized.',
      );
    }
  }

  /// Validates module configuration fields.
  static void validateConfig(TitanModuleConfig config) {
    if (config.moduleName.trim().isEmpty) {
      throw const TitanInvalidConfigException(
          'Module configuration [moduleName] cannot be empty.');
    }
    if (config.moduleVersion.trim().isEmpty) {
      throw const TitanInvalidConfigException(
          'Module configuration [moduleVersion] cannot be empty.');
    }
  }

  /// Validates that all [requiredTypes] are registered in [locator].
  static void validateRegisteredServices(
    TitanServiceLocator locator,
    List<Type> requiredTypes,
  ) {
    for (final serviceType in requiredTypes) {
      final isRegistered = locator.isRegisteredType(serviceType);
      if (!isRegistered) {
        throw TitanMissingDependencyException(serviceType);
      }
    }
  }
}
