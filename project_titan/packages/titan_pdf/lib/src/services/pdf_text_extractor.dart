import 'package:meta/meta.dart';
import '../models/document_source.dart';
import '../models/learning_page.dart';
import '../models/text_provenance.dart';

/// Structured page text extracted from a PDF document.
@immutable
class ExtractedPageText {
  /// 1-based page number.
  final int pageNumber;

  /// Cleaned text string of the page.
  final String text;

  /// Source provenance (nativePdf or ocr).
  final TextProvenance provenance;

  /// Dominant script ('latin', 'devanagari', 'bilingual').
  final String script;

  /// Confidence score (1.0 for digital, 0.0 .. 1.0 for OCR).
  final double confidence;

  /// Extracted blocks if available.
  final List<LearningPageBlock> blocks;

  const ExtractedPageText({
    required this.pageNumber,
    required this.text,
    required this.provenance,
    this.script = 'latin',
    this.confidence = 1.0,
    this.blocks = const [],
  });

  /// An empty page text result.
  const ExtractedPageText.empty({
    required this.pageNumber,
  })  : text = '',
        provenance = TextProvenance.nativePdf,
        script = 'latin',
        confidence = 1.0,
        blocks = const [];
}

/// Pluggable interface for performing OCR on scanned/raster pages when native glyphs are absent.
abstract interface class OcrFallbackProvider {
  /// Recognizes text from [source] on [pageNumber].
  Future<ExtractedPageText> recognizePage({
    required DocumentSource source,
    required int pageNumber,
    String? preferredLanguage,
  });
}

/// Abstract contract for extracting text from PDF document sources.
abstract interface class PdfTextExtractor {
  /// Extracts text from [pageNumber] of [source].
  ///
  /// If [forceOcr] is true, delegates directly to OCR fallback if available.
  /// If native text is empty and an [OcrFallbackProvider] is configured, falls back to OCR.
  Future<ExtractedPageText> extractPageText({
    required DocumentSource source,
    required int pageNumber,
    bool forceOcr = false,
  });

  /// Estimates or retrieves total page count of [source].
  Future<int> getPageCount(DocumentSource source);
}

/// Standard implementation of [PdfTextExtractor] supporting native text extraction
/// with optional [OcrFallbackProvider] fallback.
class DefaultPdfTextExtractor implements PdfTextExtractor {
  final OcrFallbackProvider? _ocrFallback;
  final Future<String?> Function(DocumentSource source, int pageNumber)?
      _nativeExtractor;
  final Future<int> Function(DocumentSource source)? _pageCountResolver;

  const DefaultPdfTextExtractor({
    OcrFallbackProvider? ocrFallback,
    Future<String?> Function(DocumentSource source, int pageNumber)?
        nativeExtractor,
    Future<int> Function(DocumentSource source)? pageCountResolver,
  })  : _ocrFallback = ocrFallback,
        _nativeExtractor = nativeExtractor,
        _pageCountResolver = pageCountResolver;

  @override
  Future<int> getPageCount(DocumentSource source) async {
    if (_pageCountResolver != null) {
      return _pageCountResolver(source);
    }
    // Default estimate or metadata check
    final metaPages = source.metadata['pageCount'] as int?;
    if (metaPages != null && metaPages > 0) return metaPages;
    return 1;
  }

  @override
  Future<ExtractedPageText> extractPageText({
    required DocumentSource source,
    required int pageNumber,
    bool forceOcr = false,
  }) async {
    if (forceOcr && _ocrFallback != null) {
      return _ocrFallback.recognizePage(
        source: source,
        pageNumber: pageNumber,
        preferredLanguage: source.languageCode,
      );
    }

    String? nativeText;
    if (_nativeExtractor != null) {
      nativeText = await _nativeExtractor(source, pageNumber);
    }

    final trimmed = nativeText?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final script = _detectScript(trimmed);
      return ExtractedPageText(
        pageNumber: pageNumber,
        text: trimmed,
        provenance: TextProvenance.nativePdf,
        script: script,
        confidence: 1.0,
      );
    }

    // If native text is absent and OCR fallback is available, trigger OCR
    if (_ocrFallback != null) {
      final ocrResult = await _ocrFallback.recognizePage(
        source: source,
        pageNumber: pageNumber,
        preferredLanguage: source.languageCode,
      );
      if (ocrResult.text.trim().isNotEmpty) {
        return ocrResult;
      }
    }

    return ExtractedPageText.empty(pageNumber: pageNumber);
  }

  /// Lightweight Unicode script detection (Latin, Devanagari, or Bilingual).
  static String _detectScript(String text) {
    var hasDevanagari = false;
    var hasLatin = false;

    for (final rune in text.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) {
        hasDevanagari = true;
      } else if ((rune >= 0x0041 && rune <= 0x005A) ||
          (rune >= 0x0061 && rune <= 0x007A)) {
        hasLatin = true;
      }
    }

    if (hasDevanagari && hasLatin) return 'bilingual';
    if (hasDevanagari) return 'devanagari';
    return 'latin';
  }
}
