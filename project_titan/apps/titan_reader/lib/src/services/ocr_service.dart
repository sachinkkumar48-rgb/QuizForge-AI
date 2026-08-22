import '../domain/entities/ocr/ocr_error.dart';
import '../domain/entities/ocr/ocr_request.dart';
import '../domain/entities/ocr/ocr_result.dart';
import '../domain/entities/ocr/page_text_classification.dart';
import '../manipulation/ast/pdf_document_ast.dart';
import '../ocr/ocr_engine.dart';
import '../ocr/ocr_model_lifecycle.dart';
import '../ocr/page_text_classifier.dart';

/// Application service orchestrating page classification, OCR recognition, and coordinate normalization.
class OcrService {
  final OcrEngine _engine;
  final PageTextClassifier _classifier;

  const OcrService({
    required OcrEngine engine,
    PageTextClassifier classifier = const PageTextClassifier(),
  })  : _engine = engine,
        _classifier = classifier;

  /// Current OCR engine status.
  OcrModelStatus get status => _engine.status;

  /// Whether the underlying OCR engine is initialized and ready.
  bool get isEngineReady => _engine.isReady;

  /// The active model descriptor if initialized.
  OcrModelDescriptor? get activeModel => _engine.activeModel;

  /// Name of the active OCR engine.
  String get engineName => _engine.engineName;

  /// Initializes the OCR engine with the specified [model] (or English baseline by default).
  Future<void> initializeEngine({OcrModelDescriptor? model}) async {
    await _engine.initialize(model: model);
  }

  /// Classifies a PDF page based on character count and raster image count.
  PageTextClassification classifyPage({
    required int pageNumber,
    required int characterCount,
    required int rasterImageCount,
  }) {
    return _classifier.classifyPageMetrics(
      pageNumber: pageNumber,
      characterCount: characterCount,
      rasterImageCount: rasterImageCount,
    );
  }

  /// Classifies an AST page by inspecting its resource dictionary for embedded raster images.
  PageTextClassification classifyAstPage({
    required PdfDocumentAst ast,
    required int pageNumber,
    required int characterCount,
  }) {
    final rasterCount = _classifier.countPageRasterImages(ast, pageNumber);
    return _classifier.classifyPageMetrics(
      pageNumber: pageNumber,
      characterCount: characterCount,
      rasterImageCount: rasterCount,
    );
  }

  /// Executes on-device OCR recognition on the requested page raster image.
  Future<OcrResult> processPage(OcrRequest request) async {
    if (!_engine.isReady) {
      // Auto-initialize if not ready
      try {
        await _engine.initialize();
      } catch (e) {
        return OcrResult.failure(
          pageNumber: request.pageNumber,
          errorCode: OcrErrorCode.initializationFailure,
          errorMessage: 'Failed to auto-initialize OCR engine: $e',
          engineName: _engine.engineName,
        );
      }
    }

    return _engine.recognize(request);
  }

  /// Releases OCR engine and model resources.
  Future<void> dispose() async {
    await _engine.dispose();
  }
}
