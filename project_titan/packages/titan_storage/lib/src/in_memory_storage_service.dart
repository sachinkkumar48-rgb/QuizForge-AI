import 'storage_entry.dart';
import 'storage_exception.dart';
import 'storage_key.dart';
import 'storage_service.dart';

/// In-memory implementation of [StorageService] for testing and transient storage.
class InMemoryStorageService implements StorageService {
  final Map<String, StorageEntry<dynamic>> _storage = {};
  bool _isInitialized = false;
  bool _isClosed = false;

  @override
  bool get isInitialized => _isInitialized;

  /// Returns true if this storage instance has been closed.
  bool get isClosed => _isClosed;

  void _checkState() {
    if (_isClosed) {
      throw const StorageClosedException('StorageService has been closed.');
    }
    if (!_isInitialized) {
      throw const StorageInitializationException(
          'StorageService is not initialized.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isClosed) {
      throw const StorageClosedException(
          'Cannot initialize a closed StorageService.');
    }
    _isInitialized = true;
  }

  @override
  Future<bool> contains(StorageKey key) async {
    _checkState();
    return _storage.containsKey(key.qualifiedKey);
  }

  @override
  Future<T?> read<T>(StorageKey key) async {
    _checkState();
    final entry = _storage[key.qualifiedKey];
    if (entry == null) return null;

    if (entry.value is! T && T != dynamic) {
      throw StorageReadException(
        'Type mismatch for key "${key.qualifiedKey}". Expected $T but found ${entry.value.runtimeType}.',
      );
    }
    return entry.value as T?;
  }

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async {
    _checkState();
    final entry = _storage[key.qualifiedKey];
    if (entry == null) return null;

    if (entry.value is! T && T != dynamic) {
      throw StorageReadException(
        'Type mismatch for entry key "${key.qualifiedKey}". Expected $T but found ${entry.value.runtimeType}.',
      );
    }

    return StorageEntry<T>.constEntry(
      key: entry.key,
      value: entry.value as T,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  @override
  Future<void> write<T>(StorageKey key, T value) async {
    _checkState();
    final now = DateTime.now();
    final existing = _storage[key.qualifiedKey];

    if (existing != null) {
      _storage[key.qualifiedKey] = StorageEntry<dynamic>.constEntry(
        key: key,
        value: value,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    } else {
      _storage[key.qualifiedKey] = StorageEntry<dynamic>.constEntry(
        key: key,
        value: value,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  @override
  Future<void> delete(StorageKey key) async {
    _checkState();
    _storage.remove(key.qualifiedKey);
  }

  @override
  Future<void> clear() async {
    _checkState();
    _storage.clear();
  }

  @override
  Future<List<StorageKey>> keys({String? namespace}) async {
    _checkState();
    if (namespace == null || namespace.isEmpty) {
      return _storage.values.map((e) => e.key).toList();
    }
    return _storage.values
        .where((e) => e.key.namespace == namespace)
        .map((e) => e.key)
        .toList();
  }

  @override
  Future<void> close() async {
    _storage.clear();
    _isInitialized = false;
    _isClosed = true;
  }
}
