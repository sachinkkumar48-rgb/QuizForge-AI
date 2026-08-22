import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ocr/ocr_engine.dart';
import '../ocr/onnx/onnx_ocr_engine.dart';
import '../ocr/page_text_classifier.dart';
import '../services/ocr_service.dart';

/// Provider for the abstract [PageTextClassifier] instance.
final pageClassifierProvider = Provider<PageTextClassifier>((ref) {
  return const PageTextClassifier();
});

/// Provider for the active [OcrEngine] implementation.
///
/// Can be overridden in tests with [MockOcrEngine].
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  final engine = OnnxOcrEngine();
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});

/// Provider for the application [OcrService] coordinator.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final engine = ref.watch(ocrEngineProvider);
  final classifier = ref.watch(pageClassifierProvider);
  return OcrService(
    engine: engine,
    classifier: classifier,
  );
});
