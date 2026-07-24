import 'ai_provider.dart';

enum AiProviderType {
  gemini,
  openAi,
  claude,
  localLlm,
}

class AiProviderFactory {
  static final Map<AiProviderType, AIProvider> _providers = {};
  static AiProviderType _activeProviderType = AiProviderType.gemini;

  static void registerProvider(AiProviderType type, AIProvider provider) {
    _providers[type] = provider;
  }

  static AIProvider? getProvider(AiProviderType type) {
    return _providers[type];
  }

  static void setActiveProvider(AiProviderType type) {
    _activeProviderType = type;
  }

  static AiProviderType get activeProviderType => _activeProviderType;

  static AIProvider getActiveProvider() {
    final provider = _providers[_activeProviderType];
    if (provider == null) {
      throw StateError(
        "AIProvider for type '$_activeProviderType' is not registered.",
      );
    }
    return provider;
  }

  static List<AIProvider> getRegisteredProviders() {
    return _providers.values.toList();
  }

  static void reset() {
    _providers.clear();
    _activeProviderType = AiProviderType.gemini;
  }
}
