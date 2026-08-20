import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/entities/pdf_manipulation_result.dart';
import '../../domain/entities/pdf_page_label_config.dart';
import '../../domain/entities/pdf_page_range.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../ast/pdf_document_ast.dart';
import '../ast/pdf_parser.dart';
import '../ast/pdf_writer.dart';
import 'pdf_manipulation_engine.dart';

/// Default pure Dart implementation of [PdfManipulationEngine] backed by the TITAN AST parser and writer.
class DefaultPdfManipulationEngine implements PdfManipulationEngine {
  const DefaultPdfManipulationEngine();

  Future<PdfDocumentAst> _loadAst(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw PdfInvalidDocumentException('File does not exist: $filePath',
          filePath: filePath);
    }
    final bytes = await file.readAsBytes();
    final parser = PdfParser(bytes);
    return parser.parse();
  }

  @override
  Future<PdfManipulationResult> merge({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    if (inputPaths.length < 2) {
      throw const PdfManipulationException(
          'Merge operation requires at least two input PDF files.');
    }

    // 1. Load first PDF as base AST
    final baseAst = await _loadAst(inputPaths.first);

    // 2. Append all subsequent PDFs
    for (var i = 1; i < inputPaths.length; i++) {
      final docAst = await _loadAst(inputPaths[i]);
      final allDocPages =
          List<int>.generate(docAst.pageCount, (index) => index);
      baseAst.insertPagesFrom(docAst, allDocPages, baseAst.pageCount);
    }

    // 3. Write out merged document
    final writer = PdfWriter(baseAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: baseAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'merge',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> split({
    required String inputPath,
    required List<PdfPageRange> ranges,
    required String outputDirectory,
    required String baseName,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);
    final outputPaths = <String>[];
    var totalPages = 0;

    final outDir = Directory(outputDirectory);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    for (var i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final zeroBasedPages = range.toPageList().map((p) => p - 1).toList();

      for (final pNum in zeroBasedPages) {
        if (pNum < 0 || pNum >= sourceAst.pageCount) {
          throw PdfPageRangeOutOfBoundsException(
            'Split range $range exceeds document page count (${sourceAst.pageCount})',
            requestedPage: pNum + 1,
            maxPages: sourceAst.pageCount,
          );
        }
      }

      final subAst = sourceAst.extractSubDocument(zeroBasedPages);
      final padNum = (i + 1).toString().padLeft(3, '0');
      final rangeStr = range.startPage == range.endPage
          ? 'p${range.startPage}'
          : 'p${range.startPage}-${range.endPage}';
      final fileName = '${baseName}_part${padNum}_$rangeStr.pdf';
      final partPath = p.join(outputDirectory, fileName);

      final writer = PdfWriter(subAst);
      final partFile = await writer.writeAtomic(partPath);
      outputPaths.add(partFile.path);
      totalPages += subAst.pageCount;
    }

    sw.stop();

    var totalBytes = 0;
    for (final path in outputPaths) {
      totalBytes += await File(path).length();
    }

    return PdfManipulationResult(
      outputPaths: outputPaths,
      pageCount: totalPages,
      fileSizeBytes: totalBytes,
      operationType: 'split',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> extractPages({
    required String inputPath,
    required List<int> pages,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    if (pages.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'No pages specified for extraction.');
    }

    final sourceAst = await _loadAst(inputPath);
    final zeroBased = pages.map((p) => p - 1).toList();

    for (final pNum in zeroBased) {
      if (pNum < 0 || pNum >= sourceAst.pageCount) {
        throw PdfPageRangeOutOfBoundsException(
          'Extract page ${pNum + 1} is out of document range (1..${sourceAst.pageCount})',
          requestedPage: pNum + 1,
          maxPages: sourceAst.pageCount,
        );
      }
    }

    final extractedAst = sourceAst.extractSubDocument(zeroBased);
    final writer = PdfWriter(extractedAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: extractedAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'extract',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> deletePages({
    required String inputPath,
    required List<int> pagesToDelete,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);
    final zeroBased = pagesToDelete.map((p) => p - 1).toList();

    sourceAst.deletePages(zeroBased);

    final writer = PdfWriter(sourceAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: sourceAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'delete',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> reorderPages({
    required String inputPath,
    required List<int> newOrder,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);
    final zeroBased = newOrder.map((p) => p - 1).toList();

    sourceAst.reorderPages(zeroBased);

    final writer = PdfWriter(sourceAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: sourceAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'reorder',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> rotatePages({
    required String inputPath,
    required Map<int, int> pageRotations,
    required String outputPath,
    bool relative = true,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);

    for (final entry in pageRotations.entries) {
      final pageNum = entry.key;
      final deg = entry.value;
      final zeroIndex = pageNum - 1;
      if (zeroIndex >= 0 && zeroIndex < sourceAst.pageCount) {
        sourceAst.rotatePage(zeroIndex, deg, relative: relative);
      }
    }

    final writer = PdfWriter(sourceAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: sourceAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'rotate',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> insertBlankPage({
    required String inputPath,
    required int targetIndex,
    double width = 595.0,
    double height = 842.0,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);
    final zeroIndex = (targetIndex - 1).clamp(0, sourceAst.pageCount);

    sourceAst.insertBlankPage(zeroIndex, width: width, height: height);

    final writer = PdfWriter(sourceAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: sourceAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'insertBlank',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> insertPagesFromPdf({
    required String targetPath,
    required int targetIndex,
    required String sourcePath,
    required List<int> sourcePages,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    final targetAst = await _loadAst(targetPath);
    final sourceAst = await _loadAst(sourcePath);

    final zeroIndex = (targetIndex - 1).clamp(0, targetAst.pageCount);
    final sourceZeroBased = sourcePages.isNotEmpty
        ? sourcePages.map((p) => p - 1).toList()
        : List<int>.generate(sourceAst.pageCount, (i) => i);

    targetAst.insertPagesFrom(sourceAst, sourceZeroBased, zeroIndex);

    final writer = PdfWriter(targetAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: targetAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'insertFromPdf',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<PdfManipulationResult> setPageLabels({
    required String inputPath,
    required List<PdfPageLabelRange> labelRanges,
    required String outputPath,
  }) async {
    final sw = Stopwatch()..start();
    final sourceAst = await _loadAst(inputPath);

    sourceAst.setPageLabels(labelRanges);

    final writer = PdfWriter(sourceAst);
    final outFile = await writer.writeAtomic(outputPath);
    sw.stop();

    return PdfManipulationResult(
      outputPaths: [outFile.path],
      pageCount: sourceAst.pageCount,
      fileSizeBytes: await outFile.length(),
      operationType: 'pageLabels',
      elapsed: sw.elapsed,
    );
  }

  @override
  Future<int> inspectPageCount(String inputPath) async {
    final ast = await _loadAst(inputPath);
    return ast.pageCount;
  }
}
