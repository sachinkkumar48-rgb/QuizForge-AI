import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/grammar_cache_repository.dart';
import 'package:titan_reader/src/data/grammar_correction_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/remote_grammar_source.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/grammar_errors.dart';
import 'package:titan_reader/src/providers/grammar_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/services/grammar_service.dart';
import 'package:titan_storage/titan_storage.dart';

class FakeGrammarEngine implements GrammarEngine {
  FakeGrammarEngine(this.issuesFor, {this.version = '1.0.0'});

  final List<GrammarIssue> Function(String text) issuesFor;
  String version;
  int checkCount = 0;
  String? lastLanguage;

  @override
  String get engineId => 'fake.engine';

  @override
  String get engineVersion => version;

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    checkCount++;
    lastLanguage = language;
    return issuesFor(text);
  }
}

class FailingGrammarEngine implements GrammarEngine {
  @override
  String get engineId => 'fake.failing';

  @override
  String get engineVersion => '1.0.0';

  @override
  Future<List<GrammarIssue>> check(String text, {String language = 'en'}) {
    throw const GrammarEngineException('spelling index is corrupt');
  }
}

class FakeRemoteSource implements RemoteGrammarSource {
  FakeRemoteSource({this.issues = const [], this.error});

  final List<GrammarIssue> issues;
  final GrammarCheckError? error;
  int callCount = 0;
  final List<String> checkedTexts = [];

  @override
  String get sourceId => 'remote:fake';

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    callCount++;
    checkedTexts.add(text);
    final failure = error;
    if (failure != null) throw failure;
    return issues;
  }
}

GrammarIssue issue(int start, int end, {String ruleId = 'remote.rule'}) =>
    GrammarIssue(
      ruleId: ruleId,
      type: GrammarIssueType.grammar,
      severity: GrammarIssueSeverity.warning,
      message: 'remote message',
      startOffset: start,
      endOffset: end,
      originalText: 'x',
      source: GrammarIssueSource.remote,
    );

