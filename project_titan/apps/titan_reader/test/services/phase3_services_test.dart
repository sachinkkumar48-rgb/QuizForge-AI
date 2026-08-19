import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/dictionary_cache_repository.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/data/recent_lookup_repository.dart';
import 'package:titan_reader/src/data/remote_dictionary_source.dart';
import 'package:titan_reader/src/data/vocabulary_repository.dart';
import 'package:titan_reader/src/domain/dictionary_errors.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/vocabulary_word.dart';
import 'package:titan_reader/src/services/dictionary_service.dart';
import 'package:titan_reader/src/services/vocabulary_service.dart';
import 'package:titan_storage/titan_storage.dart';

DictionaryEntry entry(String word, {String sourceId = 'test-dictionary'}) =>
    DictionaryEntry(
      word: word,
      normalizedWord: word,
      senses: [
        DictionarySense(
            partOfSpeech: 'noun', definitions: ['definition of $word']),
      ],
      source: DictionarySourceInfo(id: sourceId, attribution: 'test'),
    );

/// Scriptable remote source for pipeline tests.
class FakeRemoteSource implements RemoteDictionarySource {
  final Map<String, DictionaryEntry?> results = {};
  final List<String> requested = [];
  Object? error;

  @override
  String get sourceId => 'fake-remote';

  @override
  Future<DictionaryEntry?> lookup(String normalizedWord) async {
    requested.add(normalizedWord);
    final failure = error;
    if (failure != null) throw failure;
    return results[normalizedWord];
  }
}

