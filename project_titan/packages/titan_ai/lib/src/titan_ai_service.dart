import 'ai_exception.dart';
import 'ai_model.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';
import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_service.dart';

/// Concrete implementation of [AIService] routing requests to [AIProviderRegistry].
class TitanAIService implements AIService {
  final AIProviderRegistry _registry;
  final String? _preferredProviderName;
  bool _isInitialized = false;
  bool _isClosed = false;

  TitanAIService({
    required AIProviderRegistry registry,
    String? preferredProviderName,
  })  : _registry = registry,
        _preferredProviderName = preferredProviderName;

  @override
  bool get isInitialized => _isInitialized && !_isClosed;

  void _checkState() {
    if (_isClosed) {
      throw const AIInitializationException('TitanAIService has been closed.');
    }
    if (!isInitialized) {
      throw const AIInitializationException(
          'TitanAIService is not initialized.');
    }
  }

  AIProvider _activeProvider() {
    final pref = _preferredProviderName;
    if (pref != null && pref.isNotEmpty) {
      return _registry.provider(pref);
    }
    return _registry.defaultProvider();
  }

  @override
  Future<void> initialize() async {
    if (_isClosed) {
      throw const AIInitializationException(
          'Cannot initialize closed TitanAIService.');
    }
    final provider = _activeProvider();
    if (!provider.isInitialized) {
      await provider.initialize();
    }
    _isInitialized = true;
  }

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    _checkState();
    final provider = _activeProvider();
    return await provider.generate<T>(request);
  }

  @override
  List<AIModel> availableModels() {
    _checkState();
    final models = <AIModel>[];
    for (final prov in _registry.providers) {
      models.addAll(prov.models());
    }
    return models;
  }

  @override
  AIModel defaultModel() {
    _checkState();
    return _activeProvider().defaultModel();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
    _isClosed = true;
    for (final prov in _registry.providers) {
      if (prov.isInitialized) {
        await prov.close();
      }
    }
  }
}
