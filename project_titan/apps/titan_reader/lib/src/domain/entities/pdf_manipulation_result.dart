import 'package:meta/meta.dart';

/// Result summary of a completed PDF manipulation operation.
@immutable
class PdfManipulationResult {
  /// Path to the generated output file(s).
  final List<String> outputPaths;

  /// Total number of pages in the primary output document.
  final int pageCount;

  /// Output file size in bytes.
  final int fileSizeBytes;

  /// Identifier of the operation performed (e.g., 'merge', 'split', 'rotate', 'delete').
  final String operationType;

  /// Duration taken to execute the operation.
  final Duration elapsed;

  const PdfManipulationResult({
    required this.outputPaths,
    required this.pageCount,
    required this.fileSizeBytes,
    required this.operationType,
    required this.elapsed,
  });

  /// Convenient getter for single output path.
  String get primaryOutputPath =>
      outputPaths.isNotEmpty ? outputPaths.first : '';

  @override
  String toString() =>
      'PdfManipulationResult($operationType: ${outputPaths.length} file(s), $pageCount pages, $fileSizeBytes bytes, ${elapsed.inMilliseconds}ms)';
}
