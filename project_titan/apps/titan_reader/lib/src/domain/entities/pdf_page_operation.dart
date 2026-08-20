import 'package:meta/meta.dart';
import 'pdf_page_range.dart';

/// Clockwise page rotation options in degrees.
enum PdfPageRotation {
  none(0),
  cw90(90),
  cw180(180),
  cw270(270);

  final int degrees;
  const PdfPageRotation(this.degrees);

  static PdfPageRotation fromDegrees(int deg) {
    final normalized = (deg % 360 + 360) % 360;
    switch (normalized) {
      case 90:
        return PdfPageRotation.cw90;
      case 180:
        return PdfPageRotation.cw180;
      case 270:
        return PdfPageRotation.cw270;
      default:
        return PdfPageRotation.none;
    }
  }

  PdfPageRotation rotateClockwise90() {
    return fromDegrees(degrees + 90);
  }
}

/// Abstract base class for all in-memory page operation intents.
@immutable
abstract class PdfPageOperation {
  const PdfPageOperation();
}

/// Rotate specified pages by degrees.
class RotatePagesOperation extends PdfPageOperation {
  /// 1-based page numbers to rotate.
  final List<int> pages;

  /// Absolute rotation target or rotation delta.
  final PdfPageRotation rotation;

  /// Whether rotation is relative to existing page rotation.
  final bool isRelative;

  const RotatePagesOperation({
    required this.pages,
    required this.rotation,
    this.isRelative = true,
  });
}

/// Delete specified pages from document.
class DeletePagesOperation extends PdfPageOperation {
  /// 1-based page numbers to delete.
  final List<int> pages;

  const DeletePagesOperation({required this.pages});
}

/// Reorder pages in the document.
class ReorderPagesOperation extends PdfPageOperation {
  /// Ordered list of 1-based source page indices representing the new sequence.
  /// Length must match original page count.
  final List<int> newOrder;

  const ReorderPagesOperation({required this.newOrder});
}

/// Insert a blank page into the document.
class InsertBlankPageOperation extends PdfPageOperation {
  /// 1-based index where blank page will be inserted (1 = beginning).
  final int targetIndex;

  /// Page width in points (default 595.0 = A4).
  final double width;

  /// Page height in points (default 842.0 = A4).
  final double height;

  const InsertBlankPageOperation({
    required this.targetIndex,
    this.width = 595.0,
    this.height = 842.0,
  });
}

/// Insert pages from an external PDF.
class InsertPdfPagesOperation extends PdfPageOperation {
  /// 1-based index where pages will be inserted.
  final int targetIndex;

  /// Path to source PDF file.
  final String sourcePdfPath;

  /// 1-based pages from source PDF to insert. Empty means all pages.
  final List<int> sourcePages;

  const InsertPdfPagesOperation({
    required this.targetIndex,
    required this.sourcePdfPath,
    this.sourcePages = const [],
  });
}

/// Request to merge multiple PDFs into one.
@immutable
class PdfMergeRequest {
  /// Ordered list of input file paths.
  final List<String> inputPaths;

  /// Output destination file path.
  final String outputPath;

  const PdfMergeRequest({
    required this.inputPaths,
    required this.outputPath,
  });
}

/// Request to split a PDF into parts.
@immutable
class PdfSplitRequest {
  /// Path to source PDF.
  final String sourcePath;

  /// Output directory where split parts will be saved.
  final String outputDirectory;

  /// Base name for split files (e.g. "chapter" -> "chapter_001.pdf").
  final String baseName;

  /// Page ranges defining each split part.
  final List<PdfPageRange> splitRanges;

  const PdfSplitRequest({
    required this.sourcePath,
    required this.outputDirectory,
    required this.baseName,
    required this.splitRanges,
  });
}

/// Request to extract specific pages into a new PDF.
@immutable
class PdfExtractRequest {
  /// Path to source PDF.
  final String sourcePath;

  /// 1-based pages to extract.
  final List<int> pagesToExtract;

  /// Output file path.
  final String outputPath;

  const PdfExtractRequest({
    required this.sourcePath,
    required this.pagesToExtract,
    required this.outputPath,
  });
}
