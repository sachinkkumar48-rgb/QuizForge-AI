import 'storage_key.dart';
import 'storage_service.dart';

/// Centralized cache manager for storing, retrieving, checking, and invalidating cached data.
class TitanCacheManager {
  final StorageService _storageService;

  TitanCacheManager({required StorageService storageService})
      : _storageService = storageService;

  /// Store [value] under [key] in cache.
  Future<void> store<T>(StorageKey key, T value) async {
    await _storageService.write<T>(key, value);
  }

  /// Retrieve cached value for [key]. Returns null if not found or if expired (when [maxAge] is provided).
  Future<T?> retrieve<T>(StorageKey key, {Duration? maxAge}) async {
    if (maxAge != null) {
      final entry = await _storageService.readEntry<T>(key);
      if (entry == null) return null;
      final age = DateTime.now().difference(entry.updatedAt);
      if (age > maxAge) {
        await _storageService.delete(key);
        return null;
      }
      return entry.value;
    }
    return await _storageService.read<T>(key);
  }

  /// Returns true if an unexpired cache entry exists for [key].
  Future<bool> exists(StorageKey key, {Duration? maxAge}) async {
    if (maxAge != null) {
      final entry = await _storageService.readEntry<dynamic>(key);
      if (entry == null) return false;
      final age = DateTime.now().difference(entry.updatedAt);
      if (age > maxAge) {
        await _storageService.delete(key);
        return false;
      }
      return true;
    }
    return await _storageService.contains(key);
  }

  /// Remove [key] from cache.
  Future<void> remove(StorageKey key) async {
    await _storageService.delete(key);
  }

  /// Clear all entries from cache.
  Future<void> clear() async {
    await _storageService.clear();
  }
}
