library;

class OCRRegion {
  final double x;
  final double y;
  final double width;
  final double height;
  final String extractedText;
  final double confidence;

  const OCRRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.extractedText,
    this.confidence = 1.0,
  });
}

class OCRResult {
  final String fullText;
  final List<OCRRegion> regions;
  final double averageConfidence;
  final String language;

  const OCRResult({
    required this.fullText,
    this.regions = const [],
    this.averageConfidence = 1.0,
    this.language = 'en',
  });
}

abstract class IOCREngine {
  Future<OCRResult> processImage(List<int> imageBytes, {String language = 'en'});
}

class OCREngineStub implements IOCREngine {
  const OCREngineStub();

  @override
  Future<OCRResult> processImage(List<int> imageBytes, {String language = 'en'}) async {
    return OCRResult(
      fullText: '[OCR Extracted Text Stub]',
      regions: const [],
      averageConfidence: 0.99,
      language: language,
    );
  }
}
