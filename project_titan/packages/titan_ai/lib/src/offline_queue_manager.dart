import 'dart:collection';

import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_token_usage.dart';

/// Queued item model for offline request buffering.
class QueuedAIRequest {
  final String id;
  final AIRequest request;
  final DateTime createdAt;
  int retryAttempts;

  QueuedAIRequest({
    required this.id,
    required this.request,
    required this.createdAt,
    this.retryAttempts = 0,
  });
}

/// Pure Dart offline queue manager for offline-first AI processing.
class OfflineQueueManager {
  final Queue<QueuedAIRequest> _queue = Queue<QueuedAIRequest>();
  bool _isOnline = true;

  /// Network online status indicator.
  bool get isOnline => _isOnline;

  /// Sets online state and triggers queue processing.
  void setOnlineStatus(bool online) {
    _isOnline = online;
  }

  /// Number of pending queued requests.
  int get pendingCount => _queue.length;

  /// Enqueues request for background retry when offline.
  QueuedAIRequest enqueue(AIRequest request) {
    final queued = QueuedAIRequest(
      id: 'req_${DateTime.now().microsecondsSinceEpoch}',
      request: request,
      createdAt: DateTime.now(),
    );
    _queue.add(queued);
    return queued;
  }

  /// Dequeues next request from front of queue.
  QueuedAIRequest? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  /// Returns unmodifiable list of queued requests.
  List<QueuedAIRequest> get queuedRequests =>
      List.unmodifiable(_queue.toList());

  /// Generates graceful offline fallback response when network is unavailable.
  AIResponse<T> generateOfflineFallback<T>(
    AIRequest request, {
    String? fallbackMessage,
  }) {
    final text = fallbackMessage ??
        '[Offline Mode] Device is currently offline. Your request has been queued and will process automatically when connectivity is restored.';

    return AIResponse<T>(
      text: text,
      data: null,
      usage: const AITokenUsage(
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
      ),
      model: request.model ?? 'offline-fallback',
      provider: 'offline_queue',
      finishReason: 'OFFLINE_QUEUED',
      createdAt: DateTime.now(),
    );
  }

  /// Clears queue.
  void clear() {
    _queue.clear();
  }
}
