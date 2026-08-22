import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_request.dart';
import 'package:titan_reader/src/ocr/mock_ocr_engine.dart';
import 'package:titan_reader/src/ocr/ocr_model_lifecycle.dart';

void main() {
  group('MockOcrEngine Lifecycle and Recognition Tests', () {
    test(
        'transitions lifecycle states: uninitialized -> loading -> ready -> disposed',
        () async {
      final engine = MockOcrEngine();
      expect(engine.status, OcrModelStatus.uninitialized);
      expect(engine.isReady, isFalse);

      await engine.initialize();
      expect(engine.status, OcrModelStatus.ready);
      expect(engine.isReady, isTrue);
      expect(engine.activeModel?.id, 'ppocr-v4-en-int8');

      await engine.dispose();
      expect(engine.status, OcrModelStatus.uninitialized);
      expect(engine.isReady, isFalse);
    });

    test('returns deterministic mock OCR regions for valid request', () async {
      final engine = MockOcrEngine();
      await engine.initialize();

      final request = OcrRequest(
        documentId: 'doc_100',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        imageWidth: 800,
        imageHeight: 1200,
        pageWidth: 595,
        pageHeight: 842,
      );

      final result = await engine.recognize(request);
      expect(result.isSuccess, isTrue);
      expect(result.pageNumber, 1);
      expect(result.fullText, 'PROJECT TITAN');
      expect(result.words.length, 2);
      expect(result.words.first.text, 'PROJECT');
      expect(result.words.last.text, 'TITAN');
    });

    test('fails gracefully when request image payload is empty', () async {
      final engine = MockOcrEngine();
      await engine.initialize();

      final invalidReq = OcrRequest(
        documentId: 'doc_100',
        pageNumber: 1,
        imageBytes: Uint8List(0),
        imageWidth: 0,
        imageHeight: 0,
        pageWidth: 595,
        pageHeight: 842,
      );

      final result = await engine.recognize(invalidReq);
      expect(result.isFailure, isTrue);
      expect(result.errorCode, OcrErrorCode.invalidInput);
    });

    test('simulates configured failure mode', () async {
      final engine = MockOcrEngine(
        simulatedFailure: const OcrException(
          code: OcrErrorCode.processingFailure,
          message: 'Simulated tensor memory fault.',
        ),
      );
      await engine.initialize();

      final request = OcrRequest(
        documentId: 'doc_100',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2]),
        imageWidth: 100,
        imageHeight: 100,
        pageWidth: 100,
        pageHeight: 100,
      );

      final result = await engine.recognize(request);
      expect(result.isFailure, isTrue);
      expect(result.errorCode, OcrErrorCode.processingFailure);
      expect(result.errorMessage, 'Simulated tensor memory fault.');
    });
  });
}
