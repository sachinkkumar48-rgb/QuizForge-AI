import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/document_privacy_state.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/reader_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

/// Minimal valid PDF 1.4 byte sequence (header, catalog, pages, page, content, xref, trailer).
final Uint8List validMinimalPdfBytes = Uint8List.fromList([
  0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, // %PDF-1.4\n
  0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, // 1 0 obj\n
  0x3C, 0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x43, 0x61, 0x74, 0x61,
  0x6C, 0x6F, 0x67, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20,
  0x30, 0x20, 0x52, 0x3E, 0x3E, 0x0A, // <</Type/Catalog/Pages 2 0 R>>\n
  0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, // endobj\n
  0x32, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, // 2 0 obj\n
  0x3C, 0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65,
  0x73, 0x2F, 0x4B, 0x69, 0x64, 0x73, 0x5B, 0x33, 0x20, 0x30, 0x20, 0x52,
  0x5D, 0x2F, 0x43, 0x6F, 0x75, 0x6E, 0x74, 0x20, 0x31, 0x3E, 0x3E,
  0x0A, // <</Type/Pages/Kids[3 0 R]/Count 1>>\n
  0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, // endobj\n
  0x33, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, // 3 0 obj\n
  0x3C, 0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65,
  0x2F, 0x50, 0x61, 0x72, 0x65, 0x6E, 0x74, 0x20, 0x32, 0x20, 0x30, 0x20,
  0x52, 0x2F, 0x4D, 0x65, 0x64, 0x69, 0x61, 0x42, 0x6F, 0x78, 0x5B, 0x30,
  0x20, 0x30, 0x20, 0x33, 0x30, 0x30, 0x20, 0x33, 0x30, 0x30, 0x5D, 0x3E,
  0x3E, 0x0A, // <</Type/Page/Parent 2 0 R/MediaBox[0 0 300 300]>>\n
  0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, // endobj\n
  0x78, 0x72, 0x65, 0x66, 0x0A, 0x30, 0x20, 0x34, 0x0A, // xref\n0 4\n
  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x36,
  0x35, 0x35, 0x33, 0x35, 0x20, 0x66, 0x20, 0x0A,
  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x30, 0x20, 0x30,
  0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x20, 0x0A,
  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x35, 0x33, 0x20, 0x30,
  0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x20, 0x0A,
  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x30, 0x32, 0x20, 0x30,
  0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x20, 0x0A,
  0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A, // trailer\n
  0x3C, 0x3C, 0x2F, 0x53, 0x69, 0x7A, 0x65, 0x20, 0x34, 0x2F, 0x52, 0x6F,
  0x6F, 0x74, 0x20, 0x31, 0x20, 0x30, 0x20, 0x52, 0x3E, 0x3E,
  0x0A, // <</Size 4/Root 1 0 R>>\n
  0x73, 0x74, 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0A, // startxref\n
  0x31, 0x34, 0x39, 0x0A, // 149\n
  0x25, 0x25, 0x45, 0x4F, 0x46, 0x0A, // %%EOF\n
]);

