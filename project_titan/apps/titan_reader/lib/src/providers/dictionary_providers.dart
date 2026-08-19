import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bundled_dictionary_data_source.dart';
import '../data/dictionary_cache_repository.dart';
import '../data/dictionary_data_source.dart';
import '../data/recent_lookup_repository.dart';
import '../data/remote_dictionary_source.dart';
import '../data/vocabulary_repository.dart';
import '../domain/dictionary_errors.dart';
import '../domain/entities/recent_lookup.dart';
import '../domain/entities/vocabulary_word.dart';
import '../services/dictionary_service.dart';
import '../services/vocabulary_service.dart';
import 'reader_providers.dart';

// ---------------------------------------------------------------------------
// Phase 3: dictionary, vocabulary
// ---------------------------------------------------------------------------

/// Bundled offline dictionary (WordNet 3.0). Overridable in tests with an
/// in-memory source so widget tests never touch real assets.
final Provider<DictionaryDataSource> dictionaryDataSourceProvider =
    Provider<DictionaryDataSource>((ref) => BundledDictionaryDataSource());

/// Optional remote dictionary source, consulted only when
/// [remoteLookupEnabledProvider] is true. Null disables remote lookup
/// entirely.
final Provider<RemoteDictionarySource?> remoteDictionarySourceProvider =
    Provider<RemoteDictionarySource?>((ref) => DictionaryApiDevSource());

/// Privacy switch for online dictionary lookup. Defaults to LOCAL_ONLY:
/// no word ever leaves the device unless the user opts in.
final StateProvider<bool> remoteLookupEnabledProvider =
    StateProvider<bool>((ref) => false);

final Provider<DictionaryCacheRepository> dictionaryCacheRepositoryProvider =
    Provider<DictionaryCacheRepository>((ref) {
  return StorageDictionaryCacheRepository(ref.watch(storageServiceProvider));
});

final Provider<RecentLookupRepository> recentLookupRepositoryProvider =
    Provider<RecentLookupRepository>((ref) {
  return StorageRecentLookupRepository(ref.watch(storageServiceProvider));
});

final Provider<DictionaryService> dictionaryServiceProvider =
    Provider<DictionaryService>((ref) {
  return DictionaryService(
    localSource: ref.watch(dictionaryDataSourceProvider),
    cache: ref.watch(dictionaryCacheRepositoryProvider),
    recentLookups: ref.watch(recentLookupRepositoryProvider),
    remoteSource: ref.watch(remoteDictionarySourceProvider),
    remoteEnabled: ref.watch(remoteLookupEnabledProvider),
  );
});

/// Result of looking up one word; keyed by the raw (un-normalized) query.
final FutureProviderFamily<DictionaryLookupResult, String>
    dictionaryLookupProvider =
    FutureProvider.family<DictionaryLookupResult, String>((ref, rawWord) {
  return ref.watch(dictionaryServiceProvider).lookup(rawWord);
});

/// Recorded dictionary lookups, most recent first. Refreshed by the UI
/// after lookups and after clearing history.
final FutureProvider<List<RecentDictionaryLookup>> recentLookupsProvider =
    FutureProvider<List<RecentDictionaryLookup>>((ref) {
  return ref.watch(dictionaryServiceProvider).getRecentLookups();
});

final Provider<VocabularyRepository> vocabularyRepositoryProvider =
    Provider<VocabularyRepository>((ref) {
  return StorageVocabularyRepository(ref.watch(storageServiceProvider));
});

final Provider<VocabularyService> vocabularyServiceProvider =
    Provider<VocabularyService>((ref) {
  return VocabularyService(repository: ref.watch(vocabularyRepositoryProvider));
});

/// All saved vocabulary words; rebuilds whenever the service mutates.
/// Consumers call [VocabularyService.preload] before first use.
final FutureProvider<List<VocabularyWord>> vocabularyWordsProvider =
    FutureProvider<List<VocabularyWord>>((ref) {
  final service = ref.watch(vocabularyServiceProvider);
  void listener() => ref.invalidateSelf();
  service.addListener(listener);
  ref.onDispose(() => service.removeListener(listener));
  return Future.value(service.words);
});
