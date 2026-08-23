/// Identifies the originating source and extraction pipeline of text content in Project TITAN.
enum TextProvenance {
  /// Extracted natively from digital PDF content streams (glyph/font operator streams).
  nativePdf,

  /// Recognized by on-device or edge OCR from raster/scanned image content.
  ocr,

  /// Unified or hybrid content spanning both native glyphs and OCR recognized layers.
  mixed,
}
