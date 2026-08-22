import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';

void main() {
  group('OcrResult Domain Entity Tests', () {
    test(
        'OcrResult.success computes fullText, flattens lines/words, and calculates average confidence',
        () {
      const word1 = OcrWord(
        text: 'Hello',
        boundingBox:
            NormalizedPageRect(left: 0.1, top: 0.1, right: 0.2, bottom: 0.15),
        confidence: OcrConfidence(0.90),
      );
      const word2 = OcrWord(
        text: 'World',
        boundingBox:
            NormalizedPageRect(left: 0.22, top: 0.1, right: 0.35, bottom: 0.15),
        confidence: OcrConfidence(0.96),
      );
      const line1 = OcrLine(
        text: 'Hello World',
        boundingBox:
            NormalizedPageRect(left: 0.1, top: 0.1, right: 0.35, bottom: 0.15),
        confidence: OcrConfidence(0.93),
        words: [word1, word2],
      );
      const block1 = OcrBlock(
        text: 'Hello World',
        boundingBox:
            NormalizedPageRect(left: 0.1, top: 0.1, right: 0.35, bottom: 0.15),
        confidence: OcrConfidence(0.93),
        lines: [line1],
      );

      final result = OcrResult.success(
        pageNumber: 1,
        blocks: const [block1],
        processingDurationMs: 145,
        engineName: 'ONNX Runtime',
        modelIdentifier: 'ppocr-v4-en-int8',
      );

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.fullText, 'Hello World');
      expect(result.lines.length, 1);
      expect(result.words.length, 2);
      expect(result.averageConfidence.value, closeTo(0.93, 0.001));
      expect(result.processingDurationMs, 145);
      expect(result.engineName, 'ONNX Runtime');

      final json = result.toJson();
      final restored = OcrResult.fromJson(json);
      expect(restored.fullText, result.fullText);
      expect(restored.words.length, 2);
      expect(restored.isSuccess, isTrue);
    });

    test('OcrResult.failure constructs failed state and serializes to JSON',
        () {
      final failure = OcrResult.failure(
        pageNumber: 2,
        errorCode: OcrErrorCode.modelUnavailable,
        errorMessage: 'Language model hin not found locally.',
        engineName: 'ONNX Runtime',
      );

      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.errorCode, OcrErrorCode.modelUnavailable);
      expect(failure.errorMessage, contains('Language model'));

      final json = failure.toJson();
      final restored = OcrResult.fromJson(json);
      expect(restored.isSuccess, isFalse);
      expect(restored.errorCode, OcrErrorCode.modelUnavailable);
    });

    test('OcrResult.cancelled constructs cancelled state', () {
      final cancelled =
          OcrResult.cancelled(pageNumber: 3, engineName: 'Mock Engine');
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isSuccess, isFalse);
      expect(cancelled.errorCode, OcrErrorCode.cancelled);
    });
  });
}
