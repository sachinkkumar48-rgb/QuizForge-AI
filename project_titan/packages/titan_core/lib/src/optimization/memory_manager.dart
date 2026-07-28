/// Callback signature for cache trimming upon memory pressure.
typedef MemoryTrimCallback = void Function(int level);

/// Memory Manager tracking memory limits, cache trim callbacks, and garbage collection hints.
class MemoryManager {
  final List<MemoryTrimCallback> _trimListeners = [];
  final int _cacheSizeLimit;
  int _currentCacheItemCount = 0;

  MemoryManager({int cacheSizeLimit = 1000}) : _cacheSizeLimit = cacheSizeLimit;

  /// Current configured max cache item limit.
  int get cacheSizeLimit => _cacheSizeLimit;

  /// Register a memory trim callback to be notified when memory pressure occurs.
  void registerTrimListener(MemoryTrimCallback callback) {
    _trimListeners.add(callback);
  }

  /// Remove a memory trim listener.
  void unregisterTrimListener(MemoryTrimCallback callback) {
    _trimListeners.remove(callback);
  }

  /// Simulates memory pressure event and triggers all trim listeners.
  /// [level]: 1 = mild (clear 25%), 2 = moderate (clear 50%), 3 = critical (clear 100%).
  void triggerMemoryPressure(int level) {
    for (final listener in _trimListeners) {
      try {
        listener(level);
      } catch (_) {}
    }
  }

  /// Updates current item count and checks if cache limit is exceeded.
  bool updateCacheCount(int count) {
    _currentCacheItemCount = count;
    return _currentCacheItemCount > _cacheSizeLimit;
  }

  /// Reset memory manager state.
  void reset() {
    _trimListeners.clear();
    _currentCacheItemCount = 0;
  }
}
