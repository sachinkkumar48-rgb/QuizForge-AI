import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_print_result.dart';
import 'package:titan_reader/src/services/print_service.dart';

class FakePdfPrintAdapter implements PdfPrintAdapter {
  PdfPrintResult resultToReturn;
  String? lastFilePath;
  String? lastDocumentName;
  int callCount = 0;

  FakePdfPrintAdapter({
    this.resultToReturn =
        const PdfPrintResult.completed(printerName: 'Test Printer'),
  });

  @override
  Future<PdfPrintResult> printPdf({
    required String filePath,
    String? documentName,
  }) async {
    callCount++;
    lastFilePath = filePath;
    lastDocumentName = documentName;
    return resultToReturn;
  }
}

void main() {
  late Directory tempDir;
  late File samplePdf;
  late FakePdfPrintAdapter fakeAdapter;
  late PrintService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_print_test_');
    samplePdf = File('${tempDir.path}/sample.pdf');
    await samplePdf.writeAsBytes(
        [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]); // %PDF-1.7
    fakeAdapter = FakePdfPrintAdapter();
    service = PrintService(fakeAdapter);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PrintService Unit Tests', () {
    test('successfully validates file and delegates print request to adapter',
        () async {
      final result = await service.printDocument(
        filePath: samplePdf.path,
        documentTitle: 'Annual Report',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeAdapter.callCount, 1);
      expect(fakeAdapter.lastFilePath, samplePdf.path);
      expect(fakeAdapter.lastDocumentName, 'Annual Report');
    });

    test('rejects empty file path without invoking adapter', () async {
      final result = await service.printDocument(filePath: '   ');

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('cannot be empty'));
      expect(fakeAdapter.callCount, 0);
    });

    test('rejects non-existent file path without invoking adapter', () async {
      final missingPath = '${tempDir.path}/missing_document.pdf';
      final result = await service.printDocument(filePath: missingPath);

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Document file not found'));
      expect(fakeAdapter.callCount, 0);
    });

    test('propagates user cancellation result from adapter', () async {
      fakeAdapter.resultToReturn = const PdfPrintResult.cancelled();

      final result = await service.printDocument(
        filePath: samplePdf.path,
        documentTitle: 'Cancelled Doc',
      );

      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
    });

    test('propagates platform failure from adapter', () async {
      fakeAdapter.resultToReturn =
          const PdfPrintResult.failed('Spooler offline');

      final result = await service.printDocument(
        filePath: samplePdf.path,
        documentTitle: 'Failed Doc',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'Spooler offline');
    });
  });

  group('PlatformPdfPrintAdapter Unit Tests', () {
    test('returns failure immediately if target file does not exist', () async {
      const adapter = PlatformPdfPrintAdapter();
      final result =
          await adapter.printPdf(filePath: '${tempDir.path}/ghost.pdf');

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('PDF file does not exist'));
    });
  });
}
