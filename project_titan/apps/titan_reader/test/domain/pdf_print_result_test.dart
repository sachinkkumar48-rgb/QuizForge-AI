import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_print_result.dart';

void main() {
  group('PdfPrintResult Domain Entity', () {
    test('constructs completed status correctly', () {
      final now = DateTime(2026, 8, 21, 14, 0);
      final result = PdfPrintResult.completed(
        printerName: 'Office-HP-LaserJet',
        timestamp: now,
      );

      expect(result.status, PdfPrintStatus.completed);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.printerName, 'Office-HP-LaserJet');
      expect(result.errorMessage, isNull);
      expect(result.timestamp, now);
      expect(result.toString(), contains('Office-HP-LaserJet'));
    });

    test('constructs cancelled status correctly', () {
      const result = PdfPrintResult.cancelled();

      expect(result.status, PdfPrintStatus.cancelled);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.printerName, isNull);
      expect(result.errorMessage, isNull);
      expect(result.toString(), contains('cancelled'));
    });

    test('constructs failed status correctly', () {
      const result = PdfPrintResult.failed('Spooler error 0x80070057');

      expect(result.status, PdfPrintStatus.failed);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.printerName, isNull);
      expect(result.errorMessage, 'Spooler error 0x80070057');
      expect(result.toString(), contains('Spooler error'));
    });

    test('equality and hashCode work as expected', () {
      const res1 = PdfPrintResult.completed(printerName: 'Printer1');
      const res2 = PdfPrintResult.completed(printerName: 'Printer1');
      const res3 = PdfPrintResult.failed('Error');

      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1, isNot(equals(res3)));
    });
  });
}
