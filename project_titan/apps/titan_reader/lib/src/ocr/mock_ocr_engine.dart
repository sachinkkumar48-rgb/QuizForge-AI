import 'dart:async';

import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/ocr/ocr_confidence.dart';
import '../domain/entities/ocr/ocr_error.dart';
import '../domain/entities/ocr/ocr_request.dart';
import '../domain/entities/ocr/ocr_result.dart';
import '../domain/entities/ocr/ocr_text_region.dart';
import 'ocr_engine.dart';
import 'ocr_model_lifecycle.dart';

/// Deterministic mock OCR engine for testing, headless runners, and platforms without native binaries.
class MockOcrEngine implements OcrEngine {
  @override
  final String engineName;

  OcrModelStatus _status = OcrModelStatus.uninitialized;
  OcrModelDescriptor? _activeModel;

  /// Predetermined blocks to return on recognition if provided.
  final List<OcrBlock>? mockBlocks;

  /// Simulated processing duration.
  final Duration simulatedLatency;

  /// If non-null, every call to [recognize] will fail with this exception.
  final OcrException? simulatedFailure;

  MockOcrEngine({
    this.engineName = 'Mock OCR Engine',
    this.mockBlocks,
    this.simulatedLatency = Duration.zero,
    this.simulatedFailure,
  });

  @override
  OcrModelStatus get status => _status;

  @override
  bool get isReady => _status == OcrModelStatus.ready;

  @override
  OcrModelDescriptor? get activeModel => _activeModel;

  @override
  Future<void> initialize({OcrModelDescriptor? model}) async {
    _status = OcrModelStatus.loading;
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    _activeModel = model ?? OcrModelDescriptor.englishBaseline;
    _status = OcrModelStatus.ready;
  }

  @override
  Future<OcrResult> recognize(OcrRequest request) async {
    if (_status != OcrModelStatus.ready) {
      return OcrResult.failure(
        pageNumber: request.pageNumber,
        errorCode: OcrErrorCode.engineUnavailable,
        errorMessage:
            'Mock OCR engine is not in ready state (status: ${_status.name}).',
        engineName: engineName,
      );
    }

    if (request.imageBytes.isEmpty ||
        request.imageWidth <= 0 ||
        request.imageHeight <= 0) {
      return OcrResult.failure(
        pageNumber: request.pageNumber,
        errorCode: OcrErrorCode.invalidInput,
        errorMessage: 'Invalid image payload or zero dimensions.',
        engineName: engineName,
      );
    }

    if (simulatedFailure != null) {
      return OcrResult.failure(
        pageNumber: request.pageNumber,
        errorCode: simulatedFailure!.code,
        errorMessage: simulatedFailure!.message,
        engineName: engineName,
      );
    }

    _status = OcrModelStatus.processing;
    final stopwatch = Stopwatch()..start();

    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    stopwatch.stop();
    _status = OcrModelStatus.ready;

    // Use customized mock blocks or generate deterministic sample regions
    final blocks = mockBlocks ?? _generateDefaultMockBlocks(request);

    return OcrResult.success(
      pageNumber: request.pageNumber,
      blocks: blocks,
      processingDurationMs: stopwatch.elapsedMilliseconds,
      engineName: engineName,
      modelIdentifier: _activeModel?.id ?? 'mock-v1',
    );
  }

  @override
  Future<void> dispose() async {
    _status = OcrModelStatus.uninitialized;
    _activeModel = null;
  }

  List<OcrBlock> _generateDefaultMockBlocks(OcrRequest request) {
    const word1 = OcrWord(
      text: 'PROJECT',
      boundingBox: NormalizedPageRect(
        left: 0.1,
        top: 0.1,
        right: 0.3,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.98),
      wordIndex: 0,
    );

    const word2 = OcrWord(
      text: 'TITAN',
      boundingBox: NormalizedPageRect(
        left: 0.32,
        top: 0.1,
        right: 0.5,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.97),
      wordIndex: 1,
    );

    const line1 = OcrLine(
      text: 'PROJECT TITAN',
      boundingBox: NormalizedPageRect(
        left: 0.1,
        top: 0.1,
        right: 0.5,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.975),
      lineIndex: 0,
      words: [word1, word2],
    );

    const block = OcrBlock(
      text: 'PROJECT TITAN',
      boundingBox: NormalizedPageRect(
        left: 0.1,
        top: 0.1,
        right: 0.5,
        bottom: 0.15,
      ),
      confidence: OcrConfidence(0.975),
      blockIndex: 0,
      lines: [line1],
    );

    return const [block];
  }
}
