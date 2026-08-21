import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/domain/entities/reading_position.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/reader_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_reader/src/widgets/document_search_bar.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

// "%PDF-" magic header bytes, supplied to validation so the tests never
// touch the real file system (dart:io stalls inside the FakeAsync zone).
const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];

const String fakePdfPath = '/titan/reader/fixtures/sample.pdf';

void main() {
  late InMemoryStorageService storage;
  late FakePdfEngine engine;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    engine = FakePdfEngine();
  });

  LibraryService service() => LibraryService(
        library: StorageDocumentLibraryRepository(storage),
        positions: StorageReadingPositionRepository(storage),
        history: ReadingHistoryService(storage),
      );

  Widget buildSubject(String documentId) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(engine),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          fileExists: (path) => true,
        ),
      ),
    );
  }

  testWidgets('shows a friendly screen when the document is unknown',
      (tester) async {
    await tester.pumpWidget(buildSubject('ghost'));
    await tester.pump();

    expect(find.text('Document not found'), findsOneWidget);
    expect(find.text('Back to library'), findsOneWidget);
  });

  testWidgets('restores the saved reading position into the viewer',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );
    await libraryService.savePosition(ReadingPosition(
      documentId: document.id,
      pageNumber: 4,
      updatedAt: DateTime.utc(2026, 8, 2),
    ));

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    expect(handle.lastFilePath, fakePdfPath);
    expect(handle.lastSettings!.initialPage, 4);
    // Opening records a visit for the Recent shelf.
    expect(await libraryService.getRecentDocumentIds(), [document.id]);
  });

  testWidgets('engine page changes persist the reading position',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    await handle.goToPage(7);
    await tester.pump();

    expect(find.text('7 / 10'), findsOneWidget);
    final saved = await libraryService.loadPosition(document.id);
    expect(saved, isNotNull);
    expect(saved!.pageNumber, 7);
    expect(saved.totalPages, 10);
    // Engine page count is written back to the library metadata.
    expect((await libraryService.getDocuments()).single.pageCount, 10);
  });

  testWidgets('search action opens the search bar wired to the handle',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    expect(find.byType(DocumentSearchBar), findsNothing);
    await tester.tap(find.byTooltip('Search document'));
    await tester.pump();
    expect(find.byType(DocumentSearchBar), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'article');
    await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));

    expect(engine.lastHandle!.searchQueries, ['article']);

    await tester.tap(find.descendant(
      of: find.byType(DocumentSearchBar),
      matching: find.byTooltip('Close search'),
    ));
    await tester.pump();
    expect(find.byType(DocumentSearchBar), findsNothing);
  });

  testWidgets('slider navigates through pages', (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    // Once the engine reports a page count the slider covers the range.
    handle.firePageChanged(1);
    await tester.pump();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);

    await tester.drag(slider, const Offset(120, 0));
    await tester.pump();

    expect(handle.visitedPages, isNotEmpty);
    expect(handle.visitedPages.last, greaterThan(1));
  });

  testWidgets('thumbnail sidebar button toggles sidebar and navigates on tap',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    handle.pageCount = 8;
    handle.firePageChanged(1);
    await tester.pump();

    final toggleButton = find.byKey(const Key('thumbnails-sidebar-button'));
    expect(toggleButton, findsOneWidget);

    // Open sidebar
    await tester.tap(toggleButton);
    await tester.pump();

    expect(find.text('Thumbnails (8)'), findsOneWidget);

    // Tap thumbnail for page 2
    final page2Thumbnail = find.byKey(const Key('thumbnail-page-2'));
    expect(page2Thumbnail, findsOneWidget);

    await tester.tap(page2Thumbnail);
    await tester.pump();

    expect(handle.visitedPages, contains(2));

    // Close sidebar
    await tester.tap(find.byKey(const Key('close-thumbnail-sidebar-button')));
    await tester.pump();

    expect(find.text('Thumbnails (8)'), findsNothing);
  });

  testWidgets(
      'Phase 6D-2: opens outline sidebar and navigates on outline node tap',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    handle.pageCount = 20;
    handle.scriptedOutline = const [
      ReaderOutlineEntry(
        title: 'Chapter 1: Foundations',
        path: '0',
        pageNumber: 1,
      ),
      ReaderOutlineEntry(
        title: 'Chapter 2: Advanced Topics',
        path: '1',
        pageNumber: 12,
      ),
    ];
    handle.firePageChanged(1);
    await tester.pump();

    final outlineButton = find.byKey(const Key('outline-sidebar-button'));
    expect(outlineButton, findsOneWidget);

    // Open outline sidebar
    await tester.tap(outlineButton);
    await tester.pumpAndSettle();

    expect(find.text('Table of Contents'), findsOneWidget);
    expect(find.text('Chapter 1: Foundations'), findsOneWidget);
    expect(find.text('Chapter 2: Advanced Topics'), findsOneWidget);

    // Tap chapter 2
    final ch2Node = find.byKey(const Key('outline-node-1'));
    expect(ch2Node, findsOneWidget);

    await tester.tap(ch2Node);
    await tester.pumpAndSettle();

    expect(handle.visitedOutlinePaths, contains('1'));
    expect(handle.visitedPages, contains(12));

    // Close outline sidebar
    await tester.tap(find.byKey(const Key('close-outline-sidebar-button')));
    await tester.pumpAndSettle();

    expect(find.text('Table of Contents'), findsNothing);
  });

  testWidgets(
      'Phase 6D-4: renders DocumentSelectionToolbar on selection and handles actions',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pumpAndSettle();

    final handle = engine.lastHandle!;
    expect(find.byKey(const Key('selection-copy-button')), findsNothing);

    // Simulate user selecting text in the viewer
    handle.scriptedSelection = const PdfTextSelectionSnapshot(
      text: 'Neural Networks and Deep Learning',
      fragments: [],
    );
    handle.fireSelectionChanged();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selection-copy-button')), findsOneWidget);
    expect(find.text('Neural Networks and Deep Learning'), findsOneWidget);

    // Tap search action in toolbar
    await tester.tap(find.byKey(const Key('selection-search-button')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentSearchBar), findsOneWidget);
    expect(handle.searchQueries, contains('Neural Networks and Deep Learning'));
  });
}
