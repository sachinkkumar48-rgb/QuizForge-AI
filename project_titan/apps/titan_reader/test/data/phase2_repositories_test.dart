import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/annotation_repository.dart';
import 'package:titan_reader/src/data/bookmark_repository.dart';
import 'package:titan_reader/src/data/note_repository.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/reader_annotation.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/domain/entities/reader_note.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  late InMemoryStorageService storage;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
  });

  ReaderAnnotation annotation(String id, String documentId, int page) {
    final now = DateTime.utc(2026, 8, 10);
    return ReaderAnnotation(
      id: id,
      documentId: documentId,
      pageNumber: page,
      type: ReaderAnnotationType.underline,
      color: ReaderAnnotationColor.green,
      selectedText: 'text for $id',
      rects: const [
        NormalizedPageRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.15),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  ReaderBookmark bookmark(String id, String documentId, int page) =>
      ReaderBookmark(
        id: id,
        documentId: documentId,
        pageNumber: page,
        title: 'Bookmark $id',
        createdAt: DateTime.utc(2026, 8, 11),
        updatedAt: DateTime.utc(2026, 8, 11),
      );

  ReaderNote note(String id, String documentId, int page) => ReaderNote(
        id: id,
        documentId: documentId,
        pageNumber: page,
        title: 'Note $id',
        content: 'Body $id',
        createdAt: DateTime.utc(2026, 8, 12),
        updatedAt: DateTime.utc(2026, 8, 12),
      );

  group('StorageAnnotationRepository', () {
    test('uses the Reader annotations namespace', () {
      expect(StorageAnnotationRepository.namespace, 'titan.reader.annotations');
    });

    test('empty store loads empty list', () async {
      final repo = StorageAnnotationRepository(storage);
      expect(await repo.load('doc_1'), isEmpty);
    });

    test('saveAll/load round-trips per document', () async {
      final repo = StorageAnnotationRepository(storage);
      await repo.saveAll('doc_1', [
        annotation('a1', 'doc_1', 2),
        annotation('a2', 'doc_1', 5),
      ]);
      final loaded = await repo.load('doc_1');
      expect(loaded.map((a) => a.id), ['a1', 'a2']);
      expect(loaded.first, annotation('a1', 'doc_1', 2));
    });

    test('documents are isolated from each other', () async {
      final repo = StorageAnnotationRepository(storage);
      await repo.saveAll('doc_1', [annotation('a1', 'doc_1', 1)]);
      await repo.saveAll('doc_2', [annotation('b1', 'doc_2', 9)]);
      expect((await repo.load('doc_1')).single.documentId, 'doc_1');
      expect((await repo.load('doc_2')).single.documentId, 'doc_2');
      await repo.deleteDocument('doc_1');
      expect(await repo.load('doc_1'), isEmpty);
      expect((await repo.load('doc_2')), hasLength(1));
    });

    test('malformed JSON throws FormatException', () async {
      const key = StorageKey('doc_bad',
          namespace: StorageAnnotationRepository.namespace);
      await storage.write<String>(key, '{"not":"a list"}');
      final repo = StorageAnnotationRepository(storage);
      expect(() => repo.load('doc_bad'), throwsFormatException);
    });
  });

  group('StorageBookmarkRepository', () {
    test('uses the Reader bookmarks namespace', () {
      expect(StorageBookmarkRepository.namespace, 'titan.reader.bookmarks');
    });

    test('saveAll/load round-trips per document', () async {
      final repo = StorageBookmarkRepository(storage);
      await repo.saveAll('doc_1', [bookmark('bm1', 'doc_1', 3)]);
      expect(await repo.load('doc_1'), [bookmark('bm1', 'doc_1', 3)]);
      expect(await repo.load('doc_other'), isEmpty);
    });

    test('deleteDocument removes only that document', () async {
      final repo = StorageBookmarkRepository(storage);
      await repo.saveAll('doc_1', [bookmark('bm1', 'doc_1', 3)]);
      await repo.saveAll('doc_2', [bookmark('bm2', 'doc_2', 4)]);
      await repo.deleteDocument('doc_1');
      expect(await repo.load('doc_1'), isEmpty);
      expect(await repo.load('doc_2'), hasLength(1));
      await repo.deleteDocument('ghost'); // must not throw
    });
  });

  group('StorageNoteRepository', () {
    test('uses the Reader notes namespace', () {
      expect(StorageNoteRepository.namespace, 'titan.reader.notes');
    });

    test('saveAll/load round-trips per document', () async {
      final repo = StorageNoteRepository(storage);
      await repo.saveAll('doc_1', [note('n1', 'doc_1', 7)]);
      expect(await repo.load('doc_1'), [note('n1', 'doc_1', 7)]);
    });

    test('namespaces never collide across entity types', () async {
      final annotations = StorageAnnotationRepository(storage);
      final bookmarks = StorageBookmarkRepository(storage);
      final notes = StorageNoteRepository(storage);
      await annotations.saveAll('doc_1', [annotation('a1', 'doc_1', 1)]);
      await bookmarks.saveAll('doc_1', [bookmark('bm1', 'doc_1', 1)]);
      await notes.saveAll('doc_1', [note('n1', 'doc_1', 1)]);
      expect((await annotations.load('doc_1')).single.id, 'a1');
      expect((await bookmarks.load('doc_1')).single.id, 'bm1');
      expect((await notes.load('doc_1')).single.id, 'n1');
      // Deleting one entity type never touches the others.
      await annotations.deleteDocument('doc_1');
      expect(await annotations.load('doc_1'), isEmpty);
      expect((await bookmarks.load('doc_1')), hasLength(1));
      expect((await notes.load('doc_1')), hasLength(1));
    });
  });
}
