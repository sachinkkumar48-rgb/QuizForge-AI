import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/reader_document.dart';
import 'package:titan_reader/src/domain/entities/reading_position.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  late InMemoryStorageService storage;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
  });

  ReaderDocument doc(
    String id, {
    DateTime? opened,
    DateTime? added,
    bool favorite = false,
  }) {
    return ReaderDocument(
      id: id,
      title: 'Doc $id',
      filePath: '/tmp/$id.pdf',
      sizeBytes: 512,
      addedAt: added ?? DateTime.utc(2026, 8, 1),
      lastOpenedAt: opened,
      isFavorite: favorite,
    );
  }

  group('StorageDocumentLibraryRepository', () {
    test('starts empty', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      expect(await repo.getAll(), isEmpty);
      expect(await repo.getById('missing'), isNull);
    });

    test('save inserts new documents and replaces same-id entries', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      await repo.save(doc('a'));
      await repo.save(doc('a', favorite: true));
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.isFavorite, isTrue);
    });

    test('getByFilePath finds the matching document', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      await repo.save(doc('a'));
      expect((await repo.getByFilePath('/tmp/a.pdf'))!.id, 'a');
      expect(await repo.getByFilePath('/tmp/other.pdf'), isNull);
    });

    test('display order: opened docs first, newest visit first', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      await repo.save(doc('never-opened'));
      await repo.save(doc('old', opened: DateTime.utc(2026, 8, 2)));
      await repo.save(doc('recent', opened: DateTime.utc(2026, 8, 5)));
      final all = await repo.getAll();
      expect(all.map((d) => d.id).toList(), ['recent', 'old', 'never-opened']);
    });

    test('never-opened documents sort by newest addition', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      await repo.save(doc('older', added: DateTime.utc(2026, 7, 1)));
      await repo.save(doc('newer', added: DateTime.utc(2026, 8, 1)));
      final all = await repo.getAll();
      expect(all.map((d) => d.id).toList(), ['newer', 'older']);
    });

    test('remove deletes the entry; removing absent ids is a no-op', () async {
      final repo = StorageDocumentLibraryRepository(storage);
      await repo.save(doc('a'));
      await repo.remove('a');
      expect(await repo.getAll(), isEmpty);
      await repo.remove('ghost'); // must not throw
    });

    test('malformed entries are skipped instead of corrupting the library',
        () async {
      const key = StorageKey(
        StorageDocumentLibraryRepository.collectionKey,
        namespace: StorageDocumentLibraryRepository.namespace,
      );
      await storage.write<String>(
        key,
        '[{"id":"broken"},{"id":"a","title":"A","filePath":"/a.pdf",'
        '"sizeBytes":10,"addedAt":"2026-08-01T00:00:00.000Z"}]',
      );
      final repo = StorageDocumentLibraryRepository(storage);
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'a');
    });
  });

  group('StorageReadingPositionRepository', () {
    test('load returns null when no position is stored', () async {
      final repo = StorageReadingPositionRepository(storage);
      expect(await repo.load('doc_1'), isNull);
    });

    test('save/load round-trips per document', () async {
      final repo = StorageReadingPositionRepository(storage);
      final position = ReadingPosition(
        documentId: 'doc_1',
        pageNumber: 7,
        totalPages: 30,
        updatedAt: DateTime.utc(2026, 8, 9),
      );
      await repo.save(position);
      expect(await repo.load('doc_1'), position);
    });

    test('save overwrites the previous position for the same document',
        () async {
      final repo = StorageReadingPositionRepository(storage);
      await repo.save(ReadingPosition(
        documentId: 'doc_1',
        pageNumber: 3,
        updatedAt: DateTime.utc(2026, 8, 1),
      ));
      await repo.save(ReadingPosition(
        documentId: 'doc_1',
        pageNumber: 9,
        updatedAt: DateTime.utc(2026, 8, 2),
      ));
      expect((await repo.load('doc_1'))!.pageNumber, 9);
    });

    test('delete removes the position; deleting absent ids is a no-op',
        () async {
      final repo = StorageReadingPositionRepository(storage);
      await repo.save(ReadingPosition(
        documentId: 'doc_1',
        pageNumber: 3,
        updatedAt: DateTime.utc(2026, 8, 1),
      ));
      await repo.delete('doc_1');
      expect(await repo.load('doc_1'), isNull);
      await repo.delete('ghost'); // must not throw
    });
  });
}
