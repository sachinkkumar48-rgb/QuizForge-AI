import '../domain/entities/dictionary_entry.dart';

/// Contract for offline-capable dictionary data sources.
///
/// Implementations hide their storage technology (bundled assets, SQLite,
/// compressed files) from the rest of the application; callers only see
/// domain [DictionaryEntry] objects.
abstract class DictionaryDataSource {
  /// Stable identifier of this source (e.g. `wordnet-3.0`).
  String get sourceId;

  /// Attribution text required by the source license, shown in the UI
  /// and stored with cached entries.
  String get attribution;

  /// Number of headwords covered by this source, when known.
  int? get wordCount;

  /// Looks up [normalizedWord] (already normalized by the caller).
  /// Returns null when the source has no entry for the word.
  Future<DictionaryEntry?> lookup(String normalizedWord);

  /// Headwords starting with [prefix], in alphabetical order.
  ///
  /// Implementations may cap the result at [limit]; empty prefix or
  /// unsupported indexing returns an empty list.
  Future<List<String>> prefixMatches(String prefix, {int limit = 10});
}

/// In-memory [DictionaryDataSource] for tests and previews.
class InMemoryDictionaryDataSource implements DictionaryDataSource {
  InMemoryDictionaryDataSource(
    this.entries, {
    this.sourceId = 'test-dictionary',
    this.attribution = 'Test dictionary',
  });

  /// Entries keyed by normalized word.
  final Map<String, DictionaryEntry> entries;

  @override
  final String sourceId;

  @override
  final String attribution;

  @override
  int? get wordCount => entries.length;

  @override
  Future<DictionaryEntry?> lookup(String normalizedWord) async =>
      entries[normalizedWord];

  @override
  Future<List<String>> prefixMatches(String prefix, {int limit = 10}) async {
    if (prefix.isEmpty) return const [];
    final matches =
        entries.keys.where((word) => word.startsWith(prefix)).toList()..sort();
    return matches.take(limit).toList();
  }
}
