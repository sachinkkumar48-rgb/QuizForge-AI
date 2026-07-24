import 'ai_exception.dart';
import 'ai_provider.dart';

/// Registry maintaining registered [AIProvider] implementations in Project TITAN.
class AIProviderRegistry {
  final Map<String, AIProvider> _providers = {};
  String? _defaultProviderName;

  /// Register a provider in the registry.
  void register(AIProvider provider, {bool setAsDefault = false}) {
    _providers[provider.name.toLowerCase()] = provider;
    if (setAsDefault || _defaultProviderName == null) {
      _defaultProviderName = provider.name.toLowerCase();
    }
  }

  /// Unregister a provider by name.
  void unregister(String name) {
    final key = name.toLowerCase();
    _providers.remove(key);
    if (_defaultProviderName == key) {
      _defaultProviderName =
          _providers.keys.isNotEmpty ? _providers.keys.first : null;
    }
  }

  /// Get a registered provider by name. Throws [AIProviderException] if not found.
  AIProvider provider(String name) {
    final key = name.toLowerCase();
    final prov = _providers[key];
    if (prov == null) {
      throw AIProviderException('AI Provider "$name" is not registered.', name);
    }
    return prov;
  }

  /// Returns the default provider. Throws [AIProviderException] if no providers are registered.
  AIProvider defaultProvider() {
    if (_defaultProviderName == null ||
        !_providers.containsKey(_defaultProviderName)) {
      if (_providers.isNotEmpty) {
        return _providers.values.first;
      }
      throw const AIProviderException(
          'No AI providers registered in registry.');
    }
    return _providers[_defaultProviderName!]!;
  }

  /// List of all registered providers.
  List<AIProvider> get providers => List.unmodifiable(_providers.values);
}
