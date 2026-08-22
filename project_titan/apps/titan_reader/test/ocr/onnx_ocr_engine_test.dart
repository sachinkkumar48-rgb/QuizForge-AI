import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_request.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/ocr/ocr_model_lifecycle.dart';
import 'package:titan_reader/src/ocr/onnx/onnx_ocr_engine.dart';

class _FakeOnnxRunner implements OnnxSessionRunner {
  bool sessionLoaded = false;
  bool sessionClosed = false;

  @override
  Future<void> loadSession(String modelFilePath) async {
    sessionLoaded = true;
  }

  @override
  Future<List<OcrBlock>> runInference({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required double pageWidth,
    required double pageHeight,
  }) async {
    const word = OcrWord(
      text: 'CONSTITUTION',
      boundingBox: NormalizedPageRect(
        left: 0.1,
        top: 0.1,
        right: 0.4,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.99),
    );
    const line = OcrLine(
      text: 'CONSTITUTION',
      boundingBox: NormalizedPageRect(
        left: 0.1,
        top: 0.1,
        right: 0.4,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.99),
      words: [word],
    );
    return const [
      OcrBlock(
        text: 'CONSTITUTION',
        boundingBox: NormalizedPageRect(
          left: 0.1,
          top: 0.1,
          right: 0.4,
          bottom: 0.15,
        ),
        confidence: OcrConfidence(0.99),
        lines: [line],
      ),
    ];
  }

  @override
  Future<void> closeSession() async {
    sessionClosed = true;
  }
}

void main() {
  group('OnnxOcrEngine Adapter Tests', () {
    test('initializes with default baseline model', () async {
      final engine = OnnxOcrEngine();
      expect(engine.status, OcrModelStatus.uninitialized);

      await engine.initialize();
      expect(engine.status, OcrModelStatus.ready);
      expect(engine.isReady, isTrue);
      expect(engine.activeModel?.id, 'ppocr-v4-en-int8');
    });

    test('throws OcrException when local model path does not exist', () async {
      final engine = OnnxOcrEngine();
      const missingModel = OcrModelDescriptor(
        id: 'missing-model',
        displayName: 'Missing',
        languageCode: 'hin',
        format: 'onnx',
        version: '1.0',
        sizeBytes: 1000,
        localFilePath: '/non/existent/path/model.onnx',
      );

      await expectLater(
        engine.initialize(model: missingModel),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.modelUnavailable,
        )),
      );
      expect(engine.status, OcrModelStatus.error);
    });

    test('runs inference through custom OnnxSessionRunner', () async {
      final fakeRunner = _FakeOnnxRunner();
      final engine = OnnxOcrEngine(runner: fakeRunner);
      await engine.initialize();

      final request = OcrRequest(
        documentId: 'doc_1',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 1000,
        imageHeight: 1500,
        pageWidth: 595,
        pageHeight: 842,
      );

      final result = await engine.recognize(request);
      expect(result.isSuccess, isTrue);
      expect(result.fullText, 'CONSTITUTION');
      expect(result.words.first.text, 'CONSTITUTION');
      expect(result.words.first.confidence.level, OcrConfidenceLevel.high);

      await engine.dispose();
      expect(fakeRunner.sessionClosed, isTrue);
    });

    test('executes default normalized inference and handles invalid inputs',
        () async {
      final engine = OnnxOcrEngine();
      await engine.initialize();

      final validReq = OcrRequest(
        documentId: 'doc_2',
        pageNumber: 1,
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 800,
        imageHeight: 1200,
        pageWidth: 595,
        pageHeight: 842,
      );

      final result = await engine.recognize(validReq);
      expect(result.isSuccess, isTrue);
      expect(result.fullText, 'Extracted Content');

      final invalidReq = OcrRequest(
        documentId: 'doc_2',
        pageNumber: 1,
        imageBytes: Uint8List(0),
        imageWidth: 0,
        imageHeight: 0,
        pageWidth: 100,
        pageHeight: 100,
      );

      final errResult = await engine.recognize(invalidReq);
      expect(errResult.isFailure, isTrue);
      expect(errResult.errorCode, OcrErrorCode.invalidInput);
    });
  });
}
