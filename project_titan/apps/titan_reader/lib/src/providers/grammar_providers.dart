import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bundled_dictionary_data_source.dart';
import '../data/grammar_cache_repository.dart';
import '../data/grammar_correction_repository.dart';
import '../data/grammar_engine.dart';
import '../data/remote_grammar_source.dart';
import '../data/spell_checker.dart';
import '../domain/entities/grammar_issue.dart';
import '../services/grammar_service.dart';
import 'dictionary_providers.dart';
import 'reader_providers.dart';

// ---------------------------------------------------------------------------
// Phase 4: grammar, spelling, writing assistance
// ---------------------------------------------------------------------------

/// Headword index used for offline spelling. Reuses the Phase 3 bundled
/// dictionary when available; tests override this with a small fake index.
final Provider<HeadwordIndex> grammarHeadwordIndexProvider =
    Provider<HeadwordIndex>((ref) {
  final source = ref.watch(dictionaryDataSourceProvider);
  if (source is BundledDictionaryDataSource) {
    return DictionaryHeadwordIndex(source.loadHeadwords);
  }
  return const _EmptyHeadwordIndex();
});

/// Index used when the bundled dictionary is overridden (tests): every
/// word becomes unknown, which keeps behavior deterministic instead of
/// silently guessing.
class _EmptyHeadwordIndex implements HeadwordIndex {
  const _EmptyHeadwordIndex();

  @override
  Future<Set<String>> loadWords() => Future.value(const <String>{});
}

final Provider<WordNetSpellChecker> spellCheckerProvider =
    Provider<WordNetSpellChecker>((ref) {
  return WordNetSpellChecker(index: ref.watch(grammarHeadwordIndexProvider));
});

/// The deterministic local engine; overridable in tests.
final Provider<GrammarEngine> grammarEngineProvider =
    Provider<GrammarEngine>((ref) {
  return LocalGrammarEngine(spellChecker: ref.watch(spellCheckerProvider));
});

/// Optional remote grammar engine, consulted only when
/// [grammarRemoteEnabledProvider] is true. Null disables it entirely.
final Provider<RemoteGrammarSource?> remoteGrammarSourceProvider =
    Provider<RemoteGrammarSource?>((ref) => LanguageToolApiSource());

/// Privacy switch for remote grammar checking. Defaults to LOCAL_ONLY:
/// no text ever leaves the device unless the user opts in, and only the
/// checked selection is transmitted — never the PDF or metadata (§20–21).
final StateProvider<bool> grammarRemoteEnabledProvider =
    StateProvider<bool>((ref) => false);

final Provider<GrammarCacheRepository> grammarCacheRepositoryProvider =
    Provider<GrammarCacheRepository>((ref) {
  return StorageGrammarCacheRepository(ref.watch(storageServiceProvider));
});

final Provider<GrammarCorrectionRepository>
    grammarCorrectionRepositoryProvider =
    Provider<GrammarCorrectionRepository>((ref) {
  return StorageGrammarCorrectionRepository(ref.watch(storageServiceProvider));
});

final Provider<GrammarService> grammarServiceProvider =
    Provider<GrammarService>((ref) {
  return GrammarService(
    engine: ref.watch(grammarEngineProvider),
    cache: ref.watch(grammarCacheRepositoryProvider),
    corrections: ref.watch(grammarCorrectionRepositoryProvider),
    remoteSource: ref.watch(remoteGrammarSourceProvider),
    remoteEnabled: ref.watch(grammarRemoteEnabledProvider),
  );
});

/// One grammar check keyed by the checked text. The panel watches this
/// provider; rerunning a check for the same text hits the cache.
final FutureProviderFamily<
        ({GrammarCheckResult result, GrammarRemoteOutcome remote}), String>
    grammarCheckProvider = FutureProvider.family<
        ({GrammarCheckResult result, GrammarRemoteOutcome remote}),
        String>((ref, text) {
  return ref.watch(grammarServiceProvider).checkText(text);
});

/// Stored Reader-managed corrections, newest first.
final FutureProvider<List<GrammarCorrection>> grammarCorrectionsProvider =
    FutureProvider<List<GrammarCorrection>>((ref) {
  return ref.watch(grammarServiceProvider).getCorrections();
});
