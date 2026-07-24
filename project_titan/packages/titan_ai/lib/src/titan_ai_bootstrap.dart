import 'package:titan_core/titan_core.dart';
import 'package:titan_network/titan_network.dart';

import 'ai_exception.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';
import 'ai_service.dart';
import 'gemini_provider.dart';
import 'titan_ai_service.dart';

/// Central startup coordinator for Project TITAN AI foundation layer.
abstract class TitanAIBootstrap {
  /// Initializes and registers [AIProviderRegistry], [GeminiProvider], and [AIService] in [TitanServiceLocator].
  static Future<AIService> initialize({
    TitanConfig? config,
    String? geminiApiKey,
    NetworkService? networkService,
    AIProviderRegistry? registry,
    AIProvider? customProvider,
    String? preferredProviderName,
    TitanServiceLocator? locator,
  }) async {
    final serviceLocator = locator ?? TitanServiceLocator();

    final titanConfig = config ??
        (serviceLocator.isRegistered<TitanConfig>()
            ? serviceLocator.get<TitanConfig>()
            : TitanConfig.defaultConfig());

    titanConfig.validate();

    final apiKey = geminiApiKey ?? titanConfig.aiApiKey;
    final netService = networkService ??
        (serviceLocator.isRegistered<NetworkService>()
            ? serviceLocator.get<NetworkService>()
            : null);

    final providerRegistry = registry ?? AIProviderRegistry();

    if (customProvider != null) {
      providerRegistry.register(customProvider, setAsDefault: true);
    } else if (apiKey.isNotEmpty && netService != null) {
      final gemini = GeminiProvider(
        apiKey: apiKey,
        networkService: netService,
        defaultModelId: titanConfig.aiDefaultModel,
        timeout: titanConfig.aiTimeout,
      );
      providerRegistry.register(gemini, setAsDefault: true);
      serviceLocator.registerSingleton<GeminiProvider>(
        gemini,
        allowOverride: true,
      );
    } else if (apiKey.isEmpty && customProvider == null) {
      throw const AIInitializationException(
        'AI API Key missing from configuration and no custom provider supplied.',
      );
    }

    serviceLocator.registerSingleton<AIProviderRegistry>(
      providerRegistry,
      allowOverride: true,
    );

    final AIService aiService = TitanAIService(
      registry: providerRegistry,
      preferredProviderName: preferredProviderName,
    );

    if (providerRegistry.providers.isNotEmpty && !aiService.isInitialized) {
      await aiService.initialize();
    }

    serviceLocator.registerSingleton<AIService>(
      aiService,
      allowOverride: true,
    );

    return aiService;
  }
}
