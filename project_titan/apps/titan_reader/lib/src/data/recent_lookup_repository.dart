import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/recent_lookup.dart';

/// Repository contract for the recent dictionary lookup history.
abstract class RecentLookupRepository {
  /// Returns the stored lookups, most recent first.
  Future<List<RecentDictionaryLookup>> load();

  /// Replaces the stored lookup list.
  Future<void> saveAll(List<RecentDictionaryLookup> lookups);

  /// Deletes the stored history. No-op when absent.
  Future<void> clear();
}

/// [RecentLookupRepository] backed by the shared TITAN [StorageService].
///
/// Single storage entry inside the Reader-specific
/// `titan.reader.dictionary.recent` namespace; the history is Reader data
/// and stays separate from QuizForge.
class StorageRecentLookupRepository implements RecentLookupRepository {
  /// Storage namespace used for the dictionary lookup history.
  static const String namespace = 'titan.reader.dictionary.recent';

  final StorageService _storage;

  StorageRecentLookupRepository(this._storage);

  StorageKey get _key => const StorageKey('lookups', namespace: namespace);

  @override
  Future<List<RecentDictionaryLookup>> load() async {
    final raw = await _storage.read<String>(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException(
          'Recent dictionary lookup store is malformed.');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(RecentDictionaryLookup.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(List<RecentDictionaryLookup> lookups) {
    final payload = jsonEncode(lookups.map((l) => l.toJson()).toList());
    return _storage.write<String>(_key, payload);
  }

  @override
  Future<void> clear() {
    return _storage.delete(_key);
  }
}
