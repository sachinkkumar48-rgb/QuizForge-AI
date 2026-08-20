import 'dart:typed_data';
import '../../domain/entities/pdf_form_field.dart';

/// Contract interface for AcroForm extraction, mutation, persistence, and flattening.
abstract class PdfFormEngine {
  /// Extracts the complete form schema and fields from [pdfPath].
  Future<PdfFormDocument> loadForm(String pdfPath);

  /// Updates a single field value in [sourcePath], writing to [outputPath] (or replacing [sourcePath]).
  Future<void> updateFieldValue(
    String sourcePath,
    String fieldIdentifier,
    dynamic newValue, {
    String? outputPath,
  });

  /// Persists a batch map of field identifier -> new value into [sourcePath].
  Future<void> saveFormValues(
    String sourcePath,
    Map<String, dynamic> fieldValues, {
    String? outputPath,
  });

  /// Resets all form fields in [sourcePath] to default or blank states.
  Future<void> resetForm(
    String sourcePath, {
    String? outputPath,
  });

  /// Flattens form fields permanently into page content streams.
  Future<void> flattenForm(
    String sourcePath, {
    String? outputPath,
  });

  /// Exports form data from [sourcePath] as an FDF file at [fdfOutputPath].
  Future<void> exportFdf(
    String sourcePath,
    String fdfOutputPath,
  );

  /// Imports FDF bytes into [sourcePath].
  Future<void> importFdf(
    String sourcePath,
    Uint8List fdfBytes, {
    String? outputPath,
  });
}
