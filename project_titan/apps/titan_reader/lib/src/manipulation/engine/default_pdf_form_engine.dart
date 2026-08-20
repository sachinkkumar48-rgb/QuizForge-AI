import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/pdf_form_field.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../ast/pdf_fdf_serializer.dart';
import '../ast/pdf_form_builder.dart';
import '../ast/pdf_form_parser.dart';
import '../ast/pdf_parser.dart';
import '../ast/pdf_writer.dart';
import 'pdf_form_engine.dart';

/// Pure Dart AST implementation of [PdfFormEngine].
class DefaultPdfFormEngine implements PdfFormEngine {
  const DefaultPdfFormEngine();

  PdfFormDocument loadFormSync(String pdfPath) {
    final file = File(pdfPath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $pdfPath',
          filePath: pdfPath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();
    return PdfFormParser.parseDocumentForm(ast);
  }

  @override
  Future<PdfFormDocument> loadForm(String pdfPath) async {
    return loadFormSync(pdfPath);
  }

  void updateFieldValueSync(
    String sourcePath,
    String fieldIdentifier,
    dynamic newValue, {
    String? outputPath,
  }) {
    saveFormValuesSync(sourcePath, {fieldIdentifier: newValue},
        outputPath: outputPath);
  }

  @override
  Future<void> updateFieldValue(
    String sourcePath,
    String fieldIdentifier,
    dynamic newValue, {
    String? outputPath,
  }) async {
    updateFieldValueSync(sourcePath, fieldIdentifier, newValue,
        outputPath: outputPath);
  }

  void saveFormValuesSync(
    String sourcePath,
    Map<String, dynamic> fieldValues, {
    String? outputPath,
  }) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $sourcePath',
          filePath: sourcePath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();
    final formDoc = PdfFormParser.parseDocumentForm(ast);

    for (final entry in fieldValues.entries) {
      final field = formDoc.findField(entry.key);
      if (field != null) {
        PdfFormBuilder.updateFieldValue(ast, field, entry.value);
      }
    }

    final targetPath = outputPath ?? sourcePath;
    PdfWriter(ast).writeAtomicSync(targetPath);
  }

  @override
  Future<void> saveFormValues(
    String sourcePath,
    Map<String, dynamic> fieldValues, {
    String? outputPath,
  }) async {
    saveFormValuesSync(sourcePath, fieldValues, outputPath: outputPath);
  }

  void resetFormSync(
    String sourcePath, {
    String? outputPath,
  }) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $sourcePath',
          filePath: sourcePath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();
    final formDoc = PdfFormParser.parseDocumentForm(ast);

    PdfFormBuilder.resetForm(ast, formDoc.fields);

    final targetPath = outputPath ?? sourcePath;
    PdfWriter(ast).writeAtomicSync(targetPath);
  }

  @override
  Future<void> resetForm(
    String sourcePath, {
    String? outputPath,
  }) async {
    resetFormSync(sourcePath, outputPath: outputPath);
  }

  void flattenFormSync(
    String sourcePath, {
    String? outputPath,
  }) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $sourcePath',
          filePath: sourcePath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();
    final formDoc = PdfFormParser.parseDocumentForm(ast);

    PdfFormBuilder.flattenForm(ast, formDoc.fields);

    final targetPath = outputPath ?? sourcePath;
    PdfWriter(ast).writeAtomicSync(targetPath);
  }

  @override
  Future<void> flattenForm(
    String sourcePath, {
    String? outputPath,
  }) async {
    flattenFormSync(sourcePath, outputPath: outputPath);
  }

  void exportFdfSync(
    String sourcePath,
    String fdfOutputPath,
  ) {
    final formDoc = loadFormSync(sourcePath);
    final fdfBytes = PdfFdfSerializer.exportToFdf(formDoc,
        pdfFilePath: File(sourcePath).uri.pathSegments.last);
    final outFile = File(fdfOutputPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(fdfBytes, flush: true);
  }

  @override
  Future<void> exportFdf(
    String sourcePath,
    String fdfOutputPath,
  ) async {
    exportFdfSync(sourcePath, fdfOutputPath);
  }

  void importFdfSync(
    String sourcePath,
    Uint8List fdfBytes, {
    String? outputPath,
  }) {
    final importedValues = PdfFdfSerializer.importFromFdf(fdfBytes);
    saveFormValuesSync(sourcePath, importedValues, outputPath: outputPath);
  }

  @override
  Future<void> importFdf(
    String sourcePath,
    Uint8List fdfBytes, {
    String? outputPath,
  }) async {
    importFdfSync(sourcePath, fdfBytes, outputPath: outputPath);
  }
}
