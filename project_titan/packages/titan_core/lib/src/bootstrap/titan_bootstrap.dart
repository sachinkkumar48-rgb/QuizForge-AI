import 'package:flutter/widgets.dart';

import '../config/titan_config.dart';
import '../config/titan_config_loader.dart';
import '../config/titan_environment.dart';
import '../di/service_locator.dart';
import '../error/error_reporter.dart';
import '../error/global_error_handler.dart';
import '../logging/log_sink.dart';
import '../logging/titan_log_level.dart';
import '../logging/titan_logger.dart';
import '../navigation/flutter_navigation_service.dart';
import '../navigation/navigation_service.dart';

/// Central startup bootstrap coordinator for Project TITAN monorepo.
class TitanBootstrap {
  static bool _isInitialized = false;

  /// Returns true if application bootstrap has completed.
  static bool get isInitialized => _isInitialized;

  /// Resets initialized state (useful for unit testing).
  static void reset() {
    _isInitialized = false;
  }

  /// Executes the core initialization sequence in Clean Architecture order:
  /// 1. WidgetsBinding initialization
  /// 2. Configuration loading & validation via [TitanConfigLoader]
  /// 3. Service Locator registration (Config, LogSink, ErrorReporter, Logger, NavigationService, TitanErrorHandler)
  /// 4. Global Error Handling setup
  static Future<TitanConfig> initialize({
    TitanEnvironment environment = TitanEnvironment.development,
    TitanConfigLoader configLoader = const TitanConfigLoader(),
    TitanConfig? customConfig,
    NavigationService? navigationService,
    ErrorReporter? errorReporter,
    LogSink? logSink,
    TitanLogger? logger,
    TitanErrorHandler? errorHandler,
  }) async {
    if (_isInitialized) {
      return TitanServiceLocator().get<TitanConfig>();
    }

    // 1. Ensure Flutter binding initialized
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Load & Validate Configuration through TitanConfigLoader
    final config = await configLoader.load(
      environment: environment,
      overrideConfig: customConfig,
    );

    final locator = TitanServiceLocator();
    locator.registerSingleton<TitanConfig>(config, allowOverride: true);

    // 3. Register LogSink
    final sink = logSink ?? const ConsoleLogSink();
    locator.registerSingleton<LogSink>(sink, allowOverride: true);

    // 4. Register ErrorReporter
    final reporter = errorReporter ?? const NoOpErrorReporter();
    locator.registerSingleton<ErrorReporter>(reporter, allowOverride: true);

    // 5. Setup Logger with Environment-Based Min Log Level
    final minLogLevel =
        TitanLogLevel.defaultForEnvironment(config.titanEnvironment);
    final logInstance = logger ??
        ConsoleTitanLogger(
          minLogLevel: minLogLevel,
          logSink: sink,
          errorReporter: reporter,
          enableDebugPrints: config.enableLogging,
        );
    locator.registerSingleton<TitanLogger>(logInstance, allowOverride: true);
    logInstance.info(
        'Initializing ${config.appName} (v${config.version}+${config.buildNumber}) in [${config.environment}] mode...');

    // 6. Setup Navigation Service
    final navService = navigationService ?? FlutterNavigationService();
    locator.registerSingleton<NavigationService>(navService,
        allowOverride: true);

    // 7. Setup & Register Global Error Handler
    final errHandler = errorHandler ??
        TitanErrorHandler(
          logger: logInstance,
          errorReporter: reporter,
        );
    locator.registerSingleton<TitanErrorHandler>(errHandler,
        allowOverride: true);
    errHandler.initialize();

    _isInitialized = true;
    logInstance.info('Project TITAN Core Bootstrap successfully initialized.');

    return config;
  }
}
