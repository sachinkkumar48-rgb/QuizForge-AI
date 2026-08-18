import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/document_privacy_state.dart';
import 'package:titan_reader/src/domain/entities/reading_position.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_storage/titan_storage.dart';

/// Valid 5-byte PDF magic header used for positive import cases.
const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];

void main() {
  late InMemoryStorageService storage;
  late LibraryService service;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    service = LibraryService(
      library: StorageDocumentLibraryRepository(storage),
      positions: StorageReadingPositionRepository(storage),
      history: ReadingHistoryService(storage),
    );
  });

  final at = DateTime.utc(2026, 8, 10, 12);

  group('importFile', () {
    test('imports a valid PDF as LOCAL_ONLY with a derived title', () async {
      final document = await service.importFile(
        filePath: '/docs/report.pdf',
        fileName: 'Report.pdf',
        sizeBytes: 4096,
        at: at,
        headerBytes: pdfHeader,
      );
      expect(document.title, 'Report');
      expect(document.filePath, '/docs/report.pdf');
      expect(document.privacyState, DocumentPrivacyState.localOnly);
      expect(await service.getDocuments(), hasLength(1));
    });

    test('re-importing the same path refreshes instead of duplicating',
        () async {
      await service.importFile(
        filePath: '/docs/report.pdf',
        fileName: 'Report.pdf',
        sizeBytes: 4096,
        at: at,
      );
      await service.importFile(
        filePath: '/docs/report.pdf',
        fileName: 'Report.pdf',
        sizeBytes: 4096,
        at: at.add(const Duration(days: 1)),
      );
      expect(await service.getDocuments(), hasLength(1));
    });

    test('rejects non-PDF extensions via titan_pdf validation', () async {
      expect(
        () => service.importFile(
          filePath: '/docs/report.txt',
          fileName: 'report.txt',
          sizeBytes: 4096,
          at: at,
        ),
        throwsA(isA<PdfValidationException>()),
      );
    });

    test('rejects oversized files via titan_pdf validation', () async {
      expect(
        () => service.importFile(
          filePath: '/docs/huge.pdf',
          fileName: 'huge.pdf',
          sizeBytes: PdfValidationService.maxSizeBytes + 1,
          at: at,
        ),
        throwsA(isA<PdfValidationException>()),
      );
    });

    test('rejects files without the PDF magic header', () async {
      expect(
        () => service.importFile(
          filePath: '/docs/fake.pdf',
          fileName: 'fake.pdf',
          sizeBytes: 4096,
          at: at,
          headerBytes: const [0x00, 0x01, 0x02, 0x03],
        ),
        throwsA(isA<PdfValidationException>()),
      );
    });
  });

  group('markOpened', () {
    test('updates lastOpenedAt and records a history visit', () async {
      final document = await service.importFile(
        filePath: '/docs/report.pdf',
        fileName: 'Report.pdf',
        sizeBytes: 4096,
        at: at,
      );
      final opened = await service.markOpened(
        documentId: document.id,
        at: at.add(const Duration(hours: 1)),
      );
      expect(opened, isNotNull);
      expect(opened!.lastOpenedAt, at.add(const Duration(hours: 1)));
      expect(await service.getRecentDocumentIds(), [document.id]);
    });

    test('returns null for unknown documents', () async {
      expect(
        await service.markOpened(documentId: 'ghost', at: at),
        isNull,
      );
    });
  });

  test('updatePageCount persists the engine-reported page count', () async {
    final document = await service.importFile(
      filePath: '/docs/report.pdf',
      fileName: 'Report.pdf',
      sizeBytes: 4096,
      at: at,
    );
    await service.updatePageCount(documentId: document.id, pageCount: 25);
    final docs = await service.getDocuments();
    expect(docs.single.pageCount, 25);
    // Invalid page counts are ignored.
    await service.updatePageCount(documentId: document.id, pageCount: 0);
    expect((await service.getDocuments()).single.pageCount, 25);
  });

  test('toggleFavorite flips the favorite flag', () async {
    final document = await service.importFile(
      filePath: '/docs/report.pdf',
      fileName: 'Report.pdf',
      sizeBytes: 4096,
      at: at,
    );
    final favorited = await service.toggleFavorite(document.id);
    expect(favorited!.isFavorite, isTrue);
    final unfavorited = await service.toggleFavorite(document.id);
    expect(unfavorited!.isFavorite, isFalse);
  });

  test('removeDocument clears the entry, its position and its history',
      () async {
    final document = await service.importFile(
      filePath: '/docs/report.pdf',
      fileName: 'Report.pdf',
      sizeBytes: 4096,
      at: at,
    );
    await service.markOpened(documentId: document.id, at: at);
    await service.savePosition(ReadingPosition(
      documentId: document.id,
      pageNumber: 4,
      updatedAt: at,
    ));

    await service.removeDocument(document.id);

    expect(await service.getDocuments(), isEmpty);
    expect(await service.loadPosition(document.id), isNull);
    expect(await service.getRecentDocumentIds(), isEmpty);
  });

  test('position save/load round-trips through the service', () async {
    final position = ReadingPosition(
      documentId: 'doc_1',
      pageNumber: 12,
      totalPages: 40,
      updatedAt: at,
    );
    await service.savePosition(position);
    expect(await service.loadPosition('doc_1'), position);
  });
}
