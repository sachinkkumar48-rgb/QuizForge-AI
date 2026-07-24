/// Abstract caching strategy controlling when repositories read from cache, write to cache, or refresh from source.
abstract class CacheStrategy {
  /// Returns true if the repository should read from cache given the optional cache timestamp and TTL.
  bool shouldReadCache({DateTime? cachedAt, Duration? ttl});

  /// Returns true if the repository should persist fetched data into cache.
  bool shouldWriteCache();

  /// Returns true if the repository should bypass valid cache and refresh from source.
  bool shouldRefresh({DateTime? cachedAt, Duration? ttl});
}

/// Cache-First Strategy implementation:
/// Reads from cache if a valid non-expired cached item exists; otherwise fetches from remote/AI source and updates cache.
class CacheFirstStrategy implements CacheStrategy {
  final Duration defaultTtl;

  const CacheFirstStrategy({
    this.defaultTtl = const Duration(minutes: 15),
  });

  @override
  bool shouldReadCache({DateTime? cachedAt, Duration? ttl}) {
    if (cachedAt == null) return false;
    final effectiveTtl = ttl ?? defaultTtl;
    final age = DateTime.now().difference(cachedAt);
    return age < effectiveTtl;
  }

  @override
  bool shouldWriteCache() => true;

  @override
  bool shouldRefresh({DateTime? cachedAt, Duration? ttl}) {
    return !shouldReadCache(cachedAt: cachedAt, ttl: ttl);
  }
}
