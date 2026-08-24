import 'package:hive_flutter/hive_flutter.dart';
import 'storage_entry.dart';
import 'storage_exception.dart';
import 'storage_key.dart';
import 'storage_serializer.dart';
import 'storage_service.dart';

/// Production-ready Hive-backed implementation of [StorageService].
class HiveStorageService implements StorageService {
  final String boxName;
  final String? path;
  Box<dynamic>? _box;
  final StorageSerializerRegistry _serializerRegistry;
  bool _isInitialized = false;
  bool _isClosed = false;

  HiveStorageService({
    this.boxName = 'titan_storage_box',
    this.path,
    Box<dynamic>? box,
    StorageSerializerRegistry? serializerRegistry,
  })  : _box = box,
        _serializerRegistry = serializerRegistry ?? StorageSerializerRegistry();

  @override
  bool get isInitialized => _isInitialized && _box != null && _box!.isOpen;

  void _checkState() {
    if (_isClosed) {
      throw const StorageClosedException('HiveStorageService has been closed.');
    }
    if (!isInitialized) {
      throw const StorageInitializationException(
          'HiveStorageService is not initialized.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isClosed) {
      throw const StorageClosedException(
          'Cannot initialize a closed HiveStorageService.');
    }
    if (isInitialized) return;

    try {
      if (_box == null || !_box!.isOpen) {
        if (path != null && path!.isNotEmpty) {
          Hive.init(path);
        } else {
          try {
            await Hive.initFlutter();
          } catch (_) {
            // Graceful fallback when running in non-Flutter Dart runtime environments (tests/CLI)
          }
        }
        _box = await Hive.openBox<dynamic>(boxName);
      }
      _isInitialized = true;
    } catch (e, st) {
      throw StorageInitializationException(
          'Failed to initialize Hive box "$boxName"', e, st);
    }
  }

  @override
  Future<bool> contains(StorageKey key) async {
    _checkState();
    try {
      return _box!.containsKey(key.qualifiedKey);
    } catch (e, st) {
      throw StorageReadException(
          'Error checking key existence: ${key.qualifiedKey}', e, st);
    }
  }

  @override
  Future<T?> read<T>(StorageKey key) async {
    final entry = await readEntry<T>(key);
    return entry?.value;
  }

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async {
    _checkState();
    try {
      final rawData = _box!.get(key.qualifiedKey);
      if (rawData == null) return null;

      if (rawData is Map) {
        final map = Map<String, dynamic>.from(rawData);
        final rawVal = map['value'];
        final createdAt = DateTime.parse(map['createdAt'] as String);
        final updatedAt = DateTime.parse(map['updatedAt'] as String);

        final deserializedVal = _serializerRegistry.deserialize<T>(rawVal);

        return StorageEntry<T>.constEntry(
          key: key,
          value: deserializedVal,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      } else {
        final deserializedVal = _serializerRegistry.deserialize<T>(rawData);
        final now = DateTime.now();
        return StorageEntry<T>.constEntry(
          key: key,
          value: deserializedVal,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e, st) {
      if (e is StorageException) rethrow;
      throw StorageReadException(
          'Failed to read key "${key.qualifiedKey}"', e, st);
    }
  }

  @override
  Future<void> write<T>(StorageKey key, T value) async {
    _checkState();
    try {
      final now = DateTime.now();
      final existingRaw = _box!.get(key.qualifiedKey);
      DateTime createdAt = now;

      if (existingRaw is Map) {
        final existingMap = Map<String, dynamic>.from(existingRaw);
        if (existingMap['createdAt'] != null) {
          createdAt = DateTime.parse(existingMap['createdAt'] as String);
        }
      }

      final serializedValue = _serializerRegistry.serialize<T>(value);

      final payload = <String, dynamic>{
        'key': key.rawKey,
        'namespace': key.namespace,
        'value': serializedValue,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _box!.put(key.qualifiedKey, payload);
    } catch (e, st) {
      if (e is StorageException) rethrow;
      throw StorageWriteException(
          'Failed to write key "${key.qualifiedKey}"', e, st);
    }
  }

  @override
  Future<void> delete(StorageKey key) async {
    _checkState();
    try {
      await _box!.delete(key.qualifiedKey);
    } catch (e, st) {
      throw StorageDeleteException(
          'Failed to delete key "${key.qualifiedKey}"', e, st);
    }
  }

  @override
  Future<void> clear() async {
    _checkState();
    try {
      await _box!.clear();
    } catch (e, st) {
      throw StorageDeleteException(
          'Failed to clear storage box "$boxName"', e, st);
    }
  }

  @override
  Future<List<StorageKey>> keys({String? namespace}) async {
    _checkState();
    try {
      final keysList = <StorageKey>[];
      for (final rawKey in _box!.keys) {
        final keyStr = rawKey.toString();
        final rawData = _box!.get(keyStr);

        if (rawData is Map) {
          final map = Map<String, dynamic>.from(rawData);
          final k = map['key'] as String? ?? keyStr;
          final ns = map['namespace'] as String?;
          final storageKey = StorageKey(k, namespace: ns);

          if (namespace == null || namespace.isEmpty || ns == namespace) {
            keysList.add(storageKey);
          }
        } else {
          final storageKey = StorageKey(keyStr);
          if (namespace == null || namespace.isEmpty) {
            keysList.add(storageKey);
          }
        }
      }
      return keysList;
    } catch (e, st) {
      throw StorageReadException('Failed to retrieve keys', e, st);
    }
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
      _isInitialized = false;
      _isClosed = true;
    } catch (e, st) {
      throw StorageDeleteException(
          'Failed to close storage box "$boxName"', e, st);
    }
  }
}
