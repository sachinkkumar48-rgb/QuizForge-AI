library;

import '../domain/entities/ai_reading_models.dart';

/// Cancellation token to abort in-flight AI requests or streams.
class AICancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }

  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// Abstract contract for AI reading providers in TITAN Reader.
abstract class AIReadingProvider {
  /// Provider identifier (e.g. 'local.ollama', 'openai_compatible', 'gemini', 'mock').
  String get providerId;

  /// Human-readable display name.
  String get displayName;

  /// Whether this provider runs locally on the user machine / local network.
  bool get isLocal;

  /// Discovers available models supported by this provider.
  Future<List<AIModelInfo>> listModels();

  /// Executes a non-streaming completion for [request].
  Future<AIReadingResponse> generate(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  });

  /// Streams token-by-token response content for [request].
  Stream<String> generateStream(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  });
}
