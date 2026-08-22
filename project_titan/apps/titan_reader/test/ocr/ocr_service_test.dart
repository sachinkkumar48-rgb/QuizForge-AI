import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_request.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';
import 'package:titan_reader/src/ocr/mock_ocr_engine.dart';
import 'package:titan_reader/src/services/ocr_service.dart';

void main() {
  group('OcrService Application Coordinator Tests', () {
    test('classifies page metrics accurately', () {
      final engine = MockOcrEngine();
      final service = OcrService(engine: engine);

      final classScanned = service.classifyPage(
        pageNumber: 1,
        characterCount: 0,
        rasterImageCount: 1,
      );
      expect(classScanned.category, PageTextCategory.imageOnly);
      expect(classScanned.isOcrRecommended, isTrue);

      final classNative = service.classifyPage(
        pageNumber: 2,
        characterCount: 500,
        rasterImageCount: 0,
      );
      expect(classNative.category, PageTextCategory.nativeText);
      expect(classNative.isOcrRecommended, isFalse);
    });

    test(
        'auto-initializes engine when processPage is called before initialization',
        () async {
      final engine = MockOcrEngine();
      final service = OcrService(engine: engine);
      expect(service.isEngineReady, isFalse);

      final req = OcrRequest(
        documentId: 'doc_auto',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
      );

      final result = await service.processPage(req);
      expect(service.isEngineReady, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.fullText, 'PROJECT TITAN');
    });

    test('forwards OCR processing errors gracefully', () async {
      final engine = MockOcrEngine(
        simulatedFailure: const OcrException(
          code: OcrErrorCode.processingFailure,
          message: 'Out of memory during tensor allocation.',
        ),
      );
      final service = OcrService(engine: engine);
      await service.initializeEngine();

      final req = OcrRequest(
        documentId: 'doc_err',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2]),
        imageWidth: 100,
        imageHeight: 100,
        pageWidth: 100,
        pageHeight: 100,
      );

      final result = await service.processPage(req);
      expect(result.isFailure, isTrue);
      expect(result.errorCode, OcrErrorCode.processingFailure);
      expect(result.errorMessage, contains('Out of memory'));
    });

    test('releases engine resources upon disposal', () async {
      final engine = MockOcrEngine();
      final service = OcrService(engine: engine);
      await service.initializeEngine();
      expect(service.isEngineReady, isTrue);

      await service.dispose();
      expect(service.isEngineReady, isFalse);
    });
  });
}
