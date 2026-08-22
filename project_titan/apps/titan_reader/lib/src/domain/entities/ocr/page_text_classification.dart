import 'package:meta/meta.dart';

/// Categorization of a PDF page's textual composition.
enum PageTextCategory {
  /// The page contains rich native PDF text streams (searchable glyphs/characters).
  nativeText,

  /// The page contains only scanned raster images without native text streams.
  imageOnly,

  /// The page contains both native text streams and significant raster imagery.
  mixed,

  /// Classification could not be determined or page is not loaded.
  unknown,
}

/// Domain entity representing the text composition classification of a PDF page.
@immutable
class PageTextClassification {
  /// 1-based page number.
  final int pageNumber;

  /// The detected category of textual composition.
  final PageTextCategory category;

  /// Count of selectable native characters found on the page.
  final int nativeCharacterCount;

  /// Count of raster images (/XObject /Subtype /Image) embedded in the page.
  final int rasterImageCount;

  /// Whether running on-device OCR is recommended for this page.
  final bool isOcrRecommended;

  /// Diagnostic explanation for the classification.
  final String diagnosticReason;

  const PageTextClassification({
    required this.pageNumber,
    required this.category,
    this.nativeCharacterCount = 0,
    this.rasterImageCount = 0,
    this.isOcrRecommended = false,
    this.diagnosticReason = '',
  });

  /// Factory helper for a purely image-only / scanned page.
  factory PageTextClassification.imageOnly({
    required int pageNumber,
    int rasterImageCount = 1,
    String reason = 'No selectable native text found; raster imagery detected.',
  }) {
    return PageTextClassification(
      pageNumber: pageNumber,
      category: PageTextCategory.imageOnly,
      nativeCharacterCount: 0,
      rasterImageCount: rasterImageCount,
      isOcrRecommended: true,
      diagnosticReason: reason,
    );
  }

  /// Factory helper for a page with native text streams.
  factory PageTextClassification.nativeText({
    required int pageNumber,
    required int characterCount,
    int rasterImageCount = 0,
  }) {
    return PageTextClassification(
      pageNumber: pageNumber,
      category: PageTextCategory.nativeText,
      nativeCharacterCount: characterCount,
      rasterImageCount: rasterImageCount,
      isOcrRecommended: false,
      diagnosticReason: 'Page contains $characterCount native characters.',
    );
  }

  /// Factory helper for a mixed page.
  factory PageTextClassification.mixed({
    required int pageNumber,
    required int characterCount,
    required int rasterImageCount,
  }) {
    return PageTextClassification(
      pageNumber: pageNumber,
      category: PageTextCategory.mixed,
      nativeCharacterCount: characterCount,
      rasterImageCount: rasterImageCount,
      isOcrRecommended: characterCount < 100 && rasterImageCount > 0,
      diagnosticReason:
          'Page contains $characterCount native characters and $rasterImageCount images.',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageTextClassification &&
          runtimeType == other.runtimeType &&
          pageNumber == other.pageNumber &&
          category == other.category &&
          nativeCharacterCount == other.nativeCharacterCount &&
          rasterImageCount == other.rasterImageCount &&
          isOcrRecommended == other.isOcrRecommended;

  @override
  int get hashCode => Object.hash(
        pageNumber,
        category,
        nativeCharacterCount,
        rasterImageCount,
        isOcrRecommended,
      );

  @override
  String toString() =>
      'PageTextClassification(p$pageNumber: ${category.name}, nativeChars: $nativeCharacterCount, images: $rasterImageCount, ocrRecommended: $isOcrRecommended)';

  Map<String, Object?> toJson() => {
        'pageNumber': pageNumber,
        'category': category.name,
        'nativeCharacterCount': nativeCharacterCount,
        'rasterImageCount': rasterImageCount,
        'isOcrRecommended': isOcrRecommended,
        'diagnosticReason': diagnosticReason,
      };

  factory PageTextClassification.fromJson(Map<String, Object?> json) {
    final catStr = json['category'] as String? ?? 'unknown';
    final cat = PageTextCategory.values.firstWhere(
      (e) => e.name == catStr,
      orElse: () => PageTextCategory.unknown,
    );
    return PageTextClassification(
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      category: cat,
      nativeCharacterCount:
          (json['nativeCharacterCount'] as num?)?.toInt() ?? 0,
      rasterImageCount: (json['rasterImageCount'] as num?)?.toInt() ?? 0,
      isOcrRecommended: json['isOcrRecommended'] as bool? ?? false,
      diagnosticReason: json['diagnosticReason'] as String? ?? '',
    );
  }
}
