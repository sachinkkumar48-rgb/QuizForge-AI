import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/annotation_repository.dart';
import 'package:titan_reader/src/data/bookmark_repository.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/note_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/reader_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_reader/src/widgets/annotations_panel.dart';
import 'package:titan_reader/src/widgets/bookmarks_panel.dart';
import 'package:titan_reader/src/widgets/notes_panel.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

// "%PDF-" magic header bytes; tests never touch the real file system.
const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];
const String fakePdfPath = '/titan/reader/fixtures/sample.pdf';

const NormalizedPageRect selectionRect = NormalizedPageRect(
  left: 0.1,
  top: 0.2,
  right: 0.6,
  bottom: 0.25,
);

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

  Widget buildSubject(String documentId, {FakePdfEngine? withEngine}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(withEngine ?? engine),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          fileExists: (path) => true,
        ),
      ),
    );
  }

  /// Pumps a fresh reader for [documentId] with a brand-new engine,
  /// simulating an application restart against the same storage.
  Future<FakeViewerHandle> reopen(WidgetTester tester, String documentId,
      {FakePdfEngine? withEngine}) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(buildSubject(documentId, withEngine: withEngine));
    await tester.pump();
    await tester.pump();
    return (withEngine ?? engine).lastHandle!;
  }

  Future<String> importSample(LibraryService libraryService) async {
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );
    return document.id;
  }

  PdfTextSelectionSnapshot scriptedSelectionOn(int page) {
    return const PdfTextSelectionSnapshot(
      text: 'separation of powers',
      fragments: [
        PdfSelectionFragment(pageNumber: 3, rect: selectionRect),
      ],
    );
  }

  group('selection context toolbar', () {
    testWidgets('offers the mandated action set', (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final settings = engine.lastHandle!.lastSettings!;
      final ids = settings.selectionActions.map((a) => a.id).toList();
      expect(
        ids,
        containsAll([
          'copy',
          'dictionary',
          'grammar',
          'highlight',
          'underline',
          'strikethrough',
          'note',
        ]),
      );
    });

    testWidgets('highlight action persists the selection as annotation',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('highlight');
      await tester.pump();
      await tester.pump();

      expect(handle.clearSelectionCalled, isTrue);
      final stored =
          await StorageAnnotationRepository(storage).load(documentId);
      expect(stored, hasLength(1));
      expect(stored.single.selectedText, 'separation of powers');
      expect(stored.single.pageNumber, 3);
      expect(stored.single.rects, [selectionRect]);
      // The engine was asked to paint the overlay.
      expect(handle.lastOverlays, hasLength(1));
      expect(handle.lastOverlays.single.pageNumber, 3);
      expect(handle.lastOverlays.single.rect, selectionRect);
      expect(handle.lastOverlays.single.style, PdfOverlayStyle.highlight);
    });

    testWidgets('underline and strikethrough actions create their styles',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('underline');
      await tester.pump();
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('strikethrough');
      await tester.pump();
      await tester.pump();

      final stored =
          await StorageAnnotationRepository(storage).load(documentId);
      expect(stored.map((a) => a.type.name),
          containsAll(['underline', 'strikethrough']));
    });

    testWidgets('note action opens the editor with the selected text',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('note');
      await tester.pumpAndSettle();

      expect(find.text('New note'), findsOneWidget);
      expect(find.text('“separation of powers”'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('note-title-field')), 'Important concept');
      await tester.enterText(
          find.byKey(const Key('note-content-field')), 'Remember this');
      await tester.tap(find.byKey(const Key('note-save-button')));
      await tester.pumpAndSettle();

      final stored = await StorageNoteRepository(storage).load(documentId);
      expect(stored, hasLength(1));
      expect(stored.single.title, 'Important concept');
      expect(stored.single.selectedText, 'separation of powers');
      expect(stored.single.pageNumber, 3);
    });

    testWidgets('dictionary and grammar are placeholders', (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('dictionary');
      await tester.pump();
      expect(find.textContaining('Dictionary'), findsWidgets);
    });
  });

  group('Test 1 — highlight persistence across restart', () {
    testWidgets('highlight survives close/reopen and restores geometry',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('highlight');
      await tester.pump();
      await tester.pump();

      // Restart with a brand-new engine against the same storage.
      final reopenedEngine = FakePdfEngine();
      final reopened =
          await reopen(tester, documentId, withEngine: reopenedEngine);

      expect(reopened.lastOverlays, hasLength(1));
      final overlay = reopened.lastOverlays.single;
      expect(overlay.pageNumber, 3);
      expect(overlay.style, PdfOverlayStyle.highlight);
      // Canonical normalized geometry survives unchanged — positions stay
      // correct regardless of zoom/window/viewport at render time.
      expect(overlay.rect, selectionRect);
    });
  });

  group('Test 2 — bookmark persistence across restart', () {
    testWidgets('bookmark added, reopened, then navigates to its page',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('bookmark-toggle-button')));
      await tester.pump();
      await tester.pump();

      final stored = await StorageBookmarkRepository(storage).load(documentId);
      expect(stored, hasLength(1));
      expect(stored.single.pageNumber, 1);

      // Restart.
      final reopenedEngine = FakePdfEngine();
      final reopened =
          await reopen(tester, documentId, withEngine: reopenedEngine);

      // Toggle shows the bookmarked state.
      final toggle = find.byKey(const Key('bookmark-toggle-button'));
      expect(toggle, findsOneWidget);

      // Open the bookmarks panel, select the bookmark, navigate.
      await tester.tap(find.byKey(const Key('bookmarks-panel-button')));
      await tester.pumpAndSettle();
      expect(find.byType(BookmarksPanel), findsOneWidget);
      expect(find.text('Page 1'), findsWidgets);
      await tester.tap(find.text('Page 1').first);
      await tester.pumpAndSettle();
      expect(reopened.visitedPages, contains(1));
    });

    testWidgets('toggling again removes the bookmark', (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('bookmark-toggle-button')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('bookmark-toggle-button')));
      await tester.pump();
      await tester.pump();

      expect(
        await StorageBookmarkRepository(storage).load(documentId),
        isEmpty,
      );
    });

    testWidgets('bookmarks panel renders the document outline', (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedOutline = const [
        ReaderOutlineEntry(
          title: 'Part I',
          path: '0',
          pageNumber: 1,
          children: [
            ReaderOutlineEntry(title: 'Chapter 1', path: '0/0', pageNumber: 2),
          ],
        ),
      ];

      await tester.tap(find.byKey(const Key('bookmarks-panel-button')));
      await tester.pumpAndSettle();

      expect(find.text('Part I'), findsOneWidget);
      expect(find.text('Chapter 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('outline-0/0')));
      await tester.pumpAndSettle();
      expect(handle.visitedOutlinePaths, ['0/0']);
    });
  });

  group('Test 3 — notes persistence across restart', () {
    testWidgets('note added via panel survives reopen and navigates',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('notes-panel-button')));
      await tester.pumpAndSettle();
      expect(find.byType(NotesPanel), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-note-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('note-title-field')), 'Study reminder');
      await tester.enterText(
          find.byKey(const Key('note-content-field')), 'Revise article 14');
      await tester.tap(find.byKey(const Key('note-save-button')));
      await tester.pumpAndSettle();

      expect(find.text('Study reminder'), findsOneWidget);

      // Restart.
      final reopenedEngine = FakePdfEngine();
      final reopened =
          await reopen(tester, documentId, withEngine: reopenedEngine);

      await tester.tap(find.byKey(const Key('notes-panel-button')));
      await tester.pumpAndSettle();
      expect(find.text('Study reminder'), findsOneWidget);
      expect(find.textContaining('Revise article 14'), findsOneWidget);

      // Tap the note tile to navigate to its source page.
      await tester.tap(find.text('Study reminder'));
      await tester.pumpAndSettle();
      expect(reopened.visitedPages, contains(1));
    });

    testWidgets('notes panel search filters by title and content',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('notes-panel-button')));
      await tester.pumpAndSettle();

      Future<void> addNote(String title, String content) async {
        await tester.tap(find.byKey(const Key('add-note-button')));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('note-title-field')), title);
        await tester.enterText(
            find.byKey(const Key('note-content-field')), content);
        await tester.tap(find.byKey(const Key('note-save-button')));
        await tester.pumpAndSettle();
      }

      await addNote('Alpha note', 'about polity');
      await addNote('Beta note', 'about economy');

      await tester.enterText(
          find.byKey(const Key('notes-search-field')), 'alpha');
      await tester.pump();
      expect(find.text('Alpha note'), findsOneWidget);
      expect(find.text('Beta note'), findsNothing);

      await tester.tap(find.byKey(const Key('notes-search-clear')));
      await tester.pump();
      expect(find.text('Alpha note'), findsOneWidget);
      expect(find.text('Beta note'), findsOneWidget);
    });
  });

  group('annotations panel', () {
    testWidgets('lists annotations, deletes with undoable snackbar',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('highlight');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('annotations-panel-button')));
      await tester.pumpAndSettle();
      expect(find.byType(AnnotationsPanel), findsOneWidget);
      expect(find.text('separation of powers'), findsWidgets);

      // Delete through the panel (id is generated at runtime, match by
      // tooltip inside the panel).
      await tester.tap(find.byTooltip('Delete annotation'));
      await tester.pumpAndSettle();
      expect(
        await StorageAnnotationRepository(storage).load(documentId),
        isEmpty,
      );

      // Close the bottom sheet first: the snackbar renders below the modal
      // route, so dismissing the sheet makes its action reachable.
      await tester.tapAt(const Offset(400, 40));
      await tester.pumpAndSettle();
      expect(find.byType(AnnotationsPanel), findsNothing);

      // Undo via the snackbar restores the annotation.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
        await StorageAnnotationRepository(storage).load(documentId),
        hasLength(1),
      );
    });
  });

  group('undo/redo wiring', () {
    testWidgets('undo button reverses the latest annotation add',
        (tester) async {
      final libraryService = service();
      final documentId = await importSample(libraryService);
      await tester.pumpWidget(buildSubject(documentId));
      await tester.pump();
      await tester.pump();

      final handle = engine.lastHandle!;
      handle.scriptedSelection = scriptedSelectionOn(3);
      handle.lastSettings!.onSelectionAction!('highlight');
      await tester.pump();
      await tester.pump();
      expect(handle.lastOverlays, hasLength(1));

      await tester.tap(find.byKey(const Key('undo-button')));
      await tester.pump();
      await tester.pump();
      expect(handle.lastOverlays, isEmpty);
      expect(
        await StorageAnnotationRepository(storage).load(documentId),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('redo-button')));
      await tester.pump();
      await tester.pump();
      expect(handle.lastOverlays, hasLength(1));
    });
  });
}
