import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/grammar_issue.dart';

/// Repository contract for the grammar result cache.
///
/// Keys follow `grammar:<engineId>:<engineVersion>:<language>:<textHash>`
/// so an engine update never serves stale results (§22). The cache exists
/// so previously checked selections stay instantly available offline.
abstract class GrammarCacheRepository {
  /// Returns the cached result for [key], or null.
  Future<GrammarCheckResult?> load(String key);

  /// Stores [result] under [key].
  Future<void> save(String key, GrammarCheckResult result);

  /// Removes the cached result for [key]. No-op when absent.
  Future<void> delete(String key);

  /// Removes every cached result.
  Future<void> clearAll();

  /// Builds the canonical cache key for one checked text.
  static String keyFor({
    required String engineId,
    required String engineVersion,
    required String language,
    required String text,
  }) {
    return 'grammar:$engineId:$engineVersion:$language:'
        '${fnv1a64Hex(text)}';
  }
}

/// 64-bit FNV-1a hash of [text] rendered as lowercase hex.
///
/// A content hash is all a cache key needs; this avoids adding a crypto
/// dependency for Phase 4.
String fnv1a64Hex(String text) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  final units = utf8.encode(text);
  for (final unit in units) {
    hash ^= unit;
    hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
  }
  // Dart ints are signed 64-bit; render the two halves separately so
  // values with the high bit set never print a minus sign.
  final high = (hash >> 32) & 0xFFFFFFFF;
  final low = hash & 0xFFFFFFFF;
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}

/// [GrammarCacheRepository] backed by the shared TITAN [StorageService]
/// inside the Reader-specific `titan.reader.grammar.cache` namespace.
class StorageGrammarCacheRepository implements GrammarCacheRepository {
  /// Storage namespace used for all cached grammar results.
  static const String namespace = 'titan.reader.grammar.cache';

  final StorageService _storage;

  StorageGrammarCacheRepository(this._storage);

  StorageKey _keyFor(String key) => StorageKey(key, namespace: namespace);

  StorageKey get _indexKey => const StorageKey('index', namespace: namespace);

  Future<Set<String>> _readIndex() async {
    final raw = await _storage.read<String>(_indexKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.whereType<String>().toSet() : <String>{};
  }

  @override
  Future<GrammarCheckResult?> load(String key) async {
    final raw = await _storage.read<String>(_keyFor(key));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Grammar cache entry for "$key" is malformed.');
    }
    return GrammarCheckResult.fromJson(decoded);
  }

  @override
  Future<void> save(String key, GrammarCheckResult result) async {
    await _storage.write<String>(_keyFor(key), jsonEncode(result.toJson()));
    final index = await _readIndex();
    if (index.add(key)) {
      await _storage.write<String>(_indexKey, jsonEncode(index.toList()));
    }
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(_keyFor(key));
    final index = await _readIndex();
    if (index.remove(key)) {
      await _storage.write<String>(_indexKey, jsonEncode(index.toList()));
    }
  }

  @override
  Future<void> clearAll() async {
    // The storage service has no namespace-scan API, so the repository
    // tracks its own keys in a small index entry.
    final index = await _readIndex();
    for (final key in index) {
      await _storage.delete(_keyFor(key));
    }
    await _storage.delete(_indexKey);
  }
}
