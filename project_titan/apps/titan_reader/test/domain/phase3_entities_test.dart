import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/dictionary_errors.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/recent_lookup.dart';
import 'package:titan_reader/src/domain/entities/vocabulary_word.dart';
import 'package:titan_reader/src/domain/word_normalizer.dart';

final DictionaryEntry sampleEntry = DictionaryEntry(
  word: 'ephemeral',
  normalizedWord: 'ephemeral',
  phonetic: null,
  senses: const [
    DictionarySense(
      partOfSpeech: 'adjective',
      definitions: ['lasting a very short time'],
      examples: ['the ephemeral joys of childhood'],
      synonyms: ['transitory', 'short-lived'],
      antonyms: ['eternal'],
    ),
  ],
  source: const DictionarySourceInfo(id: 'wordnet-3.0', attribution: 'WordNet'),
);

void main() {
  group('WordNormalizer.normalizeWord', () {
    test('strips surrounding punctuation and lowercases', () {
      expect(WordNormalizer.normalizeWord('"Ephemeral,"'), 'ephemeral');
      expect(WordNormalizer.normalizeWord('(word!)'), 'word');
      expect(WordNormalizer.normalizeWord('  HELLO.  '), 'hello');
    });

    test('preserves inner apostrophes and hyphens', () {
      expect(WordNormalizer.normalizeWord("don't"), "don't");
      expect(WordNormalizer.normalizeWord('short-lived.'), 'short-lived');
    });

    test('returns null for empty and phrase input', () {
      expect(WordNormalizer.normalizeWord(''), isNull);
      expect(WordNormalizer.normalizeWord('...'), isNull);
      expect(WordNormalizer.normalizeWord('separation of powers'), isNull);
      expect(WordNormalizer.normalizeWord('two\nlines'), isNull);
    });
  });

  group('WordNormalizer single-word detection', () {
    test('accepts single words with edge noise', () {
      expect(WordNormalizer.isSingleWord('Ephemeral,'), isTrue);
      expect(WordNormalizer.singleWordFrom('"Ephemeral,"'), 'ephemeral');
    });

    test('rejects multi-word selections', () {
      expect(WordNormalizer.isSingleWord('separation of powers'), isFalse);
      expect(WordNormalizer.singleWordFrom('two words'), isNull);
      expect(WordNormalizer.singleWordFrom('   '), isNull);
    });
  });

  group('DictionaryEntry serialization', () {
    test('round-trips through JSON', () {
      final restored = DictionaryEntry.fromJson(sampleEntry.toJson());
      expect(restored, sampleEntry);
      expect(restored.partsOfSpeech, ['adjective']);
    });

    test('rejects malformed JSON with FormatException', () {
      expect(() => DictionaryEntry.fromJson(const {'word': 'x'}),
          throwsFormatException);
    });
  });

  group('RecentDictionaryLookup serialization', () {
    test('round-trips through JSON', () {
      final lookup = RecentDictionaryLookup(
          word: 'ephemeral', at: DateTime.utc(2026, 8, 19, 10));
      expect(RecentDictionaryLookup.fromJson(lookup.toJson()), lookup);
    });

    test('rejects malformed JSON', () {
      expect(() => RecentDictionaryLookup.fromJson(const {'word': 'x'}),
          throwsFormatException);
    });
  });

  group('VocabularyWord', () {
    final base = VocabularyWord(
      id: 'vocab_1',
      word: 'ephemeral',
      normalizedWord: 'ephemeral',
      sourceDocumentId: 'doc_1',
      sourceDocumentName: 'sample.pdf',
      sourcePage: 3,
      createdAt: DateTime.utc(2026, 8, 19),
      updatedAt: DateTime.utc(2026, 8, 19),
    );

    test('defaults to New mastery status', () {
      expect(base.status, VocabularyMasteryStatus.isNew);
      expect(base.status.label, 'New');
    });

    test('hasNavigableSource requires document id and page', () {
      expect(base.hasNavigableSource, isTrue);
      expect(
        VocabularyWord(
          id: 'v2',
          word: 'x',
          normalizedWord: 'x',
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
        ).hasNavigableSource,
        isFalse,
      );
    });

    test('matches searches word, meaning, note and document name', () {
      final word = base.copyWith(
        personalMeaning: 'short-lived',
        personalNote: 'from intro chapter',
      );
      expect(word.matches('EPHEM'), isTrue);
      expect(word.matches('short'), isTrue);
      expect(word.matches('intro'), isTrue);
      expect(word.matches('sample.pdf'), isTrue);
      expect(word.matches('zzz'), isFalse);
      expect(word.matches(''), isFalse);
    });

    test('personal fields never touch dictionary data via copyWith', () {
      final updated = base.copyWith(
        personalMeaning: 'my meaning',
        status: VocabularyMasteryStatus.learning,
        updatedAt: DateTime.utc(2026, 8, 20),
      );
      expect(updated.personalMeaning, 'my meaning');
      expect(updated.status, VocabularyMasteryStatus.learning);
      expect(updated.word, base.word);
      expect(updated.normalizedWord, base.normalizedWord);
      expect(updated.createdAt, base.createdAt);
    });

    test('round-trips through JSON including status', () {
      final restored = VocabularyWord.fromJson(base.toJson());
      expect(restored, base);
    });

    test('unknown persisted status falls back to New', () {
      final json = base.toJson()..['status'] = 'future-status';
      expect(
          VocabularyWord.fromJson(json).status, VocabularyMasteryStatus.isNew);
    });

    test('rejects malformed JSON', () {
      expect(() => VocabularyWord.fromJson(const {'id': 'x'}),
          throwsFormatException);
    });
  });

  group('typed dictionary errors', () {
    test('every failure type is a DictionaryException', () {
      const errors = <DictionaryException>[
        DictionaryNotFoundException('x'),
        DictionaryOfflineUnavailableException('x'),
        DictionaryParseFailureException('bad data'),
        DictionarySourceException('unreachable'),
        DictionaryStorageFailureException('write failed'),
      ];
      expect(errors, hasLength(5));
      expect(errors.last.toString(), contains('write failed'));
    });

    test('lookup results model all UI states', () {
      final results = <DictionaryLookupResult>[
        DictionaryLookupFound(
            word: 'a', entry: sampleEntry, fromLocalSource: true),
        const DictionaryLookupNotFound('b', offline: true),
        const DictionaryLookupFailure('c', DictionarySourceException('boom')),
      ];
      expect(results[0], isA<DictionaryLookupFound>());
      expect((results[1] as DictionaryLookupNotFound).offline, isTrue);
      expect((results[2] as DictionaryLookupFailure).error,
          isA<DictionarySourceException>());
    });
  });
}