void main() {
  late Directory tempSandboxDir;
  late InMemoryStorageService storage;
  late FakePdfEngine engine;
  late LibraryService service;

  setUp(() async {
    tempSandboxDir =
        await Directory.systemTemp.createTemp('titan_reader_test_');
    storage = InMemoryStorageService();
    await storage.initialize();
    engine = FakePdfEngine();

    service = LibraryService(
      library: StorageDocumentLibraryRepository(storage),
      positions: StorageReadingPositionRepository(storage),
      history: ReadingHistoryService(storage),
      getDocumentsDirectory: () async => tempSandboxDir,
    );
  });

  tearDown(() async {
    if (tempSandboxDir.existsSync()) {
      await tempSandboxDir.delete(recursive: true);
    }
  });

  Widget buildSubject(String documentId) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(engine),
        libraryServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          fileExists: (path) => true,
        ),
      ),
    );
  }

  group('Phase 7J — Android PDF Open/Render Pipeline Diagnostics & Regression',
      () {
    test(
        '1. Normal filesystem PDF is copied to application-private storage with valid metadata',
        () async {
      final sourceFile = File('${tempSandboxDir.path}/external_download.pdf');
      await sourceFile.writeAsBytes(validMinimalPdfBytes, flush: true);

      final document = await service.importPickedFile(
        sourceFilePath: sourceFile.path,
        fileName: 'external_download.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      expect(document.title, 'external_download');
      expect(document.privacyState, DocumentPrivacyState.localOnly);
      // Stored path must be inside application-private documents directory
      expect(document.filePath, contains('/documents/'));
      expect(File(document.filePath).existsSync(), isTrue);

      final documents = await service.getDocuments();
      expect(documents, hasLength(1));
      expect(documents.first.id, document.id);
      expect(documents.first.filePath, document.filePath);
    });

    test(
        '2. Temporary Android picker cache file survives cache purge and Reader opens private copy',
        () async {
      // Create simulated transient file_picker cache directory
      final cacheDir =
          Directory('${tempSandboxDir.path}/cache/file_picker/1724500000');
      await cacheDir.create(recursive: true);
      final pickerCacheFile = File('${cacheDir.path}/picked_report.pdf');
      await pickerCacheFile.writeAsBytes(validMinimalPdfBytes, flush: true);

      // Import via importPickedFile
      final document = await service.importPickedFile(
        sourceFilePath: pickerCacheFile.path,
        fileName: 'picked_report.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      // Simulate Android OS / file_picker clearing the cache directory
      await cacheDir.delete(recursive: true);
      expect(pickerCacheFile.existsSync(), isFalse);

      // The canonical private copy MUST remain intact and readable
      final privateFile = File(document.filePath);
      expect(privateFile.existsSync(), isTrue);
      expect(await privateFile.readAsBytes(), validMinimalPdfBytes);
    });

    test(
        '3. In-memory byte PDF (cloud picker / SAF stream) writes to private storage and registers',
        () async {
      final document = await service.importPickedFile(
        sourceFilePath: null,
        fileBytes: validMinimalPdfBytes,
        fileName: 'cloud_streamed.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      expect(document.title, 'cloud_streamed');
      expect(File(document.filePath).existsSync(), isTrue);
      expect(await File(document.filePath).readAsBytes(), validMinimalPdfBytes);
    });

    test(
        '4. Zero-byte PDF is rejected and does not leave orphaned files in private storage',
        () async {
      final zeroByteFile = File('${tempSandboxDir.path}/empty.pdf');
      await zeroByteFile.writeAsBytes([], flush: true);

      expect(
        () => service.importPickedFile(
          sourceFilePath: zeroByteFile.path,
          fileName: 'empty.pdf',
          sizeBytes: 0,
          at: DateTime.utc(2026, 8, 24),
          headerBytes: [],
        ),
        throwsA(isA<PdfValidationException>()),
      );

      final documents = await service.getDocuments();
      expect(documents, isEmpty);
    });

    test('5. Non-PDF extension / missing header is rejected by validation',
        () async {
      final invalidFile = File('${tempSandboxDir.path}/corrupt.txt');
      await invalidFile.writeAsString('not a pdf', flush: true);

      expect(
        () => service.importPickedFile(
          sourceFilePath: invalidFile.path,
          fileName: 'corrupt.txt',
          sizeBytes: 9,
          at: DateTime.utc(2026, 8, 24),
        ),
        throwsA(isA<PdfValidationException>()),
      );
    });

    test(
        '6. Re-importing existing document updates private storage and refreshes library',
        () async {
      final sourceFile = File('${tempSandboxDir.path}/lecture.pdf');
      await sourceFile.writeAsBytes(validMinimalPdfBytes, flush: true);

      final firstImport = await service.importPickedFile(
        sourceFilePath: sourceFile.path,
        fileName: 'lecture.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24, 10),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      // Re-import with newer timestamp
      final secondImport = await service.importPickedFile(
        sourceFilePath: sourceFile.path,
        fileName: 'lecture.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24, 11),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      expect(secondImport.id, firstImport.id);
      expect(secondImport.filePath, firstImport.filePath);
      final documents = await service.getDocuments();
      expect(documents, hasLength(1));
    });

    testWidgets(
        '7. ReaderScreen receives stable readable canonical document reference and builds viewer',
        (tester) async {
      final canonicalPath = '${tempSandboxDir.path}/documents/sample_doc.pdf';
      final document = await service.importFile(
        filePath: canonicalPath,
        fileName: 'sample_doc.pdf',
        sizeBytes: validMinimalPdfBytes.length,
        at: DateTime.utc(2026, 8, 24),
        headerBytes: validMinimalPdfBytes.sublist(0, 5),
      );

      await tester.pumpWidget(buildSubject(document.id));
      await tester.pump();

      expect(find.text('sample_doc'), findsOneWidget);
      final handle = engine.lastHandle;
      expect(handle, isNotNull);
      expect(handle!.lastFilePath, canonicalPath);
      expect(find.byKey(const Key('fake-pdf-viewer')), findsOneWidget);
    });
  });
}
