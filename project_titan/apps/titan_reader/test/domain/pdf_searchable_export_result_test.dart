import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_searchable_export_result.dart';

void main() {
  group('PdfSearchableExportResult Domain Entity Tests', () {
    test('instantiates success result with valid properties', () {
      final result = PdfSearchableExportResult.success(
        outputPath: '/path/to/exported_searchable.pdf',
        exportedPagesCount: 5,
        totalPagesCount: 5,
        fileSizeBytes: 102400,
        elapsed: const Duration(milliseconds: 350),
      );

      expect(result.status, PdfSearchableExportStatus.success);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.outputPath, '/path/to/exported_searchable.pdf');
      expect(result.exportedPagesCount, 5);
      expect(result.totalPagesCount, 5);
      expect(result.fileSizeBytes, 102400);
      expect(result.elapsed.inMilliseconds, 350);
      expect(result.errorMessage, isNull);
    });

    test('instantiates noOcrData result with defaults', () {
      final result = PdfSearchableExportResult.noOcrData(totalPagesCount: 3);

      expect(result.status, PdfSearchableExportStatus.noOcrData);
      expect(result.isSuccess, isFalse);
      expect(result.totalPagesCount, 3);
      expect(result.exportedPagesCount, 0);
      expect(result.errorMessage, contains('No OCR text layer'));
    });

    test('instantiates encrypted result correctly', () {
      final result = PdfSearchableExportResult.encrypted(totalPagesCount: 10);

      expect(result.status, PdfSearchableExportStatus.encrypted);
      expect(result.isSuccess, isFalse);
      expect(result.totalPagesCount, 10);
      expect(result.errorMessage, contains('encrypted'));
    });

    test('instantiates invalidDocument result with custom message', () {
      final result = PdfSearchableExportResult.invalidDocument(
        message: 'File not found at target location.',
      );

      expect(result.status, PdfSearchableExportStatus.invalidDocument);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'File not found at target location.');
    });

    test('instantiates cancelled result accurately', () {
      final result = PdfSearchableExportResult.cancelled(
        elapsed: const Duration(milliseconds: 120),
      );

      expect(result.status, PdfSearchableExportStatus.cancelled);
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.elapsed.inMilliseconds, 120);
    });

    test('instantiates failed result with error detail', () {
      final result = PdfSearchableExportResult.failed(
        errorMessage: 'Disk full error.',
        elapsed: const Duration(milliseconds: 80),
      );

      expect(result.status, PdfSearchableExportStatus.failed);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Disk full error.');
      expect(result.elapsed.inMilliseconds, 80);
    });

    test('serializes to and from JSON cleanly', () {
      final original = PdfSearchableExportResult.success(
        outputPath: '/path/out.pdf',
        exportedPagesCount: 2,
        totalPagesCount: 2,
        fileSizeBytes: 4096,
        elapsed: const Duration(milliseconds: 150),
      );

      final json = original.toJson();
      final roundTrip = PdfSearchableExportResult.fromJson(json);

      expect(roundTrip, original);
      expect(roundTrip.status, PdfSearchableExportStatus.success);
      expect(roundTrip.outputPath, '/path/out.pdf');
      expect(roundTrip.exportedPagesCount, 2);
      expect(roundTrip.totalPagesCount, 2);
      expect(roundTrip.fileSizeBytes, 4096);
      expect(roundTrip.elapsed.inMilliseconds, 150);
    });

    test('handles value equality and hash codes', () {
      final a = PdfSearchableExportResult.success(
        outputPath: '/a.pdf',
        exportedPagesCount: 1,
        totalPagesCount: 1,
        fileSizeBytes: 100,
        elapsed: const Duration(milliseconds: 50),
      );

      final b = PdfSearchableExportResult.success(
        outputPath: '/a.pdf',
        exportedPagesCount: 1,
        totalPagesCount: 1,
        fileSizeBytes: 100,
        elapsed: const Duration(milliseconds: 50),
      );

      final c = PdfSearchableExportResult.failed(
        errorMessage: 'Different',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
