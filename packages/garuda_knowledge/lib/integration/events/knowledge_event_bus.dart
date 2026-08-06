import 'knowledge_events.dart';

typedef KnowledgeEventListener<T extends KnowledgeEvent> = void Function(T event);

/// Central event bus for propagating Knowledge Engine lifecycle and data mutation events.
class KnowledgeEventBus {
  final Map<Type, List<Function>> _listeners = {};

  void subscribe<T extends KnowledgeEvent>(KnowledgeEventListener<T> listener) {
    _listeners.putIfAbsent(T, () => []).add(listener);
  }

  void unsubscribe<T extends KnowledgeEvent>(KnowledgeEventListener<T> listener) {
    _listeners[T]?.remove(listener);
  }

  void publish<T extends KnowledgeEvent>(T event) {
    final list = _listeners[T];
    if (list != null) {
      for (final listener in List<Function>.from(list)) {
        (listener as KnowledgeEventListener<T>)(event);
      }
    }
  }

  void clear() {
    _listeners.clear();
  }
}