void main() {
  group('DictionaryService lookup pipeline', () {
    late InMemoryStorageService storage;
    late InMemoryDictionaryDataSource local;
    late FakeRemoteSource remote;

    DictionaryService service({
      bool remoteEnabled = false,
      bool withRemote = true,
      int maxRecentLookups = 50,
    }) =>
        DictionaryService(
          localSource: local,
          cache: StorageDictionaryCacheRepository(storage),
          recentLookups: StorageRecentLookupRepository(storage),
          remoteSource: withRemote ? remote : null,
          remoteEnabled: remoteEnabled,
          maxRecentLookups: maxRecentLookups,
        );

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      local = InMemoryDictionaryDataSource({'ephemeral': entry('ephemeral')});
      remote = FakeRemoteSource();
    });

    test('normalizes input and serves bundled words first', () async {
      final result = await service().lookup('"Ephemeral,"');
      expect(result, isA<DictionaryLookupFound>());
      final found = result as DictionaryLookupFound;
      expect(found.word, 'ephemeral');
      expect(found.fromLocalSource, isTrue);
      expect(remote.requested, isEmpty, reason: 'remote must not be called');
    });

    test('unknown word with remote disabled is offline not-found', () async {
      final result = await service().lookup('zebra');
      expect(result, isA<DictionaryLookupNotFound>());
      expect((result as DictionaryLookupNotFound).offline, isTrue);
      expect(remote.requested, isEmpty);
    });

    test('phrase input yields not-found without hitting any source', () async {
      final result = await service().lookup('separation of powers');
      expect(result, isA<DictionaryLookupNotFound>());
      expect(remote.requested, isEmpty);
    });

    test('enabled remote fills the cache when local misses', () async {
      remote.results['zebra'] = entry('zebra', sourceId: 'fake-remote');
      final result = await service(remoteEnabled: true).lookup('zebra');
      final found = result as DictionaryLookupFound;
      expect(found.fromLocalSource, isFalse);
      expect(remote.requested, ['zebra']);

      // Second lookup works from cache alone (offline path).
      remote.results.clear();
      final cached = await service().lookup('zebra');
      expect(cached, isA<DictionaryLookupFound>());
      expect((cached as DictionaryLookupFound).fromLocalSource, isFalse);
      expect(remote.requested, ['zebra'], reason: 'cache must short-circuit');
    });

    test('remote miss is plain not-found (not offline)', () async {
      remote.results['zebra'] = null;
      final result = await service(remoteEnabled: true).lookup('zebra');
      expect(result, isA<DictionaryLookupNotFound>());
      expect((result as DictionaryLookupNotFound).offline, isFalse);
    });

    test('remote transport failure surfaces as typed failure', () async {
      remote.results['zebra'] = null;
      remote.error = const DictionarySourceException('unreachable');
      final result = await service(remoteEnabled: true).lookup('zebra');
      expect(result, isA<DictionaryLookupFailure>());
      expect((result as DictionaryLookupFailure).error,
          isA<DictionarySourceException>());
    });

    test('corrupted local data surfaces as parse failure', () async {
      final broken = _BrokenLocalSource();
      final result = await DictionaryService(
        localSource: broken,
        cache: StorageDictionaryCacheRepository(storage),
        recentLookups: StorageRecentLookupRepository(storage),
      ).lookup('ephemeral');
      expect(result, isA<DictionaryLookupFailure>());
      expect((result as DictionaryLookupFailure).error,
          isA<DictionaryParseFailureException>());
    });

    test('records lookups most-recent-first and dedups', () async {
      final svc = service(remoteEnabled: true);
      remote.results['zebra'] = entry('zebra');
      await svc.lookup('ephemeral');
      await svc.lookup('zebra');
      await svc.lookup('ephemeral');

      final recent = await svc.getRecentLookups();
      expect(recent.map((l) => l.word), ['ephemeral', 'zebra']);
      await svc.clearRecentLookups();
      expect(await svc.getRecentLookups(), isEmpty);
    });

    test('recent lookup history is capped', () async {
      local.entries.addAll({
        for (final w in ['alpha', 'bravo', 'charlie']) w: entry(w),
      });
      final svc = service(maxRecentLookups: 2);
      await svc.lookup('alpha');
      await svc.lookup('bravo');
      await svc.lookup('charlie');
      final recent = await svc.getRecentLookups();
      expect(recent.map((l) => l.word), ['charlie', 'bravo']);
    });

    test('suggestions come from the local headword index', () async {
      expect(await service().suggestions('Ephe'), ['ephemeral']);
      expect(await service().suggestions('two words'), isEmpty);
    });

    test('exposes local source attribution and id', () {
      final svc = service();
      expect(svc.localSourceId, 'test-dictionary');
      expect(svc.localAttribution, 'Test dictionary');
      expect(svc.remoteEnabled, isFalse);
    });
  });

  group('VocabularyService', () {
    late InMemoryStorageService storage;
    late StorageVocabularyRepository repository;
    var idCounter = 0;

    VocabularyService makeService() => VocabularyService(
          repository: repository,
          idGenerator: (prefix) => '${prefix}_${idCounter++}',
        );

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageVocabularyRepository(storage);
      idCounter = 0;
    });

    test('saveWord persists with source tracking and New status', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final word = await svc.saveWord(
        rawWord: '"Ephemeral,"',
        at: DateTime.utc(2026, 8, 19),
        dictionarySourceId: 'wordnet-3.0',
        sourceDocumentId: 'doc_1',
        sourceDocumentName: 'sample.pdf',
        sourcePage: 3,
        selectedText: 'Ephemeral,',
      );
      expect(word.normalizedWord, 'ephemeral');
      expect(word.status, VocabularyMasteryStatus.isNew);
      expect(word.hasNavigableSource, isTrue);

      final stored = await repository.loadAll();
      expect(stored, hasLength(1));
      expect(stored.single.sourcePage, 3);
    });

    test('saving the same word twice does not duplicate', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final first = await svc.saveWord(
          rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));
      final second = await svc.saveWord(
          rawWord: 'EPHEMERAL.', at: DateTime.utc(2026, 8, 20));
      expect(second.id, first.id);
      expect(svc.words, hasLength(1));
    });

    test('updateWord keeps personal fields separate from dictionary data',
        () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final saved = await svc.saveWord(
          rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));
      final updated = await svc.updateWord(
        wordId: saved.id,
        at: DateTime.utc(2026, 8, 20),
        personalMeaning: 'short-lived',
        personalNote: 'seen in intro',
      );
      expect(updated!.personalMeaning, 'short-lived');
      expect(updated.personalNote, 'seen in intro');
      expect(updated.word, 'ephemeral');
      expect(
          await svc.updateWord(wordId: 'missing', at: DateTime.now()), isNull);
    });

    test('changeStatus only changes on explicit request', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final saved = await svc.saveWord(
          rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));
      expect(saved.status, VocabularyMasteryStatus.isNew);
      final updated = await svc.changeStatus(
        wordId: saved.id,
        status: VocabularyMasteryStatus.mastered,
        at: DateTime.utc(2026, 8, 20),
      );
      expect(updated!.status, VocabularyMasteryStatus.mastered);
      expect(
          await svc.changeStatus(
              wordId: 'missing',
              status: VocabularyMasteryStatus.known,
              at: DateTime.now()),
          isNull);
    });

    test('removeWord deletes and persists', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final saved = await svc.saveWord(
          rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));
      final removed = await svc.removeWord(wordId: saved.id);
      expect(removed!.word, 'ephemeral');
      expect(svc.words, isEmpty);
      expect(await repository.loadAll(), isEmpty);
      expect(await svc.removeWord(wordId: saved.id), isNull);
    });

    test('words survive restart via a fresh service instance', () async {
      final first = makeService();
      await first.ensureLoaded();
      await first.saveWord(rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));

      final second = makeService();
      expect(second.isLoaded, isFalse);
      await second.ensureLoaded();
      expect(second.isLoaded, isTrue);
      expect(second.words.map((w) => w.normalizedWord), ['ephemeral']);
      // ensureLoaded must not wipe data when called again.
      await second.ensureLoaded();
      expect(second.words, hasLength(1));
    });

    test('sorted modes order correctly', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      final zulu =
          await svc.saveWord(rawWord: 'zulu', at: DateTime.utc(2026, 8, 1));
      await svc.saveWord(rawWord: 'alpha', at: DateTime.utc(2026, 8, 2));
      await svc.changeStatus(
        wordId: zulu.id,
        status: VocabularyMasteryStatus.mastered,
        at: DateTime.utc(2026, 8, 3),
      );

      expect(svc.sorted(VocabularySortMode.recent).map((w) => w.word),
          ['alpha', 'zulu']);
      expect(svc.sorted(VocabularySortMode.alphabetical).map((w) => w.word),
          ['alpha', 'zulu']);
      expect(svc.sorted(VocabularySortMode.status).map((w) => w.word),
          ['alpha', 'zulu']); // isNew (0) before mastered (3)
    });

    test('search matches word, note and document name', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      await svc.saveWord(
        rawWord: 'ephemeral',
        at: DateTime.utc(2026, 8, 19),
        sourceDocumentName: 'constitution.pdf',
      );
      expect(svc.search('ephem').map((w) => w.word), ['ephemeral']);
      expect(svc.search('constitution'), hasLength(1));
      expect(svc.search('zzz'), isEmpty);
      expect(svc.search('  '), hasLength(1));
    });

    test('notifies listeners on mutation', () async {
      final svc = makeService();
      await svc.ensureLoaded();
      var notifications = 0;
      svc.addListener(() => notifications++);
      await svc.saveWord(rawWord: 'ephemeral', at: DateTime.utc(2026, 8, 19));
      expect(notifications, greaterThan(0));
    });
  });

  group('DictionaryApiDevSource', () {
    test('parses meanings, phonetics and provenance', () async {
      final source = DictionaryApiDevSource(fetch: (uri) async {
        expect(uri.pathSegments.last, 'ephemeral');
        return const RemoteDictionaryHttpResponse(
            200,
            '[{"word":"ephemeral","phonetic":"/ɪˈfem(ə)r(ə)l/",'
            '"meanings":[{"partOfSpeech":"adjective",'
            '"definitions":[{"definition":"lasting a very short time",'
            '"example":"ephemeral art","synonyms":["transitory"],'
            '"antonyms":["eternal"]}],'
            '"synonyms":["fleeting"]}]}]');
      });
      final entry = await source.lookup('ephemeral');
      expect(entry, isNotNull);
      expect(entry!.phonetic, '/ɪˈfem(ə)r(ə)l/');
      expect(entry.senses.single.partOfSpeech, 'adjective');
      expect(entry.senses.single.synonyms,
          containsAll(['transitory', 'fleeting']));
      expect(entry.senses.single.antonyms, ['eternal']);
      expect(entry.source.id, DictionaryApiDevSource.id);
    });

    test('404 means not found, 5xx means typed source failure', () async {
      final notFound = DictionaryApiDevSource(
          fetch: (uri) async =>
              const RemoteDictionaryHttpResponse(404, 'missing'));
      expect(await notFound.lookup('nope'), isNull);

      final serverError = DictionaryApiDevSource(
          fetch: (uri) async =>
              const RemoteDictionaryHttpResponse(500, 'boom'));
      expect(() => serverError.lookup('nope'),
          throwsA(isA<DictionarySourceException>()));
    });

    test('malformed body is a typed parse failure', () async {
      final broken = DictionaryApiDevSource(
          fetch: (uri) async =>
              const RemoteDictionaryHttpResponse(200, 'not json'));
      expect(() => broken.lookup('nope'),
          throwsA(isA<DictionaryParseFailureException>()));
    });
  });
}

/// Local source that simulates corrupted bundled data.
class _BrokenLocalSource implements DictionaryDataSource {
  @override
  String get sourceId => 'broken';

  @override
  String get attribution => 'broken';

  @override
  int? get wordCount => null;

  @override
  Future<DictionaryEntry?> lookup(String normalizedWord) async {
    throw const FormatException('corrupted shard');
  }

  @override
  Future<List<String>> prefixMatches(String prefix, {int limit = 10}) async =>
      const [];
}
