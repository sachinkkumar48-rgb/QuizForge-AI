import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/bundled_dictionary_data_source.dart';
import 'package:titan_reader/src/data/dictionary_cache_repository.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/data/recent_lookup_repository.dart';
import 'package:titan_reader/src/data/vocabulary_repository.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/recent_lookup.dart';
import 'package:titan_reader/src/domain/entities/vocabulary_word.dart';
import 'package:titan_storage/titan_storage.dart';

/// Builds an in-memory asset bundle matching the build script's layout:
/// manifest.json, gzipped headword index and gzipped shards.
class FakeDictionaryAssets {
  final Map<String, List<int>> _assets = {};

  FakeDictionaryAssets({
    required Map<String, Map<String, Object?>> shards,
    required List<String> headwords,
    int? wordCount,
  }) {
    _assets['assets/dictionary/manifest.json'] = utf8.encode(jsonEncode({
      'source': 'wordnet-3.0',
      'wordCount': wordCount ?? headwords.length,
    }));
    final sorted = List.of(headwords)..sort();
    _assets['assets/dictionary/headwords.json.gz'] =
        gzip.encode(utf8.encode(jsonEncode(sorted)));
    shards.forEach((key, entries) {
      _assets['assets/dictionary/shards/$key.json.gz'] =
          gzip.encode(utf8.encode(jsonEncode(entries)));
    });
  }

  Future<Uint8List> load(String path) async {
    final data = _assets[path];
    if (data == null) {
      throw StateError('Missing asset: $path');
    }
    return Uint8List.fromList(data);
  }

  /// Corrupts one asset so parse-failure paths can be tested.
  void corrupt(String path) {
    _assets[path] = utf8.encode('not json');
  }
}

Map<String, Object?> entryJson(String word,
        {String pos = 'adjective', List<String>? synonyms}) =>
    {
      'w': word,
      's': [
        {
          'p': pos,
          'd': ['a test definition of $word'],
          'e': ['an example using $word'],
          'y': synonyms ?? const <String>[],
          'a': const <String>[],
        },
      ],
    };

