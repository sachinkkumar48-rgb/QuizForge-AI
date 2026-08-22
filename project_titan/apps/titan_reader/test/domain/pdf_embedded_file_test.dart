import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_embedded_file.dart';

void main() {
  group('PdfEmbeddedFile Domain Entity Tests', () {
    test('computes formattedSize correctly for various byte scales', () {
      const fileBytes = PdfEmbeddedFile(
        id: '1',
        filename: 'data.bin',
        actualSize: 512,
        streamObjectNumber: 10,
      );
      expect(fileBytes.formattedSize, '512 B');

      const fileKb = PdfEmbeddedFile(
        id: '2',
        filename: 'doc.pdf',
        actualSize: 1024 * 15 + 512,
        streamObjectNumber: 11,
      );
      expect(fileKb.formattedSize, '15.5 KB');

      const fileMb = PdfEmbeddedFile(
        id: '3',
        filename: 'archive.zip',
        actualSize: 3932160,
        streamObjectNumber: 12,
      );
      expect(fileMb.formattedSize, '3.75 MB');

      const fileUnknown = PdfEmbeddedFile(
        id: '4',
        filename: 'unknown.dat',
        streamObjectNumber: 13,
      );
      expect(fileUnknown.formattedSize, 'Unknown size');
    });

    test('extracts fileExtension reliably', () {
      const f1 = PdfEmbeddedFile(
        id: '1',
        filename: 'report.final.PDF',
        streamObjectNumber: 1,
      );
      expect(f1.fileExtension, 'pdf');

      const f2 = PdfEmbeddedFile(
        id: '2',
        filename: 'README',
        streamObjectNumber: 2,
      );
      expect(f2.fileExtension, '');
    });

    test('supports value equality and copy/props', () {
      const f1 = PdfEmbeddedFile(
        id: 'emb_1',
        filename: 'file.txt',
        mimeType: 'text/plain',
        declaredSize: 100,
        streamObjectNumber: 5,
        sourceLocation: PdfAttachmentSourceLocation.documentLevel,
      );

      const f2 = PdfEmbeddedFile(
        id: 'emb_1',
        filename: 'file.txt',
        mimeType: 'text/plain',
        declaredSize: 100,
        streamObjectNumber: 5,
        sourceLocation: PdfAttachmentSourceLocation.documentLevel,
      );

      const f3 = PdfEmbeddedFile(
        id: 'emb_2',
        filename: 'file2.txt',
        streamObjectNumber: 6,
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
    });
  });

  group('PdfAttachmentExtractionResult Tests', () {
    test('completed result properties', () {
      final res = PdfAttachmentExtractionResult.completed(
        outputPath: '/tmp/extracted.pdf',
        extractedBytesCount: 2048,
      );
      expect(res.isSuccess, isTrue);
      expect(res.isFailure, isFalse);
      expect(res.isCancelled, isFalse);
      expect(res.outputPath, '/tmp/extracted.pdf');
      expect(res.extractedBytesCount, 2048);
      expect(res.errorMessage, isNull);
    });

    test('failed result properties', () {
      final res = PdfAttachmentExtractionResult.failed('Disk full error');
      expect(res.isSuccess, isFalse);
      expect(res.isFailure, isTrue);
      expect(res.errorMessage, 'Disk full error');
    });

    test('cancelled result properties', () {
      final res = PdfAttachmentExtractionResult.cancelled();
      expect(res.isCancelled, isTrue);
      expect(res.isSuccess, isFalse);
      expect(res.isFailure, isFalse);
    });
  });
}
