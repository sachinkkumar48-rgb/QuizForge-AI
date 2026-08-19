import '../data/dictionary_cache_repository.dart';
import '../data/dictionary_data_source.dart';
import '../data/recent_lookup_repository.dart';
import '../data/remote_dictionary_source.dart';
import '../domain/dictionary_errors.dart';
import '../domain/entities/recent_lookup.dart';
import '../domain/word_normalizer.dart';

/// Application service implementing the dictionary lookup pipeline.
///
/// Lookup order (local-first, offline never requires the remote source):
///
/// ```text
/// Word
///  ↓ normalize
/// Bundled/local dictionary  → found → return
///  ↓ miss
/// Remote-lookup cache       → hit   → return
///  ↓ miss
/// Remote source (only when enabled) → found → cache → return
///  ↓ miss/failure
/// Not found / typed failure
/// ```
///
/// Privacy: at most the single normalized word is ever transmitted, and
/// only when remote lookup is explicitly enabled.
class DictionaryService {
  DictionaryService({
    required DictionaryDataSource localSource,
    required DictionaryCacheRepository cache,
    required RecentLookupRepository recentLookups,
    RemoteDictionarySource? remoteSource,
    bool remoteEnabled = false,
    int maxRecentLookups = 50,
  })  : _localSource = localSource,
        _cache = cache,
        _recentLookups = recentLookups,
        _remoteSource = remoteSource,
        _remoteEnabled = remoteEnabled,
        _maxRecentLookups = maxRecentLookups;

  final DictionaryDataSource _localSource;
  final DictionaryCacheRepository _cache;
  final RecentLookupRepository _recentLookups;
  final RemoteDictionarySource? _remoteSource;
  final bool _remoteEnabled;
  final int _maxRecentLookups;

  /// Attribution of the bundled local source, for display in the UI.
  String get localAttribution => _localSource.attribution;

  /// Identifier of the bundled local source.
  String get localSourceId => _localSource.sourceId;

  /// Whether online lookup is currently enabled.
  bool get remoteEnabled => _remoteEnabled;

  /// Looks up [rawWord] and returns an explicit result for every UI state.
  ///
  /// Never throws for expected conditions (word missing, remote disabled);
  /// storage failures surface as [DictionaryLookupFailure] with typed
  /// errors.
  Future<DictionaryLookupResult> lookup(String rawWord) async {
    final word = WordNormalizer.normalizeWord(rawWord);
    if (word == null) {
      return const DictionaryLookupNotFound('');
    }

    // 1. Bundled/local dictionary.
    try {
      final local = await _localSource.lookup(word);
      if (local != null) {
        await _recordLookup(word);
        return DictionaryLookupFound(
            word: word, entry: local, fromLocalSource: true);
      }
    } on FormatException catch (error) {
      return DictionaryLookupFailure(
          word,
          DictionaryParseFailureException(
              'Local dictionary data is corrupted.', error));
    }

    // 2. Remote-lookup cache (works offline once populated).
    try {
      final cached = await _cache.load(word);
      if (cached != null) {
        await _recordLookup(word);
        return DictionaryLookupFound(
            word: word, entry: cached.entry, fromLocalSource: false);
      }
    } on FormatException {
      // A corrupted cache entry is discarded, not surfaced.
      await _cache.delete(word);
    }

    return _lookupRemoteOrNotFound(word);
  }

  Future<DictionaryLookupResult> _lookupRemoteOrNotFound(String word) async {
    final remote = _remoteSource;
    if (!_remoteEnabled || remote == null) {
      return DictionaryLookupNotFound(word, offline: true);
    }
    try {
      final entry = await remote.lookup(word);
      if (entry != null) {
        await _cache.save(
          word,
          CachedDictionaryEntry(
            entry: entry,
            sourceId: entry.source.id,
            fetchedAt: DateTime.now(),
          ),
        );
        await _recordLookup(word);
        return DictionaryLookupFound(
            word: word, entry: entry, fromLocalSource: false);
      }
      await _recordLookup(word);
      return DictionaryLookupNotFound(word);
    } on DictionaryException catch (error) {
      return DictionaryLookupFailure(word, error);
    } on FormatException catch (error) {
      return DictionaryLookupFailure(
          word,
          DictionaryParseFailureException(
              'Remote dictionary returned malformed data.', error));
    }
  }

  /// Prefix suggestions from the local headword index.
  Future<List<String>> suggestions(String rawPrefix, {int limit = 10}) {
    final prefix = WordNormalizer.normalizeWord(rawPrefix);
    if (prefix == null || prefix.isEmpty) return Future.value(const []);
    return _localSource.prefixMatches(prefix, limit: limit);
  }

  /// Recorded lookups, most recent first.
  Future<List<RecentDictionaryLookup>> getRecentLookups() =>
      _recentLookups.load();

  /// Clears the recorded lookup history.
  Future<void> clearRecentLookups() => _recentLookups.clear();

  Future<void> _recordLookup(String word) async {
    final existing = await _recentLookups.load();
    final updated = <RecentDictionaryLookup>[
      RecentDictionaryLookup(word: word, at: DateTime.now()),
      for (final lookup in existing)
        if (lookup.word != word) lookup,
    ];
    await _recentLookups.saveAll(updated.take(_maxRecentLookups).toList());
  }
}
