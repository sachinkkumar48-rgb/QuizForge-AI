import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:titan_pdf/titan_pdf.dart';
import '../../domain/entities/pdf_manipulation_result.dart';
import '../../domain/entities/pdf_page_label_config.dart';
import '../../domain/entities/pdf_page_range.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../engine/pdf_manipulation_engine.dart';
import '../engine/default_pdf_manipulation_engine.dart';

/// High-level domain service orchestrating PDF Document Manipulation workflows with file safety and output verification.
class PdfDocumentManipulationService {
  final PdfManipulationEngine _engine;
  final PdfValidationService _validator;

  PdfDocumentManipulationService({
    PdfManipulationEngine? engine,
    PdfValidationService? validator,
  })  : _engine = engine ?? const DefaultPdfManipulationEngine(),
        _validator = validator ?? const PdfValidationService();

  /// Generates a safe, non-colliding output path with a given action suffix (e.g. `doc_reordered.pdf`).
  String generateSafeOutputPath(String sourcePath, String suffix,
      {String? customOutputDir}) {
    final dir = customOutputDir ?? p.dirname(sourcePath);
    final baseWithoutExt = p.basenameWithoutExtension(sourcePath);
    var candidate = p.join(dir, '${baseWithoutExt}_$suffix.pdf');

    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '${baseWithoutExt}_${suffix}_$counter.pdf');
      counter++;
    }
    return candidate;
  }

  /// Merges multiple PDFs safely.
  Future<PdfManipulationResult> mergePdfs({
    required List<String> inputPaths,
    String? customOutputPath,
  }) async {
    if (inputPaths.length < 2) {
      throw const PdfManipulationException(
          'Merge requires at least two input PDF files.');
    }

    for (final path in inputPaths) {
      _preflightValidate(path);
    }

    final outPath =
        customOutputPath ?? generateSafeOutputPath(inputPaths.first, 'merged');
    final result =
        await _engine.merge(inputPaths: inputPaths, outputPath: outPath);

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 2);
    return result;
  }

  /// Splits a PDF into multiple sub-documents according to [ranges].
  Future<PdfManipulationResult> splitPdf({
    required String sourcePath,
    required List<PdfPageRange> ranges,
    String? outputDirectory,
    String? baseName,
  }) async {
    _preflightValidate(sourcePath);
    if (ranges.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'Must specify at least one split range.');
    }

    final outDir = outputDirectory ?? p.dirname(sourcePath);
    final name = baseName ?? p.basenameWithoutExtension(sourcePath);

    final result = await _engine.split(
      inputPath: sourcePath,
      ranges: ranges,
      outputDirectory: outDir,
      baseName: name,
    );

    for (final partPath in result.outputPaths) {
      await _postflightVerify(partPath, expectedMinPages: 1);
    }

    return result;
  }

  /// Extracts specified pages into a new PDF.
  Future<PdfManipulationResult> extractPages({
    required String sourcePath,
    required List<int> pages,
    String? customOutputPath,
  }) async {
    _preflightValidate(sourcePath);
    if (pages.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'Must specify at least one page to extract.');
    }

    final outPath =
        customOutputPath ?? generateSafeOutputPath(sourcePath, 'extracted');
    final result = await _engine.extractPages(
      inputPath: sourcePath,
      pages: pages,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath,
        expectedMinPages: pages.length);
    return result;
  }

  /// Deletes specified pages from a PDF.
  Future<PdfManipulationResult> deletePages({
    required String sourcePath,
    required List<int> pagesToDelete,
    String? customOutputPath,
  }) async {
    _preflightValidate(sourcePath);
    if (pagesToDelete.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'No pages specified for deletion.');
    }

    final outPath =
        customOutputPath ?? generateSafeOutputPath(sourcePath, 'deleted');
    final result = await _engine.deletePages(
      inputPath: sourcePath,
      pagesToDelete: pagesToDelete,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 1);
    return result;
  }

  /// Reorders pages in a PDF.
  Future<PdfManipulationResult> reorderPages({
    required String sourcePath,
    required List<int> newOrder,
    String? customOutputPath,
  }) async {
    _preflightValidate(sourcePath);
    if (newOrder.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'Reorder sequence cannot be empty.');
    }

    final outPath =
        customOutputPath ?? generateSafeOutputPath(sourcePath, 'reordered');
    final result = await _engine.reorderPages(
      inputPath: sourcePath,
      newOrder: newOrder,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath,
        expectedMinPages: newOrder.length);
    return result;
  }

  /// Rotates pages in a PDF.
  Future<PdfManipulationResult> rotatePages({
    required String sourcePath,
    required Map<int, int> pageRotations,
    String? customOutputPath,
    bool relative = true,
  }) async {
    _preflightValidate(sourcePath);
    if (pageRotations.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'No page rotations specified.');
    }

    final outPath =
        customOutputPath ?? generateSafeOutputPath(sourcePath, 'rotated');
    final result = await _engine.rotatePages(
      inputPath: sourcePath,
      pageRotations: pageRotations,
      outputPath: outPath,
      relative: relative,
    );

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 1);
    return result;
  }

  /// Inserts a blank page into a PDF.
  Future<PdfManipulationResult> insertBlankPage({
    required String sourcePath,
    required int targetIndex,
    double width = 595.0,
    double height = 842.0,
    String? customOutputPath,
  }) async {
    _preflightValidate(sourcePath);
    final outPath = customOutputPath ??
        generateSafeOutputPath(sourcePath, 'blank_inserted');
    final result = await _engine.insertBlankPage(
      inputPath: sourcePath,
      targetIndex: targetIndex,
      width: width,
      height: height,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 1);
    return result;
  }

  /// Inserts pages from another PDF.
  Future<PdfManipulationResult> insertPagesFromPdf({
    required String targetPath,
    required int targetIndex,
    required String sourcePath,
    List<int> sourcePages = const [],
    String? customOutputPath,
  }) async {
    _preflightValidate(targetPath);
    _preflightValidate(sourcePath);

    final outPath = customOutputPath ??
        generateSafeOutputPath(targetPath, 'pages_inserted');
    final result = await _engine.insertPagesFromPdf(
      targetPath: targetPath,
      targetIndex: targetIndex,
      sourcePath: sourcePath,
      sourcePages: sourcePages,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 1);
    return result;
  }

  /// Sets `/PageLabels` for a PDF.
  Future<PdfManipulationResult> setPageLabels({
    required String sourcePath,
    required List<PdfPageLabelRange> labelRanges,
    String? customOutputPath,
  }) async {
    _preflightValidate(sourcePath);
    final outPath =
        customOutputPath ?? generateSafeOutputPath(sourcePath, 'labeled');
    final result = await _engine.setPageLabels(
      inputPath: sourcePath,
      labelRanges: labelRanges,
      outputPath: outPath,
    );

    await _postflightVerify(result.primaryOutputPath, expectedMinPages: 1);
    return result;
  }

  /// Fast inspection of page count.
  Future<int> inspectPageCount(String filePath) async {
    _preflightValidate(filePath);
    return await _engine.inspectPageCount(filePath);
  }

  void _preflightValidate(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $filePath',
          filePath: filePath);
    }
    final size = file.lengthSync();
    final raf = file.openSync();
    try {
      final headerBytes = raf.readSync(10);
      _validator.validatePdf(
        filePath: filePath,
        sizeBytes: size,
        headerBytes: headerBytes,
      );
    } finally {
      raf.closeSync();
    }
  }

  Future<void> _postflightVerify(String outputPath,
      {int expectedMinPages = 1}) async {
    final file = File(outputPath);
    if (!await file.exists()) {
      throw PdfAtomicWriteException(
          'Generated PDF file does not exist: $outputPath',
          targetPath: outputPath);
    }
    final size = await file.length();
    if (size < 100) {
      throw PdfAtomicWriteException(
          'Generated PDF file is abnormally small ($size bytes): $outputPath',
          targetPath: outputPath);
    }

    final pages = await _engine.inspectPageCount(outputPath);
    if (pages < expectedMinPages) {
      throw PdfInvalidDocumentException(
        'Generated PDF has $pages pages, but expected at least $expectedMinPages pages.',
        filePath: outputPath,
      );
    }
  }
}
