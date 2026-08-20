import '../../domain/entities/pdf_manipulation_result.dart';
import '../../domain/entities/pdf_page_label_config.dart';
import '../../domain/entities/pdf_page_range.dart';

/// Contract for PDF Document Manipulation and structural page mutations.
abstract class PdfManipulationEngine {
  /// Merges multiple PDF files in [inputPaths] into a single document at [outputPath].
  Future<PdfManipulationResult> merge({
    required List<String> inputPaths,
    required String outputPath,
  });

  /// Splits [inputPath] into multiple sub-documents based on [ranges].
  Future<PdfManipulationResult> split({
    required String inputPath,
    required List<PdfPageRange> ranges,
    required String outputDirectory,
    required String baseName,
  });

  /// Extracts specified 1-based [pages] from [inputPath] into [outputPath].
  Future<PdfManipulationResult> extractPages({
    required String inputPath,
    required List<int> pages,
    required String outputPath,
  });

  /// Deletes specified 1-based [pagesToDelete] from [inputPath] and writes remaining to [outputPath].
  Future<PdfManipulationResult> deletePages({
    required String inputPath,
    required List<int> pagesToDelete,
    required String outputPath,
  });

  /// Reorders pages according to [newOrder] (1-based original page indices) and writes to [outputPath].
  Future<PdfManipulationResult> reorderPages({
    required String inputPath,
    required List<int> newOrder,
    required String outputPath,
  });

  /// Rotates pages according to [pageRotations] (1-based page number -> rotation degrees: 90, 180, 270).
  Future<PdfManipulationResult> rotatePages({
    required String inputPath,
    required Map<int, int> pageRotations,
    required String outputPath,
    bool relative = true,
  });

  /// Inserts a blank page into [inputPath] at 1-based [targetIndex].
  Future<PdfManipulationResult> insertBlankPage({
    required String inputPath,
    required int targetIndex,
    double width = 595.0,
    double height = 842.0,
    required String outputPath,
  });

  /// Inserts [sourcePages] (1-based) from [sourcePath] into [targetPath] at 1-based [targetIndex].
  Future<PdfManipulationResult> insertPagesFromPdf({
    required String targetPath,
    required int targetIndex,
    required String sourcePath,
    required List<int> sourcePages,
    required String outputPath,
  });

  /// Configures `/PageLabels` for [inputPath] and writes to [outputPath].
  Future<PdfManipulationResult> setPageLabels({
    required String inputPath,
    required List<PdfPageLabelRange> labelRanges,
    required String outputPath,
  });

  /// Fast inspection of document page count.
  Future<int> inspectPageCount(String inputPath);
}
