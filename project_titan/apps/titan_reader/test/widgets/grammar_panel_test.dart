import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/data/grammar_cache_repository.dart';
import 'package:titan_reader/src/data/grammar_correction_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/remote_grammar_source.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/grammar_errors.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/grammar_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/services/grammar_service.dart';
import 'package:titan_reader/src/widgets/dictionary_panel.dart';
import 'package:titan_reader/src/widgets/grammar_panel.dart';
import 'package:titan_storage/titan_storage.dart';

class FakeGrammarEngine implements GrammarEngine {
  FakeGrammarEngine(this.issuesFor);

  final List<GrammarIssue> Function(String text) issuesFor;

  @override
  String get engineId => 'fake.engine';

  @override
  String get engineVersion => '1.0.0';

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    return issuesFor(text);
  }
}

class FakeRemoteSource implements RemoteGrammarSource {
  FakeRemoteSource(this.error);

  final GrammarCheckError error;

  @override
  String get sourceId => 'remote:fake';

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    throw error;
  }
}

void main() {
  late InMemoryStorageService storage;
  late InMemoryDictionaryDataSource localDictionary;
  String? clipboardText;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    localDictionary = InMemoryDictionaryDataSource({});
    clipboardText = null;
  });

  Widget buildSubject({
    required String text,
    GrammarEngine? engine,
    GrammarService? serviceOverride,
  }) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        dictionaryDataSourceProvider.overrideWithValue(localDictionary),
        remoteDictionarySourceProvider.overrideWithValue(null),
        grammarEngineProvider
            .overrideWithValue(engine ?? FakeGrammarEngine((_) => const [])),
        remoteGrammarSourceProvider.overrideWithValue(null),
        if (serviceOverride != null)
          grammarServiceProvider.overrideWithValue(serviceOverride),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: GrammarPanel(
            key: ValueKey('grammar-panel-$text'),
            text: text,
            documentId: 'doc-1',
            documentName: 'Sample Document',
            pageNumber: 4,
          ),
        ),
      ),
    );
  }

  Future<void> mockClipboard(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  testWidgets('renders issues with original, suggestions and explanation',
      (tester) async {
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'rule.subject-verb',
            type: GrammarIssueType.grammar,
            severity: GrammarIssueSeverity.warning,
            message: '"He go" needs the third-person form.',
            explanation: 'The subject "He" requires "goes".',
            startOffset: 3,
            endOffset: 5,
            originalText: 'go',
            suggestions: [
              GrammarSuggestion(replacement: 'goes'),
              GrammarSuggestion(replacement: 'went'),
            ],
          ),
        ]);
    await tester
        .pumpWidget(buildSubject(text: 'He go to school.', engine: engine));
    await tester.pumpAndSettle();

    expect(find.text('1 issue found'), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('grammar-issue-original-0')), findsOneWidget);
    expect(find.textContaining('"He go" needs the third-person form.'),
        findsOneWidget);
    expect(find.textContaining('The subject "He" requires "goes".'),
        findsOneWidget);
    // Multiple suggestions are both visible (§6).
    expect(find.byKey(const ValueKey('grammar-issue-suggestion-0-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-issue-suggestion-0-1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-apply-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-dismiss-0')), findsOneWidget);
    // The honest PDF limitation notice is always shown (§16).
    expect(find.byKey(const Key('grammar-pdf-note')), findsOneWidget);
    // Non-spelling issues never offer dictionary/vocabulary actions.
    expect(find.byKey(const ValueKey('grammar-dictionary-0')), findsNothing);
  });

  testWidgets('clean text reports no issues', (tester) async {
    await tester.pumpWidget(buildSubject(text: 'A perfectly fine sentence.'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grammar-no-issues')), findsOneWidget);
    expect(find.text('No issues found'), findsOneWidget);
  });

  testWidgets('engine failures render an honest error state', (tester) async {
    final engine = FakeGrammarEngine((_) => throw Exception('boom'));
    await tester.pumpWidget(buildSubject(text: 'any text', engine: engine));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grammar-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsNothing);
  });

  testWidgets('apply stores a Reader-managed correction, never the PDF',
      (tester) async {
    await mockClipboard(tester);
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'rule.repeated-word',
            type: GrammarIssueType.typographical,
            severity: GrammarIssueSeverity.error,
            message: 'Repeated word "the".',
            startOffset: 3,
            endOffset: 7,
            originalText: ' the',
            suggestions: [GrammarSuggestion(replacement: '')],
          ),
        ]);
    await tester.pumpWidget(buildSubject(text: 'the the end.', engine: engine));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('grammar-apply-0-0')));
    await tester.pumpAndSettle();

    // The issue disappears and the user is told the PDF was not touched.
    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsNothing);
    expect(
      find.textContaining('The PDF itself was not modified'),
      findsOneWidget,
    );

    // The correction is stored with source context.
    final service = ProviderScope.containerOf(tester
            .element(find.byKey(const Key('grammar-copy-corrected-button'))))
        .read(grammarServiceProvider);
    final stored = await service.getCorrections();
    expect(stored, hasLength(1));
    expect(stored.single.correctedText, 'the end.');
    expect(stored.single.documentId, 'doc-1');
    expect(stored.single.pageNumber, 4);
    expect(stored.single.appliedRuleIds, ['rule.repeated-word']);

    // Copying the corrected text works end-to-end (§18). Expire the
    // apply snackbar first so the copy snackbar is unambiguous.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grammar-copy-corrected-button')));
    await tester.pumpAndSettle();
    expect(clipboardText, 'the end.');
    expect(find.textContaining('Corrected text copied'), findsOneWidget);
  });

  testWidgets('dismiss removes the issue without storing anything',
      (tester) async {
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'rule.double-space',
            type: GrammarIssueType.typographical,
            severity: GrammarIssueSeverity.warning,
            message: 'Multiple consecutive spaces.',
            startOffset: 3,
            endOffset: 5,
            originalText: '  ',
            suggestions: [GrammarSuggestion(replacement: ' ')],
          ),
        ]);
    await tester.pumpWidget(buildSubject(text: 'two  spaces', engine: engine));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('grammar-dismiss-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsNothing);
    expect(find.byKey(const Key('grammar-no-issues')), findsOneWidget);
    final service = ProviderScope.containerOf(
            tester.element(find.byKey(const Key('grammar-issue-count'))))
        .read(grammarServiceProvider);
    expect(await service.getCorrections(), isEmpty);
  });

  testWidgets('copy suggestion puts the replacement on the clipboard',
      (tester) async {
    await mockClipboard(tester);
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'rule.modal-of',
            type: GrammarIssueType.grammar,
            severity: GrammarIssueSeverity.error,
            message: '"should of" is not a verb phrase.',
            startOffset: 2,
            endOffset: 11,
            originalText: 'should of',
            suggestions: [GrammarSuggestion(replacement: 'should have')],
          ),
        ]);
    await tester
        .pumpWidget(buildSubject(text: 'I should of gone.', engine: engine));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('grammar-copy-suggestion-0-0')));
    await tester.pumpAndSettle();
    expect(clipboardText, 'should have');
    expect(find.textContaining('Suggestion copied'), findsOneWidget);
  });

  testWidgets('spelling issues offer dictionary lookup and vocabulary save',
      (tester) async {
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'spelling.unknown-word',
            type: GrammarIssueType.spelling,
            severity: GrammarIssueSeverity.error,
            message: 'Possible spelling mistake.',
            startOffset: 0,
            endOffset: 7,
            originalText: 'recieve',
            suggestions: [GrammarSuggestion(replacement: 'receive')],
          ),
        ]);
    await tester.pumpWidget(buildSubject(text: 'recieve', engine: engine));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grammar-dictionary-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-vocabulary-0')), findsOneWidget);

    // Save to Vocabulary reuses the Phase 3 service (§26).
    await tester.tap(find.byKey(const ValueKey('grammar-vocabulary-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved "recieve"'), findsOneWidget);
    final vocabulary = ProviderScope.containerOf(
            tester.element(find.byKey(const ValueKey('grammar-vocabulary-0'))))
        .read(vocabularyServiceProvider);
    expect(vocabulary.wordForNormalized('recieve'), isNotNull);

    // Let the snackbar expire so the next one is unambiguous.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Dictionary lookup opens the Phase 3 dictionary panel (§25).
    await tester.tap(find.byKey(const ValueKey('grammar-dictionary-0')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryPanel), findsOneWidget);
  });

  testWidgets(
      'remote failures are reported honestly alongside local '
      'results', (tester) async {
    final engine = FakeGrammarEngine((_) => const [
          GrammarIssue(
            ruleId: 'rule.standalone-i',
            type: GrammarIssueType.style,
            severity: GrammarIssueSeverity.error,
            message: 'The pronoun "I" is always capitalized.',
            startOffset: 0,
            endOffset: 1,
            originalText: 'i',
            suggestions: [GrammarSuggestion(replacement: 'I')],
          ),
        ]);
    final service = GrammarService(
      engine: engine,
      cache: StorageGrammarCacheRepository(storage),
      corrections: StorageGrammarCorrectionRepository(storage),
      remoteSource:
          FakeRemoteSource(const GrammarRemoteException('unreachable')),
      remoteEnabled: true,
    );
    await tester.pumpWidget(buildSubject(
      text: 'i agree.',
      engine: engine,
      serviceOverride: service,
    ));
    await tester.pumpAndSettle();

    // Local results remain available; the failure is visible (§19–20).
    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsOneWidget);
    expect(find.byKey(const Key('grammar-remote-failure')), findsOneWidget);
    expect(find.textContaining('Online check unavailable'), findsOneWidget);
  });
}
