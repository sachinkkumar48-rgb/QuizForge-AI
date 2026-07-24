import '../../models/validation_report.dart';

/// Contract for dataset parsing, schema validation, and module data importing.
abstract class ModuleImporter {
  /// Name or description of supported import formats (e.g. JSON, PDF, CSV, Digest).
  String get supportedFormat;

  /// Validate raw payload or content string against the module's schema.
  Future<ValidationReport> validateDataset(String content);

  /// Import dataset content into storage.
  /// Returns the number of successfully imported items.
  Future<int> importDataset(
    String content, {
    ImportMode importMode = ImportMode.safe,
  });

  /// Sample template paths or instructions for importing.
  List<String> getSampleTemplates();
}
