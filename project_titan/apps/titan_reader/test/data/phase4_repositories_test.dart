import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/grammar_cache_repository.dart';
import 'package:titan_reader/src/data/grammar_correction_repository.dart';
import 'package:titan_reader/src/data/remote_grammar_source.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/grammar_errors.dart';
import 'package:titan_storage/titan_storage.dart';

GrammarCheckResult result({
  String text = 'He go to school.',
  String engineVersion = '1.0.0',
  List<GrammarIssue> issues = const [],
}) {
  return GrammarCheckResult(
    text: text,
    language: 'en',
    issues: issues,
    engineId: 'local.titan.grammar',
    engineVersion: engineVersion,
    checkedAt: DateTime.utc(2026, 8, 19, 12),
  );
}

void main() {
  group('grammar cache keys', () {
    test('follow the grammar:<engine>:<version>:<language>:<hash> shape', () {
      final key = GrammarCacheRepository.keyFor(
        engineId: 'local.titan.grammar',
        engineVersion: '1.0.0',
        language: 'en',
        text: 'some text',
      );
      final parts = key.split(':');
      expect(parts[0], 'grammar');
      expect(parts[1], 'local.titan.grammar');
      expect(parts[2], '1.0.0');
      expect(parts[3], 'en');
      expect(parts[4], hasLength(16));
    });

    test('are deterministic and text sensitive', () {
      String keyFor(String text) => GrammarCacheRepository.keyFor(
            engineId: 'e',
            engineVersion: '1',
            language: 'en',
            text: text,
          );
      expect(keyFor('abc'), keyFor('abc'));
      expect(keyFor('abc'), isNot(keyFor('abd')));
    });

    test('change when the engine version changes', () {
      final old = GrammarCacheRepository.keyFor(
        engineId: 'e',
        engineVersion: '1.0.0',
        language: 'en',
        text: 'abc',
      );
      final updated = GrammarCacheRepository.keyFor(
        engineId: 'e',
        engineVersion: '1.1.0',
        language: 'en',
        text: 'abc',
      );
      expect(old, isNot(updated));
    });

    test('fnv1a64Hex matches the known empty-string offset basis', () {
      expect(fnv1a64Hex(''), 'cbf29ce484222325');
    });
  });

  group('StorageGrammarCacheRepository', () {
    late InMemoryStorageService storage;
    late StorageGrammarCacheRepository repository;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageGrammarCacheRepository(storage);
    });

    test('stores and restores a full check result', () async {
      const key = 'grammar:e:1:en:hash';
      final original = result(
        issues: const [
          GrammarIssue(
            ruleId: 'rule.test',
            type: GrammarIssueType.grammar,
            severity: GrammarIssueSeverity.error,
            message: 'm',
            explanation: 'e',
            startOffset: 3,
            endOffset: 5,
            originalText: 'go',
            suggestions: [GrammarSuggestion(replacement: 'goes')],
          ),
        ],
      );
      await repository.save(key, original);
      final restored = await repository.load(key);
      expect(restored, isNotNull);
      expect(restored!.text, original.text);
      expect(restored.issues, hasLength(1));
      expect(restored.issues.single.suggestions.single.replacement, 'goes');
    });

    test('returns null for unknown keys', () async {
      expect(await repository.load('grammar:e:1:en:missing'), isNull);
    });

    test('delete removes a single entry only', () async {
      await repository.save('key-a', result(text: 'a'));
      await repository.save('key-b', result(text: 'b'));
      await repository.delete('key-a');
      expect(await repository.load('key-a'), isNull);
      expect(await repository.load('key-b'), isNotNull);
    });

    test('clearAll empties the cache', () async {
      await repository.save('key-a', result(text: 'a'));
      await repository.save('key-b', result(text: 'b'));
      await repository.clearAll();
      expect(await repository.load('key-a'), isNull);
      expect(await repository.load('key-b'), isNull);
    });

    test('rejects malformed stored payloads', () async {
      await storage.write<String>(
        const StorageKey('bad',
            namespace: StorageGrammarCacheRepository.namespace),
        '"not an object"',
      );
      expect(() => repository.load('bad'), throwsFormatException);
    });
  });

  group('StorageGrammarCorrectionRepository', () {
    late InMemoryStorageService storage;
    late StorageGrammarCorrectionRepository repository;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      repository = StorageGrammarCorrectionRepository(storage);
    });

    GrammarCorrection correction(String id, DateTime at) => GrammarCorrection(
          id: id,
          documentId: 'doc-1',
          pageNumber: 2,
          originalText: 'the the end',
          correctedText: 'the end',
          appliedRuleIds: const ['rule.repeated-word'],
          createdAt: at,
        );

    test('loads an empty list before any save', () async {
      expect(await repository.loadAll(), isEmpty);
    });

    test('saveAll/loadAll round-trip preserves order and fields', () async {
      final items = [
        correction('a', DateTime.utc(2026, 8, 19, 9)),
        correction('b', DateTime.utc(2026, 8, 19, 10)),
      ];
      await repository.saveAll(items);
      final restored = await repository.loadAll();
      expect(restored.map((c) => c.id).toList(), ['a', 'b']);
      expect(restored.first.appliedRuleIds, ['rule.repeated-word']);
      expect(restored.first.pageNumber, 2);
    });

    test('delete removes only the matching correction', () async {
      await repository.saveAll([
        correction('a', DateTime.utc(2026, 8, 19, 9)),
        correction('b', DateTime.utc(2026, 8, 19, 10)),
      ]);
      await repository.delete('a');
      final remaining = await repository.loadAll();
      expect(remaining.map((c) => c.id).toList(), ['b']);
    });

    test('delete is a no-op for unknown ids', () async {
      await repository.saveAll([correction('a', DateTime.utc(2026, 8, 19, 9))]);
      await repository.delete('zzz');
      expect(await repository.loadAll(), hasLength(1));
    });

    test('rejects malformed payloads', () async {
      await storage.write<String>(
          StorageGrammarCorrectionRepository.allKey, '"not a list"');
      expect(() => repository.loadAll(), throwsFormatException);
    });
  });

  group('LanguageToolApiSource', () {
    const validPayload = '''
    {
      "matches": [
        {
          "offset": 3,
          "length": 2,
          "message": "Use the third-person singular.",
          "replacements": [{"value": "goes"}, {"value": "went"}],
          "rule": {
            "id": "EN_VERB_3P",
            "issueType": "grammar",
            "description": "Subject-verb agreement"
          }
        },
        {
          "offset": 0,
          "length": 999,
          "message": "Clamped match.",
          "rule": {"id": "CLAMPED", "issueType": "misspelling"}
        }
      ]
    }
    ''';

    test('parses matches into domain issues and clamps offsets', () async {
      Uri? requestedUri;
      String? requestedBody;
      final source = LanguageToolApiSource(
        fetch: (uri, body) async {
          requestedUri = uri;
          requestedBody = body;
          return const RemoteGrammarHttpResponse(200, validPayload);
        },
      );
      const text = 'He go to school.';
      final issues = await source.check(text);

      // Privacy: the request carries only the text and the language (§20).
      expect(requestedUri.toString(), 'https://api.languagetool.org/v2/check');
      expect(requestedBody, contains('text='));
      expect(requestedBody, contains('language=en'));
      expect(requestedBody!.contains('document'), isFalse);

      expect(issues, hasLength(2));
      // Sorted by offset; the clamped match sorts first (offset 0).
      final clamped = issues.first;
      expect(clamped.startOffset, 0);
      expect(clamped.endOffset, text.length);
      expect(clamped.type, GrammarIssueType.spelling);
      expect(clamped.source, GrammarIssueSource.remote);

      final verb = issues[1];
      expect(verb.ruleId, 'languagetool:EN_VERB_3P');
      expect(verb.type, GrammarIssueType.grammar);
      expect(verb.severity, GrammarIssueSeverity.warning);
      expect(verb.explanation, 'Subject-verb agreement');
      expect(
        verb.suggestions.map((s) => s.replacement).toList(),
        ['goes', 'went'],
      );
      expect(verb.originalText, text.substring(3, 5));
    });

    test('returns no issues for empty input without calling the network',
        () async {
      var called = false;
      final source = LanguageToolApiSource(fetch: (uri, body) async {
        called = true;
        return const RemoteGrammarHttpResponse(200, '{}');
      });
      expect(await source.check('   '), isEmpty);
      expect(called, isFalse);
    });

    test('maps non-2xx statuses to GrammarRemoteException', () async {
      final source = LanguageToolApiSource(
        fetch: (uri, body) async =>
            const RemoteGrammarHttpResponse(503, 'unavailable'),
      );
      await expectLater(
        source.check('text'),
        throwsA(isA<GrammarRemoteException>()),
      );
    });

    test('maps malformed JSON to GrammarRemoteParseException', () async {
      final source = LanguageToolApiSource(
        fetch: (uri, body) async =>
            const RemoteGrammarHttpResponse(200, 'not json'),
      );
      await expectLater(
        source.check('text'),
        throwsA(isA<GrammarRemoteParseException>()),
      );
    });

    test('maps missing matches arrays to GrammarRemoteParseException',
        () async {
      final source = LanguageToolApiSource(
        fetch: (uri, body) async =>
            const RemoteGrammarHttpResponse(200, '{"software": {}}'),
      );
      await expectLater(
        source.check('text'),
        throwsA(isA<GrammarRemoteParseException>()),
      );
    });

    test('skips malformed matches instead of failing the whole check',
        () async {
      final source = LanguageToolApiSource(
        fetch: (uri, body) async => const RemoteGrammarHttpResponse(
          200,
          '{"matches": [{"offset": "x"}, '
          '{"offset": 0, "length": 3, "message": "ok"}]}',
        ),
      );
      final issues = await source.check('some text');
      expect(issues, hasLength(1));
      expect(issues.single.message, 'ok');
    });
  });
}
