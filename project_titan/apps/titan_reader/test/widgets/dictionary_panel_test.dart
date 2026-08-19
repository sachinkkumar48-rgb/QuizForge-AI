import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/widgets/dictionary_panel.dart';
import 'package:titan_storage/titan_storage.dart';

DictionaryEntry entry(String word,
        {List<String> synonyms = const [], List<String> antonyms = const []}) =>
    DictionaryEntry(
      word: word,
      normalizedWord: word,
      senses: [
        DictionarySense(
          partOfSpeech: 'adjective',
          definitions: ['definition of $word', 'second definition'],
          examples: ['an example with $word'],
          synonyms: synonyms,
          antonyms: antonyms,
        ),
      ],
      source: const DictionarySourceInfo(
          id: 'test-dictionary', attribution: 'Test attribution'),
    );

void main() {
  late InMemoryStorageService storage;
  late InMemoryDictionaryDataSource localSource;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    localSource = InMemoryDictionaryDataSource({
      'ephemeral':
          entry('ephemeral', synonyms: ['transitory'], antonyms: ['eternal']),
      'transitory': entry('transitory'),
    });
  });

  Widget buildSubject({String? word}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        dictionaryDataSourceProvider.overrideWithValue(localSource),
        remoteDictionarySourceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        // A distinct key per opening mirrors production: every sheet
        // presentation creates a brand-new panel state.
        home: Scaffold(
          body: DictionaryPanel(
            key: ValueKey('dictionary-panel-${word ?? 'home'}'),
            initialWord: word,
          ),
        ),
      ),
    );
  }

  testWidgets('renders a found entry with definitions and attribution',
      (tester) async {
    await tester.pumpWidget(buildSubject(word: '"Ephemeral,"'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
    expect(find.text('ephemeral'), findsWidgets);
    expect(find.byKey(const Key('dictionary-pos-0')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('dictionary-definition-1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('dictionary-definition-2')), findsOneWidget);
    expect(find.textContaining('an example with ephemeral'), findsOneWidget);
    expect(find.byKey(const Key('dictionary-attribution')), findsOneWidget);
    expect(
        find.byKey(const Key('dictionary-save-word-button')), findsOneWidget);
  });

  testWidgets('save word stores the word with source context', (tester) async {
    await tester.pumpWidget(buildSubject(word: 'ephemeral'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-save-word-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved "ephemeral"'), findsOneWidget);

    final service = ProviderScope.containerOf(tester
            .element(find.byKey(const Key('dictionary-save-word-button'))))
        .read(vocabularyServiceProvider);
    final saved = service.wordForNormalized('ephemeral');
    expect(saved, isNotNull);
    expect(saved!.status.name, 'isNew');

    // Saving again reports the existing word instead of duplicating.
    // Dismiss the first snackbar so the second one is unambiguous.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictionary-save-word-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('already in My Vocabulary'), findsOneWidget);
    expect(service.words, hasLength(1));
  });

  testWidgets('unknown bundled word shows the offline-unavailable state',
      (tester) async {
    await tester.pumpWidget(buildSubject(word: 'zebra'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dictionary-offline-unavailable')),
        findsOneWidget);
    expect(find.byKey(const Key('dictionary-online-toggle')), findsOneWidget);
    expect(find.byKey(const Key('dictionary-not-found')), findsNothing);
  });

  testWidgets('synonym chips push a new lookup and back pops', (tester) async {
    await tester.pumpWidget(buildSubject(word: 'ephemeral'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('dictionary-synonym-transitory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-back-button')), findsOneWidget);
    expect(find.text('transitory'), findsWidgets);

    await tester.tap(find.byKey(const Key('dictionary-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-back-button')), findsNothing);
  });

  testWidgets('search view shows recent lookups and can clear them',
      (tester) async {
    // First lookup records the word in history.
    await tester.pumpWidget(buildSubject(word: 'ephemeral'));
    await tester.pumpAndSettle();

    // Reopen the panel without a word: search home shows history.
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-recent-ephemeral')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('dictionary-clear-history-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-recent-ephemeral')),
        findsNothing);
  });

  testWidgets('search field offers suggestions and opens the tapped word',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('dictionary-search-field')), 'ephe');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-suggestion-ephemeral')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('dictionary-suggestion-ephemeral')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);

    // Submitting a full word directly also performs a lookup.
    await tester.enterText(
        find.byKey(const Key('dictionary-search-field')), 'transitory');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('transitory'), findsWidgets);
  });
}
