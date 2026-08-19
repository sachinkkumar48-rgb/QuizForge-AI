import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_reader/src/data/bundled_dictionary_data_source.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/navigation/reader_routes.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/vocabulary_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/navigation/reader_router.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

// "%PDF-" magic header bytes written to a real temp file so the
// reader's production file-exists check passes.
const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];

const NormalizedPageRect wordRect = NormalizedPageRect(
  left: 0.1,
  top: 0.2,
  right: 0.3,
  bottom: 0.25,
);

DictionaryEntry entry(String word, {List<String> synonyms = const []}) =>
    DictionaryEntry(
      word: word,
      normalizedWord: word,
      senses: [
        DictionarySense(
          partOfSpeech: 'adjective',
          definitions: ['definition of $word'],
          examples: ['an example with $word'],
          synonyms: synonyms,
        ),
      ],
      source: const DictionarySourceInfo(
          id: 'test-dictionary', attribution: 'Test dictionary'),
    );

void main() {
  late InMemoryStorageService storage;
  late FakePdfEngine engine;
  late InMemoryDictionaryDataSource localSource;
  late GoRouter router;
  late io.Directory tempDir;
  late String fakePdfPath;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    engine = FakePdfEngine();
    localSource = InMemoryDictionaryDataSource({
      'ephemeral': entry('ephemeral', synonyms: ['transitory']),
      'transitory': entry('transitory'),
    });
    // Fresh router per test: no navigation state leaks between cases.
    router = buildReaderRouter();
    // Real file on disk: the reader route cannot inject a fake file-exists
    // check, so the import points at an actual temporary PDF.
    tempDir = await io.Directory.systemTemp.createTemp('titan_reader_it');
    final file =
        io.File('${tempDir.path}${io.Platform.pathSeparator}sample.pdf');
    await file.writeAsBytes(pdfHeader, flush: true);
    fakePdfPath = file.path;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  List<Override> overrides({DictionaryDataSource? source}) => [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(engine),
        dictionaryDataSourceProvider.overrideWithValue(source ?? localSource),
        // LOCAL_ONLY: no remote source is ever reachable in these tests.
        remoteDictionarySourceProvider.overrideWithValue(null),
      ];

  LibraryService libraryService() => LibraryService(
        library: StorageDocumentLibraryRepository(storage),
        positions: StorageReadingPositionRepository(storage),
        history: ReadingHistoryService(storage),
      );

  Future<String> importSample() async {
    final document = await libraryService().importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );
    return document.id;
  }

  Widget app({DictionaryDataSource? source}) {
    return ProviderScope(
      overrides: overrides(source: source),
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Pumps the app at [location] and waits for the reader to prepare.
  Future<FakeViewerHandle> openReader(WidgetTester tester, String documentId,
      {DictionaryDataSource? source}) async {
    await tester.pumpWidget(app(source: source));
    router.go(ReaderRoutes.readerFor(documentId));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    return engine.lastHandle!;
  }

  PdfTextSelectionSnapshot selection(String text, int page) {
    return PdfTextSelectionSnapshot(
      text: text,
      fragments: [PdfSelectionFragment(pageNumber: page, rect: wordRect)],
    );
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
          tester.element(find.byType(VocabularyScreen).first));

  group('integration workflow 1: select → dictionary → save → vocabulary', () {
    testWidgets(
        'selected word opens the dictionary, saves, and reopens from '
        'My Vocabulary', (tester) async {
      final documentId = await importSample();
      final handle = await openReader(tester, documentId);

      // Select "Ephemeral," in the PDF and invoke the Dictionary action.
      handle.scriptedSelection = selection('"Ephemeral,"', 3);
      handle.lastSettings!.onSelectionAction!('dictionary');
      await tester.pumpAndSettle();

      // The dictionary panel shows the normalized word and its entry.
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
      expect(find.text('ephemeral'), findsWidgets);
      expect(find.textContaining('definition of ephemeral'), findsOneWidget);
      expect(handle.clearSelectionCalled, isTrue);

      // Save the word from the panel.
      await tester.tap(find.byKey(const Key('dictionary-save-word-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved "ephemeral"'), findsOneWidget);

      // Navigate to My Vocabulary; the saved word is listed.
      router.go(ReaderRoutes.vocabulary);
      await tester.pumpAndSettle();
      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.textContaining('Source: sample · page 3'), findsOneWidget);

      // Opening the word from the vocabulary shows its dictionary entry.
      await tester.tap(find.text('ephemeral'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
      expect(find.textContaining('definition of ephemeral'), findsOneWidget);
    });
  });

  group('integration workflow 2: source tracking and jump-back', () {
    testWidgets('saved word records the source page and opens it again',
        (tester) async {
      final documentId = await importSample();
      final handle = await openReader(tester, documentId);

      // Save the selected word straight from the toolbar on page 3.
      handle.scriptedSelection = selection('Ephemeral,', 3);
      handle.lastSettings!.onSelectionAction!('save-word');
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved "ephemeral"'), findsOneWidget);

      // Vocabulary shows the source reference.
      router.go(ReaderRoutes.vocabulary);
      await tester.pumpAndSettle();
      expect(find.textContaining('Source: sample · page 3'), findsOneWidget);

      final service = containerOf(tester).read(vocabularyServiceProvider);
      final saved = service.wordForNormalized('ephemeral')!;
      expect(saved.sourceDocumentId, documentId);
      expect(saved.sourcePage, 3);

      // Open the source: the reader reopens at the recorded page.
      await tester
          .tap(find.byKey(ValueKey('vocabulary-open-source-${saved.id}')));
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final reopened = engine.lastHandle!;
      expect(reopened.lastFilePath, fakePdfPath);
      expect(reopened.lastSettings!.initialPage, 3);
    });
  });

  group('integration workflow 3: fully offline dictionary + vocabulary', () {
    testWidgets(
        'offline lookup, save, restart and vocabulary persistence without '
        'any remote source', (tester) async {
      final documentId = await importSample();
      await openReader(tester, documentId);

      // Open the dictionary from the AppBar (no selection) and search.
      await tester.tap(find.byKey(const Key('dictionary-panel-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('dictionary-search-field')), 'ephemeral');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
      expect(find.textContaining('definition of ephemeral'), findsOneWidget);

      // Save it.
      await tester.tap(find.byKey(const Key('dictionary-save-word-button')));
      await tester.pumpAndSettle();

      // A word missing from the bundled dictionary shows the explicit
      // offline state — remote lookup stays disabled by default.
      await tester.enterText(
          find.byKey(const Key('dictionary-search-field')), 'zzzzzz');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionary-offline-unavailable')),
          findsOneWidget);

      // Simulate an app restart: new widget tree, same storage.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      router = buildReaderRouter();
      await tester.pumpWidget(app());
      router.go(ReaderRoutes.vocabulary);
      await tester.pumpAndSettle();

      // The saved word survives the restart and opens its entry offline.
      expect(find.text('ephemeral'), findsOneWidget);
      await tester.tap(find.text('ephemeral'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
    });
  });

  group('acceptance: bundled WordNet dictionary (§50)', () {
    test('real bundled dataset resolves "ephemeral" fully offline', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final source = BundledDictionaryDataSource();
      final result = await source.lookup('ephemeral');
      expect(result, isNotNull, reason: 'ephemeral must ship in the bundle');
      expect(result!.normalizedWord, 'ephemeral');
      expect(result.senses, isNotEmpty);
      expect(
        result.senses.expand((s) => s.definitions),
        isNotEmpty,
        reason: 'definitions are source-backed, never fabricated',
      );
      expect(result.source.id, 'wordnet-3.0');
      expect(result.source.attribution, contains('Princeton'));

      final suggestions = await source.prefixMatches('ephem');
      expect(suggestions, contains('ephemeral'));
    });

    testWidgets(
        'end-to-end acceptance with the real bundled dictionary: select, '
        'look up, save, restart, reopen', (tester) async {
      final documentId = await importSample();
      final handle = await openReader(tester, documentId,
          source: BundledDictionaryDataSource());

      handle.scriptedSelection = selection('Ephemeral,', 3);
      handle.lastSettings!.onSelectionAction!('dictionary');
      await tester.pumpAndSettle();

      // The real WordNet entry renders: definitions plus attribution.
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
      expect(find.byKey(const ValueKey('dictionary-definition-1')),
          findsOneWidget);
      expect(find.byKey(const Key('dictionary-attribution')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dictionary-save-word-button')));
      await tester.pumpAndSettle();

      // Restart against the same storage.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      router = buildReaderRouter();
      await tester.pumpWidget(app(source: BundledDictionaryDataSource()));
      router.go(ReaderRoutes.vocabulary);
      await tester.pumpAndSettle();
      expect(find.text('ephemeral'), findsOneWidget);

      await tester.tap(find.text('ephemeral'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionary-word-header')), findsOneWidget);
      expect(find.byKey(const Key('dictionary-attribution')), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
