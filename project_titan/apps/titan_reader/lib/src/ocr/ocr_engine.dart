import '../domain/entities/ocr/ocr_request.dart';
import '../domain/entities/ocr/ocr_result.dart';
import 'ocr_model_lifecycle.dart';

/// Abstract contract for an on-device Optical Character Recognition engine.
///
/// Implementations are completely decoupled from the domain and UI layers.
/// Concrete adapters (such as [OnnxOcrEngine] or [MockOcrEngine]) sit behind
/// this interface and manage native FFI, isolates, and model sessions.
abstract class OcrEngine {
  /// Human-readable name of the engine (e.g. 'ONNX Runtime (PP-OCRv4)', 'Mock OCR').
  String get engineName;

  /// Current lifecycle status of the engine's model session.
  OcrModelStatus get status;

  /// True if the engine is initialized and ready to accept [OcrRequest]s.
  bool get isReady;

  /// Currently active model descriptor, or null if uninitialized.
  OcrModelDescriptor? get activeModel;

  /// Initializes model weights, allocates sessions, and starts worker threads/isolates.
  Future<void> initialize({OcrModelDescriptor? model});

  /// Executes optical character recognition on a rasterized page image.
  Future<OcrResult> recognize(OcrRequest request);

  /// Releases model memory, native sessions, and terminates worker threads/isolates.
  Future<void> dispose();
}
