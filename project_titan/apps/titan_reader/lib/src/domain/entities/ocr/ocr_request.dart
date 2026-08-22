import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Request parameters submitted to the OCR engine for single-page optical character recognition.
@immutable
class OcrRequest {
  /// Unique identifier of the document being processed.
  final String documentId;

  /// 1-based page number within the document.
  final int pageNumber;

  /// In-memory raster image bytes (PNG, JPEG, or raw RGBA).
  final Uint8List imageBytes;

  /// Width of the rasterized image in pixels.
  final int imageWidth;

  /// Height of the rasterized image in pixels.
  final int imageHeight;

  /// Original PDF page width in points.
  final double pageWidth;

  /// Original PDF page height in points.
  final double pageHeight;

  /// Target BCP-47 / ISO language code (e.g. 'eng', 'hin'). Defaults to 'eng'.
  final String language;

  /// Page rotation quarter turns (0..3) applied during rendering.
  final int rotationQuarterTurns;

  const OcrRequest({
    required this.documentId,
    required this.pageNumber,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.pageWidth,
    required this.pageHeight,
    this.language = 'eng',
    this.rotationQuarterTurns = 0,
  })  : assert(pageNumber >= 1, 'pageNumber must be >= 1'),
        assert(imageWidth >= 0, 'imageWidth must be non-negative'),
        assert(imageHeight >= 0, 'imageHeight must be non-negative'),
        assert(pageWidth > 0, 'pageWidth must be positive'),
        assert(pageHeight > 0, 'pageHeight must be positive');

  @override
  String toString() =>
      'OcrRequest(doc: $documentId, page: $pageNumber, lang: $language, ${imageWidth}x$imageHeight px)';
}
