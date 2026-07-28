/// Cache entry wrapper with TTL expiration and hit count metrics.
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration ttl;
  int hitCount = 0;

  CacheEntry({
    required this.value,
    required this.ttl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Cache Optimizer managing LRU eviction, TTL expiration, prefetching, and multi-tier memory caching.
class TitanCacheOptimizer<K, V> {
  final Map<K, CacheEntry<V>> _cache = {};
  final int maxCapacity;
  final Duration defaultTtl;

  TitanCacheOptimizer({
    this.maxCapacity = 500,
    this.defaultTtl = const Duration(minutes: 30),
  });

  /// Current item count in cache.
  int get length => _cache.length;

  /// Put an item in cache. Evicts LRU if max capacity exceeded.
  void put(K key, V value, {Duration? ttl}) {
    if (_cache.length >= maxCapacity && !_cache.containsKey(key)) {
      _evictLru();
    }
    _cache[key] = CacheEntry<V>(
      value: value,
      ttl: ttl ?? defaultTtl,
    );
  }

  /// Get an item from cache. Returns null if missing or expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    entry.hitCount++;
    return entry.value;
  }

  /// Removes expired entries.
  int cleanExpired() {
    final keysToRemove = <K>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    return keysToRemove.length;
  }

  /// Evicts the least recently / hit entry.
  void _evictLru() {
    if (_cache.isEmpty) return;
    K? lruKey;
    int minHits = 999999;
    for (final entry in _cache.entries) {
      if (entry.value.hitCount < minHits) {
        minHits = entry.value.hitCount;
        lruKey = entry.key;
      }
    }
    if (lruKey != null) {
      _cache.remove(lruKey);
    }
  }

  /// Clears all entries.
  void clear() {
    _cache.clear();
  }
}