void main() {
  late InMemoryStorageService storage;
  late GrammarCacheRepository cache;
  late GrammarCorrectionRepository corrections;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    cache = StorageGrammarCacheRepository(storage);
    corrections = StorageGrammarCorrectionRepository(storage);
  });

  GrammarService service({
    GrammarEngine? engine,
    RemoteGrammarSource? remoteSource,
    bool remoteEnabled = false,
  }) {
    return GrammarService(
      engine: engine ?? FakeGrammarEngine((_) => const []),
      cache: cache,
      corrections: corrections,
      remoteSource: remoteSource,
      remoteEnabled: remoteEnabled,
      idGenerator: (prefix) => 'id-$prefix',
    );
  }

  group('checkText', () {
    test('runs the local engine and reports no remote activity by default',
        () async {
      final engine =
          FakeGrammarEngine((_) => [issue(0, 2, ruleId: 'local.rule')]);
      final remote = FakeRemoteSource();
      final subject =
          service(engine: engine, remoteSource: remote, remoteEnabled: false);

      final outcome = await subject.checkText('some text');

      expect(engine.checkCount, 1);
      expect(engine.lastLanguage, 'en');
      expect(remote.callCount, 0,
          reason: 'LOCAL_ONLY must never consult the remote engine');
      expect(outcome.result.issues, hasLength(1));
      expect(outcome.result.remoteSourceId, isNull);
      expect(outcome.remote.issues, isEmpty);
      expect(outcome.remote.failureReason, isNull);
    });

    test('serves repeat checks from the cache', () async {
      final engine =
          FakeGrammarEngine((_) => [issue(0, 2, ruleId: 'local.rule')]);
      final subject = service(engine: engine);

      final first = await subject.checkText('same text');
      final second = await subject.checkText('same text');

      expect(engine.checkCount, 1);
      expect(second.result.checkedAt, first.result.checkedAt);
      expect(second.result.issues, hasLength(1));

      // A different text is checked again.
      await subject.checkText('other text');
      expect(engine.checkCount, 2);
    });

    test('engine updates invalidate cached results via the key version',
        () async {
      final engine =
          FakeGrammarEngine((_) => [issue(0, 2, ruleId: 'local.rule')]);
      final subject = service(engine: engine);

      await subject.checkText('text');
      expect(engine.checkCount, 1);

      // Simulate an engine update: the version changes, so the old cache
      // entry must not be served (§22).
      engine.version = '2.0.0';
      final outcome = await subject.checkText('text');
      expect(engine.checkCount, 2);
      expect(outcome.result.engineVersion, '2.0.0');
    });

    test('merges remote issues when the user opted in', () async {
      final engine = FakeGrammarEngine((_) => [
            issue(0, 3, ruleId: 'local.rule'),
          ]);
      final remote = FakeRemoteSource(issues: [
        issue(0, 3, ruleId: 'duplicate-span'),
        issue(5, 9),
      ]);
      final subject =
          service(engine: engine, remoteSource: remote, remoteEnabled: true);

      final outcome = await subject.checkText('text for remote');

      expect(remote.callCount, 1);
      // The identical-span remote issue is dropped; local wins.
      expect(outcome.result.issues, hasLength(2));
      expect(
        outcome.result.issues.map((i) => i.ruleId).toList(),
        ['local.rule', 'remote.rule'],
      );
      expect(outcome.result.remoteSourceId, 'remote:fake');
      expect(outcome.remote.issues, hasLength(2));
      expect(outcome.remote.failureReason, isNull);

      // Only the checked text is transmitted to the remote engine (§20).
      expect(remote.checkedTexts, ['text for remote']);
    });

    test('keeps local results when the remote engine fails', () async {
      final engine =
          FakeGrammarEngine((_) => [issue(0, 2, ruleId: 'local.rule')]);
      final remote = FakeRemoteSource(
        error: const GrammarRemoteException('unreachable'),
      );
      final subject =
          service(engine: engine, remoteSource: remote, remoteEnabled: true);

      final outcome = await subject.checkText('text');

      expect(outcome.result.issues, hasLength(1));
      expect(outcome.result.remoteSourceId, isNull);
      expect(outcome.remote.failureReason, 'unreachable');
    });

    test('keeps local results when the remote payload is malformed', () async {
      final engine =
          FakeGrammarEngine((_) => [issue(0, 2, ruleId: 'local.rule')]);
      final remote = FakeRemoteSource(
        error: const GrammarRemoteParseException('bad payload'),
      );
      final subject =
          service(engine: engine, remoteSource: remote, remoteEnabled: true);

      final outcome = await subject.checkText('text');

      expect(outcome.result.issues, hasLength(1));
      expect(outcome.remote.failureReason, 'bad payload');
    });

    test('surfaces local engine failures as GrammarCheckError', () async {
      final subject = service(engine: FailingGrammarEngine());
      await expectLater(
        subject.checkText('text'),
        throwsA(isA<GrammarEngineException>()),
      );
    });

    test('remoteEnabled requires both the flag and a source', () {
      expect(
        service(remoteEnabled: true, remoteSource: null).remoteEnabled,
        isFalse,
      );
      expect(
        service(remoteEnabled: false, remoteSource: FakeRemoteSource())
            .remoteEnabled,
        isFalse,
      );
      expect(
        service(remoteEnabled: true, remoteSource: FakeRemoteSource())
            .remoteEnabled,
        isTrue,
      );
    });
  });

  group('Reader-managed corrections', () {
    test(
        'applyCorrections stores the correction and never pretends to '
        'edit the PDF', () async {
      final subject = service();
      final at = DateTime.utc(2026, 8, 19, 14);

      final correction = await subject.applyCorrections(
        text: 'He go to school.',
        replacements: {
          (3, 5): 'goes',
        },
        appliedRuleIds: const ['rule.subject-verb'],
        at: at,
        documentId: 'doc-42',
        pageNumber: 7,
      );

      expect(correction.correctedText, 'He goes to school.');
      expect(correction.documentId, 'doc-42');
      expect(correction.pageNumber, 7);
      expect(correction.appliedRuleIds, ['rule.subject-verb']);

      final stored = await corrections.loadAll();
      expect(stored, hasLength(1));
      expect(stored.single.correctedText, 'He goes to school.');
    });

    test('getCorrections is safe on empty storage', () async {
      final subject = service();
      expect(await subject.getCorrections(), isEmpty);
    });

    test('getCorrections orders newest first and removeCorrection deletes',
        () async {
      final subject = service();
      final first = await subject.applyCorrections(
        text: 'a a',
        replacements: {(0, 3): 'a'},
        appliedRuleIds: const ['rule.repeated-word'],
        at: DateTime.utc(2026, 8, 1, 9),
      );
      await subject.applyCorrections(
        text: 'b b',
        replacements: {(0, 3): 'b'},
        appliedRuleIds: const ['rule.repeated-word'],
        at: DateTime.utc(2026, 8, 2, 9),
      );

      final all = await subject.getCorrections();
      expect(all.map((c) => c.originalText).toList(), ['b b', 'a a']);

      await subject.removeCorrection(first.id);
      final remaining = await subject.getCorrections();
      expect(remaining.map((c) => c.originalText).toList(), ['b b']);
    });
  });

  group('provider defaults', () {
    test('remote grammar checking defaults to LOCAL_ONLY', () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          grammarEngineProvider
              .overrideWithValue(FakeGrammarEngine((_) => const [])),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(grammarRemoteEnabledProvider), isFalse);
      expect(container.read(grammarServiceProvider).remoteEnabled, isFalse);
    });
  });
}