void main() {
  group('BundledDictionaryDataSource', () {
    late FakeDictionaryAssets assets;
    late BundledDictionaryDataSource source;

    setUp(() {
      assets = FakeDictionaryAssets(
        shards: {
          'ep': {
            'ephemeral':
                entryJson('ephemeral', synonyms: ['transitory', 'short-lived']),
            'epic': entryJson('epic', pos: 'noun'),
          },
          '_a': {
            "aardvark's": entryJson("aardvark's"),
          },
          // The shipped dataset contains every shard key, including empty
          // ones; mirrors that contract here.
          'ze': <String, Object?>{},
        },
        headwords: ['aardvark', 'ephemeral', 'epic'],
      );
      source = BundledDictionaryDataSource(assetLoader: assets.load);
    });

    test('shardKeyFor matches the build script', () {
      expect(BundledDictionaryDataSource.shardKeyFor('ephemeral'), 'ep');
      expect(BundledDictionaryDataSource.shardKeyFor('a'), '_a');
      expect(BundledDictionaryDataSource.shardKeyFor('9x'), '_9');
    });

    test('lookup decodes senses, examples and synonyms', () async {
      final entry = await source.lookup('ephemeral');
      expect(entry, isNotNull);
      expect(entry!.word, 'ephemeral');
      expect(entry.senses.single.partOfSpeech, 'adjective');
      expect(
          entry.senses.single.definitions, ['a test definition of ephemeral']);
      expect(entry.senses.single.examples, ['an example using ephemeral']);
      expect(entry.senses.single.synonyms, ['transitory', 'short-lived']);
      expect(entry.source.id, 'wordnet-3.0');
      expect(entry.source.attribution, contains('Princeton'));
    });

    test('lookup returns null for missing words', () async {
      expect(await source.lookup('zebra'), isNull);
      expect(await source.lookup(''), isNull);
    });

    test('wordCount comes from the manifest after index load', () async {
      expect(source.wordCount, isNull);
      await source.prefixMatches('ephe');
      expect(source.wordCount, 3);
    });

    test('prefixMatches uses the sorted headword index', () async {
      expect(await source.prefixMatches('ep'), ['ephemeral', 'epic']);
      expect(await source.prefixMatches('ep', limit: 1), ['ephemeral']);
      expect(await source.prefixMatches(''), isEmpty);
      expect(await source.prefixMatches('zzz'), isEmpty);
    });

    test('malformed shard surfaces as FormatException', () async {
      assets.corrupt('assets/dictionary/shards/ep.json.gz');
      expect(() => source.lookup('ephemeral'), throwsFormatException);
    });
  });

  group('InMemoryDictionaryDataSource', () {
    test('serves entries by normalized word', () async {
      final entry = DictionaryEntry(
        word: 'ephemeral',
        normalizedWord: 'ephemeral',
        senses: const [
          DictionarySense(partOfSpeech: 'adjective', definitions: ['short']),
        ],
        source: const DictionarySourceInfo(id: 't', attribution: 't'),
      );
      final source = InMemoryDictionaryDataSource({'ephemeral': entry});
      expect(await source.lookup('ephemeral'), entry);
      expect(await source.lookup('missing'), isNull);
      expect(await source.prefixMatches('eph'), ['ephemeral']);
      expect(source.wordCount, 1);
    });
  });

  group('StorageDictionaryCacheRepository', () {
    late InMemoryStorageService storage;
    late StorageDictionaryCacheRepository repository;

    final cached = CachedDictionaryEntry(
      entry: DictionaryEntry(
        word: 'ephemeral',
        normalizedWord: 'ephemeral',
        senses: const [
          DictionarySense(partOfSpeech: 'adjective', definitions: ['short']),
        ],
        source: const DictionarySourceInfo(id: 'r', attribution: 'remote'),
      ),
      sourceId: 'remote:dictionaryapi.dev',
      fetchedAt: DateTime.utc(2026, 8, 19),
    );

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageDictionaryCacheRepository(storage);
    });

    test('uses the reader dictionary cache namespace', () async {
      await repository.save('ephemeral', cached);
      final raw = await storage.read<String>(const StorageKey(
          'dictionary:ephemeral',
          namespace: 'titan.reader.dictionary.cache'));
      expect(raw, isNotNull);
    });

    test('save/load round-trips entries with provenance', () async {
      await repository.save('ephemeral', cached);
      final restored = await repository.load('ephemeral');
      expect(restored, isNotNull);
      expect(restored!.entry, cached.entry);
      expect(restored.sourceId, 'remote:dictionaryapi.dev');
      expect(restored.fetchedAt, DateTime.utc(2026, 8, 19));
    });

    test('load returns null when absent', () async {
      expect(await repository.load('nope'), isNull);
    });

    test('delete removes entry and index entry', () async {
      await repository.save('ephemeral', cached);
      await repository.delete('ephemeral');
      expect(await repository.load('ephemeral'), isNull);
      await repository.clearAll(); // must not resurrect anything
      expect(await repository.load('ephemeral'), isNull);
    });

    test('clearAll removes every cached entry', () async {
      await repository.save('ephemeral', cached);
      await repository.save('diurnal', cached);
      await repository.clearAll();
      expect(await repository.load('ephemeral'), isNull);
      expect(await repository.load('diurnal'), isNull);
    });

    test('malformed stored JSON throws FormatException', () async {
      await storage.write<String>(
          const StorageKey('dictionary:broken',
              namespace: 'titan.reader.dictionary.cache'),
          '[1,2,3]');
      expect(() => repository.load('broken'), throwsFormatException);
    });
  });

  group('StorageRecentLookupRepository', () {
    late InMemoryStorageService storage;
    late StorageRecentLookupRepository repository;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageRecentLookupRepository(storage);
    });

    test('uses the reader dictionary recent namespace', () {
      expect(StorageRecentLookupRepository.namespace,
          'titan.reader.dictionary.recent');
    });

    test('round-trips lookup history and clears it', () async {
      expect(await repository.load(), isEmpty);
      final lookups = [
        RecentDictionaryLookup(
            word: 'ephemeral', at: DateTime.utc(2026, 8, 19, 12)),
        RecentDictionaryLookup(
            word: 'diurnal', at: DateTime.utc(2026, 8, 19, 11)),
      ];
      await repository.saveAll(lookups);
      expect(await repository.load(), lookups);
      await repository.clear();
      expect(await repository.load(), isEmpty);
    });

    test('malformed stored JSON throws FormatException', () async {
      await storage.write<String>(
          const StorageKey('lookups',
              namespace: 'titan.reader.dictionary.recent'),
          'not json');
      expect(() => repository.load(), throwsFormatException);
    });
  });

  group('StorageVocabularyRepository', () {
    late InMemoryStorageService storage;
    late StorageVocabularyRepository repository;

    final word = VocabularyWord(
      id: 'vocab_1',
      word: 'ephemeral',
      normalizedWord: 'ephemeral',
      sourceDocumentId: 'doc_1',
      sourceDocumentName: 'sample.pdf',
      sourcePage: 3,
      createdAt: DateTime.utc(2026, 8, 19),
      updatedAt: DateTime.utc(2026, 8, 19),
    );

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageVocabularyRepository(storage);
    });

    test('uses the reader vocabulary namespace', () {
      expect(StorageVocabularyRepository.namespace, 'titan.reader.vocabulary');
    });

    test('round-trips vocabulary words and clears them', () async {
      expect(await repository.loadAll(), isEmpty);
      await repository.saveAll([word]);
      expect(await repository.loadAll(), [word]);
      await repository.clear();
      expect(await repository.loadAll(), isEmpty);
    });

    test('malformed stored JSON throws FormatException', () async {
      await storage.write<String>(
          const StorageKey('all', namespace: 'titan.reader.vocabulary'), '{}');
      expect(() => repository.loadAll(), throwsFormatException);
    });
  });
}
