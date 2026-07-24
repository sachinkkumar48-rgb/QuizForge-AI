import 'package:meta/meta.dart';
import 'pdf_document.dart';

/// Immutable model representing the result of a PDF document import attempt.
@immutable
class PdfImportResult {
  final PdfDocument document;
  final List<String> warnings;
  final List<String> errors;

  PdfImportResult({
    required this.document,
    List<String>? warnings,
    List<String>? errors,
  })  : warnings = List<String>.unmodifiable(warnings ?? const []),
        errors = List<String>.unmodifiable(errors ?? const []);

  bool get isSuccess => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfImportResult &&
          runtimeType == other.runtimeType &&
          document == other.document &&
          warnings == other.warnings &&
          errors == other.errors;

  @override
  int get hashCode => document.hashCode ^ warnings.hashCode ^ errors.hashCode;

  @override
  String toString() =>
      'PdfImportResult(doc: ${document.id}, success: $isSuccess, warnings: ${warnings.length}, errors: ${errors.length})';
}
