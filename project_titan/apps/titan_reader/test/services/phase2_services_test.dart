import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/annotation_repository.dart';
import 'package:titan_reader/src/data/bookmark_repository.dart';
import 'package:titan_reader/src/data/note_repository.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/reader_annotation.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/domain/entities/reader_note.dart';
import 'package:titan_reader/src/services/annotation_service.dart';
import 'package:titan_reader/src/services/bookmark_service.dart';
import 'package:titan_reader/src/services/note_service.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  late InMemoryStorageService storage;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
  });

  const rect =
      NormalizedPageRect(left: 0.2, top: 0.3, right: 0.8, bottom: 0.35);

  ReaderAnnotation annotation(
    String id,
    String documentId, {
    int page = 1,
    DateTime? createdAt,
    ReaderAnnotationColor color = ReaderAnnotationColor.yellow,
  }) {
    final created = createdAt ?? DateTime.utc(2026, 8, 10);
    return ReaderAnnotation(
      id: id,
      documentId: documentId,
      pageNumber: page,
      type: ReaderAnnotationType.highlight,
      color: color,
      selectedText: 'snippet $id',
      rects: const [rect],
      createdAt: created,
      updatedAt: created,
    );
  }

  group('AnnotationService', () {
    AnnotationService service() => AnnotationService(
          repository: StorageAnnotationRepository(storage),
          idGenerator: (prefix) => 'fixed_$prefix',
        );

    test('add persists and exposes the annotation in creation order', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(
          annotation('a2', 'doc_1', createdAt: DateTime.utc(2026, 8, 11)));
      await subject.addAnnotation(
          annotation('a1', 'doc_1', createdAt: DateTime.utc(2026, 8, 10)));
      // preload sorts by createdAt on next load; the live cache keeps
      // insertion order, both views are deterministic.
      expect(subject.annotationsFor('doc_1').map((a) => a.id), ['a2', 'a1']);
      final reloaded = service();
      await reloaded.preload('doc_1');
      expect(reloaded.annotationsFor('doc_1').map((a) => a.id), ['a1', 'a2']);
    });

    test('annotationsOnPage filters by page', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(annotation('a1', 'doc_1', page: 2));
      await subject.addAnnotation(annotation('a2', 'doc_1', page: 5));
      expect(subject.annotationsOnPage('doc_1', 2).single.id, 'a1');
      expect(subject.annotationsOnPage('doc_1', 9), isEmpty);
    });

    test('changeColor updates and persists', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(annotation('a1', 'doc_1'));
      final updated = await subject.changeColor(
        documentId: 'doc_1',
        annotationId: 'a1',
        color: ReaderAnnotationColor.purple,
        at: DateTime.utc(2026, 8, 12),
      );
      expect(updated!.color, ReaderAnnotationColor.purple);
      final reloaded = service();
      await reloaded.preload('doc_1');
      expect(reloaded.annotationsFor('doc_1').single.color,
          ReaderAnnotationColor.purple);
    });

    test('remove deletes and undo restores', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(annotation('a1', 'doc_1'));
      final removed = await subject.removeAnnotation(
          documentId: 'doc_1', annotationId: 'a1');
      expect(removed, isNotNull);
      expect(subject.annotationsFor('doc_1'), isEmpty);
      // Persisted state is empty after removal.
      expect(await StorageAnnotationRepository(storage).load('doc_1'), isEmpty);

      expect(await subject.undo(), isTrue);
      expect(subject.annotationsFor('doc_1').single.id, 'a1');
      expect((await StorageAnnotationRepository(storage).load('doc_1')),
          hasLength(1));

      expect(await subject.redo(), isTrue);
      expect(subject.annotationsFor('doc_1'), isEmpty);
    });

    test('undo/redo of color changes', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(annotation('a1', 'doc_1'));
      await subject.changeColor(
        documentId: 'doc_1',
        annotationId: 'a1',
        color: ReaderAnnotationColor.green,
        at: DateTime.utc(2026, 8, 12),
      );
      expect(await subject.undo(), isTrue);
      expect(subject.annotationsFor('doc_1').single.color,
          ReaderAnnotationColor.yellow);
      expect(await subject.redo(), isTrue);
      expect(subject.annotationsFor('doc_1').single.color,
          ReaderAnnotationColor.green);
    });

    test('undo returns false when nothing is pending', () async {
      final subject = service();
      await subject.preload('doc_1');
      expect(await subject.undo(), isFalse);
      expect(await subject.redo(), isFalse);
    });

    test('clearDocument wipes storage without touching other documents',
        () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addAnnotation(annotation('a1', 'doc_1'));
      await subject.addAnnotation(annotation('b1', 'doc_2'));
      await subject.clearDocument('doc_1');
      expect(await StorageAnnotationRepository(storage).load('doc_1'), isEmpty);
      expect((await StorageAnnotationRepository(storage).load('doc_2')),
          hasLength(1));
    });
  });

  group('BookmarkService', () {
    BookmarkService service() => BookmarkService(
          repository: StorageBookmarkRepository(storage),
          idGenerator: (prefix) => 'fixed_$prefix',
        );

    ReaderBookmark bookmark(String id, {int page = 1, String? title}) =>
        ReaderBookmark(
          id: id,
          documentId: 'doc_1',
          pageNumber: page,
          title: title ?? 'Bookmark $id',
          createdAt: DateTime.utc(2026, 8, 10),
          updatedAt: DateTime.utc(2026, 8, 10),
        );

    test('add/remove/update persist through storage', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addBookmark(bookmark('bm1', page: 3));
      expect(subject.bookmarkForPage('doc_1', 3)!.id, 'bm1');

      final renamed = await subject.updateBookmark(
        documentId: 'doc_1',
        bookmarkId: 'bm1',
        at: DateTime.utc(2026, 8, 11),
        title: 'Important chapter',
      );
      expect(renamed!.title, 'Important chapter');

      await subject.removeBookmark(documentId: 'doc_1', bookmarkId: 'bm1');
      expect(subject.bookmarksFor('doc_1'), isEmpty);

      final reloaded = service();
      await reloaded.preload('doc_1');
      expect(reloaded.bookmarksFor('doc_1'), isEmpty);
    });

    test('undo restores removed bookmarks at the original position', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addBookmark(bookmark('bm1', page: 1));
      await subject.addBookmark(bookmark('bm2', page: 2));
      await subject.addBookmark(bookmark('bm3', page: 3));
      await subject.removeBookmark(documentId: 'doc_1', bookmarkId: 'bm2');
      expect(await subject.undo(), isTrue);
      expect(subject.bookmarksFor('doc_1').map((b) => b.id),
          ['bm1', 'bm2', 'bm3']);
    });

    test('unknown ids return null without mutating', () async {
      final subject = service();
      await subject.preload('doc_1');
      expect(
        await subject.updateBookmark(
            documentId: 'doc_1', bookmarkId: 'ghost', at: DateTime.utc(2026)),
        isNull,
      );
      expect(
        await subject.removeBookmark(documentId: 'doc_1', bookmarkId: 'ghost'),
        isNull,
      );
    });
  });

  group('NoteService', () {
    NoteService service() => NoteService(
          repository: StorageNoteRepository(storage),
          idGenerator: (prefix) => 'fixed_$prefix',
        );

    ReaderNote note(String id, {String? selectedText, int page = 1}) =>
        ReaderNote(
          id: id,
          documentId: 'doc_1',
          pageNumber: page,
          title: 'Title $id',
          content: 'Content $id',
          selectedText: selectedText,
          createdAt: DateTime.utc(2026, 8, 10),
          updatedAt: DateTime.utc(2026, 8, 10),
        );

    test('add/update/remove persist through storage', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addNote(note('n1', selectedText: 'quoted'));
      final updated = await subject.updateNote(
        documentId: 'doc_1',
        noteId: 'n1',
        at: DateTime.utc(2026, 8, 11),
        content: 'Revised body',
      );
      expect(updated!.content, 'Revised body');
      expect(updated.selectedText, 'quoted'); // loose refs survive edits
      await subject.removeNote(documentId: 'doc_1', noteId: 'n1');
      final reloaded = service();
      await reloaded.preload('doc_1');
      expect(reloaded.notesFor('doc_1'), isEmpty);
    });

    test('searchNotes matches title, content and selectedText', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addNote(note('n1'));
      await subject.addNote(note('n2', selectedText: 'article 21'));
      expect(subject.searchNotes('doc_1', 'title n1').single.id, 'n1');
      expect(subject.searchNotes('doc_1', 'ARTICLE 21').single.id, 'n2');
      expect(subject.searchNotes('doc_1', ''), hasLength(2));
      expect(subject.searchNotes('doc_1', 'no match'), isEmpty);
    });

    test('undo/redo cover add, edit and delete', () async {
      final subject = service();
      await subject.preload('doc_1');
      await subject.addNote(note('n1'));
      await subject.updateNote(
        documentId: 'doc_1',
        noteId: 'n1',
        at: DateTime.utc(2026, 8, 11),
        title: 'Edited',
      );
      await subject.removeNote(documentId: 'doc_1', noteId: 'n1');

      expect(await subject.undo(), isTrue); // restore delete
      expect(subject.notesFor('doc_1').single.title, 'Edited');
      expect(await subject.undo(), isTrue); // revert edit
      expect(subject.notesFor('doc_1').single.title, 'Title n1');
      expect(await subject.undo(), isTrue); // revert add
      expect(subject.notesFor('doc_1'), isEmpty);
      expect(await subject.undo(), isFalse);

      expect(await subject.redo(), isTrue); // re-add
      expect(subject.notesFor('doc_1').single.title, 'Title n1');
      expect(await subject.redo(), isTrue); // re-apply edit
      expect(subject.notesFor('doc_1').single.title, 'Edited');
      expect(await subject.redo(), isTrue); // re-apply delete
      expect(subject.notesFor('doc_1'), isEmpty);
      expect(await subject.redo(), isFalse);
    });
  });
}
