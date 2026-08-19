import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/vocabulary_word.dart';
import 'package:titan_reader/src/navigation/reader_routes.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/vocabulary_screen.dart';
import 'package:titan_storage/titan_storage.dart';

DictionaryEntry entry(String word) => DictionaryEntry(
      word: word,
      normalizedWord: word,
      senses: const [
        DictionarySense(
            partOfSpeech: 'adjective', definitions: ['a definition']),
      ],
      source: const DictionarySourceInfo(id: 'test', attribution: 'test'),
    );

void main() {
  late InMemoryStorageService storage;
  late InMemoryDictionaryDataSource localSource;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    localSource = InMemoryDictionaryDataSource({
      'ephemeral': entry('ephemeral'),
      'diurnal': entry('diurnal'),
    });
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        dictionaryDataSourceProvider.overrideWithValue(localSource),
        remoteDictionarySourceProvider.overrideWithValue(null),
      ];

  /// Router used to verify source navigation; the reader route renders a
  /// probe showing the exact location requested.
  GoRouter buildRouter() => GoRouter(
        initialLocation: ReaderRoutes.vocabulary,
        routes: [
          GoRoute(
            path: ReaderRoutes.vocabulary,
            builder: (context, state) => const VocabularyScreen(),
          ),
          GoRoute(
            path: '/reader/:documentId',
            builder: (context, state) => Scaffold(
              key: const Key('reader-nav-probe'),
              body: Text(state.uri.toString()),
            ),
          ),
        ],
      );

  Future<ProviderContainer> seedContainer() async {
    final container = ProviderContainer(overrides: overrides());
    final service = container.read(vocabularyServiceProvider);
    await service.saveWord(
      rawWord: 'ephemeral',
      at: DateTime.utc(2026, 8, 19, 10),
      sourceDocumentId: 'doc_1',
      sourceDocumentName: 'sample.pdf',
      sourcePage: 3,
    );
    await service.saveWord(
      rawWord: 'diurnal',
      at: DateTime.utc(2026, 8, 19, 9),
    );
    return container;
  }

  Widget buildSubject(ProviderContainer container, {GoRouter? router}) {
    final effectiveRouter = router ?? buildRouter();
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: effectiveRouter),
    );
  }

  Finder wordTile(String id) => find.byKey(ValueKey('vocabulary-word-$id'));

  testWidgets('lists saved words with source tracking', (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    final ephemeral = service.wordForNormalized('ephemeral')!;
    final diurnal = service.wordForNormalized('diurnal')!;
    expect(wordTile(ephemeral.id), findsOneWidget);
    expect(wordTile(diurnal.id), findsOneWidget);
    expect(find.text('Source: sample.pdf · page 3'), findsOneWidget);
  });

  testWidgets('search filters the list', (tester) async {
    final container = await seedContainer();
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('vocabulary-search-field')), 'ephem');
    await tester.pumpAndSettle();
    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('diurnal'), findsNothing);
  });

  testWidgets('status change and status filter', (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    final ephemeral = service.wordForNormalized('ephemeral')!;
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    // Change status through the dialog.
    await tester.tap(find.byKey(ValueKey('vocabulary-status-${ephemeral.id}')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('vocabulary-status-option-mastered')));
    await tester.pumpAndSettle();
    expect(service.wordFor(ephemeral.id)!.status,
        VocabularyMasteryStatus.mastered);

    // Filter to only mastered words.
    await tester.tap(find.byKey(const ValueKey('vocabulary-filter-mastered')));
    await tester.pumpAndSettle();
    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('diurnal'), findsNothing);
  });

  testWidgets('delete removes the word and persists', (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    final diurnal = service.wordForNormalized('diurnal')!;
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('vocabulary-delete-${diurnal.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Removed "diurnal"'), findsOneWidget);
    expect(service.wordForNormalized('diurnal'), isNull);
    expect(service.words, hasLength(1));
  });

  testWidgets(
      'edit dialog updates personal meaning without touching the '
      'word itself', (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    final ephemeral = service.wordForNormalized('ephemeral')!;
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('vocabulary-edit-${ephemeral.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('vocab-meaning-field')), 'short-lived');
    await tester.enterText(
        find.byKey(const Key('vocab-note-field')), 'remember: mayfly');
    await tester.tap(find.byKey(const Key('vocab-save-button')));
    await tester.pumpAndSettle();

    final updated = service.wordFor(ephemeral.id)!;
    expect(updated.personalMeaning, 'short-lived');
    expect(updated.personalNote, 'remember: mayfly');
    expect(updated.word, 'ephemeral');
    // The tile subtitle joins meaning and source line; match a substring.
    expect(find.textContaining('short-lived'), findsOneWidget);
  });

  testWidgets('open source navigates to the saved document and page',
      (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    final ephemeral = service.wordForNormalized('ephemeral')!;
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(ValueKey('vocabulary-open-source-${ephemeral.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-nav-probe')), findsOneWidget);
    expect(find.text('/reader/doc_1?page=3'), findsOneWidget);
  });

  testWidgets('empty vocabulary shows guidance', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vocabulary-empty')), findsOneWidget);
    expect(find.textContaining('No saved words yet'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tapping a word opens its dictionary entry', (tester) async {
    final container = await seedContainer();
    final service = container.read(vocabularyServiceProvider);
    final ephemeral = service.wordForNormalized('ephemeral')!;
    await tester.pumpWidget(buildSubject(container));
    await tester.pumpAndSettle();

    await tester.tap(wordTile(ephemeral.id), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
  });
}
