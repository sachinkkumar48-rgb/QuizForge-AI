import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/dictionary_entry.dart';

/// A dictionary entry cached after a remote lookup, with provenance.
@immutable
class CachedDictionaryEntry {
  /// The cached entry itself.
  final DictionaryEntry entry;

  /// Identifier of the source that produced the entry.
  final String sourceId;

  /// Source/dataset version, when the source provides one.
  final String? sourceVersion;

  /// When the entry was fetched.
  final DateTime fetchedAt;

  const CachedDictionaryEntry({
    required this.entry,
    required this.sourceId,
    required this.fetchedAt,
    this.sourceVersion,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'sourceVersion': sourceVersion,
        'fetchedAt': fetchedAt.toIso8601String(),
        'entry': entry.toJson(),
      };

  /// Deserializes a [CachedDictionaryEntry]; throws [FormatException] on
  /// malformed required fields.
  factory CachedDictionaryEntry.fromJson(Map<String, Object?> json) {
    final sourceId = json['sourceId'];
    final fetchedAt = json['fetchedAt'];
    final entry = json['entry'];
    if (sourceId is! String || fetchedAt is! String || entry is! Map) {
      throw const FormatException(
          'CachedDictionaryEntry JSON requires sourceId, fetchedAt and '
          'entry fields.');
    }
    final sourceVersion = json['sourceVersion'];
    return CachedDictionaryEntry(
      entry: DictionaryEntry.fromJson(Map<String, Object?>.from(entry)),
      sourceId: sourceId,
      sourceVersion: sourceVersion is String ? sourceVersion : null,
      fetchedAt: DateTime.parse(fetchedAt),
    );
  }
}

/// Repository contract for the remote-lookup dictionary cache.
///
/// Keys follow the `dictionary:<normalizedWord>` shape. The cache exists so
/// previously resolved remote words keep working offline; it never shadows
/// the bundled local dictionary.
abstract class DictionaryCacheRepository {
  /// Returns the cached entry for [normalizedWord], or null.
  Future<CachedDictionaryEntry?> load(String normalizedWord);

  /// Stores [cached] under [normalizedWord].
  Future<void> save(String normalizedWord, CachedDictionaryEntry cached);

  /// Removes the cached entry for [normalizedWord]. No-op when absent.
  Future<void> delete(String normalizedWord);

  /// Removes every cached entry.
  Future<void> clearAll();
}

/// [DictionaryCacheRepository] backed by the shared TITAN [StorageService]
/// inside the Reader-specific `titan.reader.dictionary.cache` namespace.
class StorageDictionaryCacheRepository implements DictionaryCacheRepository {
  /// Storage namespace used for all cached dictionary entries.
  static const String namespace = 'titan.reader.dictionary.cache';

  final StorageService _storage;

  StorageDictionaryCacheRepository(this._storage);

  StorageKey _keyFor(String normalizedWord) =>
      StorageKey('dictionary:$normalizedWord', namespace: namespace);

  StorageKey get _indexKey => const StorageKey('index', namespace: namespace);

  Future<Set<String>> _readIndex() async {
    final raw = await _storage.read<String>(_indexKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.whereType<String>().toSet() : <String>{};
  }

  @override
  Future<CachedDictionaryEntry?> load(String normalizedWord) async {
    final raw = await _storage.read<String>(_keyFor(normalizedWord));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException(
          'Dictionary cache entry for "$normalizedWord" is malformed.');
    }
    return CachedDictionaryEntry.fromJson(decoded);
  }

  @override
  Future<void> save(String normalizedWord, CachedDictionaryEntry cached) async {
    await _storage.write<String>(
        _keyFor(normalizedWord), jsonEncode(cached.toJson()));
    final index = await _readIndex();
    if (index.add(normalizedWord)) {
      await _storage.write<String>(_indexKey, jsonEncode(index.toList()));
    }
  }

  @override
  Future<void> delete(String normalizedWord) async {
    await _storage.delete(_keyFor(normalizedWord));
    final index = await _readIndex();
    if (index.remove(normalizedWord)) {
      await _storage.write<String>(_indexKey, jsonEncode(index.toList()));
    }
  }

  @override
  Future<void> clearAll() async {
    // The storage service has no namespace-scan API, so the repository
    // tracks its own keys in a small index entry.
    final index = await _readIndex();
    for (final word in index) {
      await _storage.delete(_keyFor(word));
    }
    await _storage.delete(_indexKey);
  }
}
