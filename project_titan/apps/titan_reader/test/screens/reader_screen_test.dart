import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/reading_position.dart';
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
}
