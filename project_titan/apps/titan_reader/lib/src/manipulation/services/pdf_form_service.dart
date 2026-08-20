import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/pdf_form_field.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../../services/reader_undo_stack.dart';
import '../ast/pdf_fdf_serializer.dart';
import '../engine/default_pdf_form_engine.dart';
import '../engine/pdf_form_engine.dart';

/// Orchestrates AcroForm operations, field validation, FDF/JSON I/O,
/// and Reader-scoped undo/redo operations.
class PdfFormService {
  final PdfFormEngine engine;
  final ReaderUndoStack undoStack;

  PdfFormService({
    PdfFormEngine? engine,
    ReaderUndoStack? undoStack,
  })  : engine = engine ?? const DefaultPdfFormEngine(),
        undoStack = undoStack ?? ReaderUndoStack();

  /// Loads form document and all fields from [pdfPath].
  Future<PdfFormDocument> loadForm(String pdfPath) async {
    _assertFileExists(pdfPath);
    return engine.loadForm(pdfPath);
  }

  /// Updates a single field value with undo/redo rollback support.
  Future<void> updateFieldValue({
    required String sourcePath,
    required String fieldIdentifier,
    required dynamic newValue,
    dynamic previousValue,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;

    if (engine is DefaultPdfFormEngine) {
      final defaultEngine = engine as DefaultPdfFormEngine;
      undoStack.perform(ReaderOperation(
        label: 'Update Form Field $fieldIdentifier',
        scope: 'acro_forms',
        apply: () {
          defaultEngine.updateFieldValueSync(
            sourcePath,
            fieldIdentifier,
            newValue,
            outputPath: outputPath,
          );
        },
        revert: () {
          if (previousValue != null) {
            defaultEngine.updateFieldValueSync(
              outputPath,
              fieldIdentifier,
              previousValue,
              outputPath: outputPath,
            );
          }
        },
      ));
    } else {
      await engine.updateFieldValue(sourcePath, fieldIdentifier, newValue,
          outputPath: outputPath);
    }
  }

  /// Saves batch form values with undo/redo support.
  Future<void> saveFormValues({
    required String sourcePath,
    required Map<String, dynamic> values,
    Map<String, dynamic>? previousValues,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;

    if (engine is DefaultPdfFormEngine) {
      final defaultEngine = engine as DefaultPdfFormEngine;
      undoStack.perform(ReaderOperation(
        label: 'Save Form Values',
        scope: 'acro_forms',
        apply: () {
          defaultEngine.saveFormValuesSync(sourcePath, values,
              outputPath: outputPath);
        },
        revert: () {
          if (previousValues != null && previousValues.isNotEmpty) {
            defaultEngine.saveFormValuesSync(outputPath, previousValues,
                outputPath: outputPath);
          }
        },
      ));
    } else {
      await engine.saveFormValues(sourcePath, values, outputPath: outputPath);
    }
  }

  /// Validates document form fields against constraints (e.g. required, maxLength).
  PdfFormValidationResult validateForm(PdfFormDocument formDoc) {
    final errors = <PdfFormFieldValidationError>[];

    for (final field in formDoc.fields) {
      if (field.isRequired && !field.hasValue) {
        errors.add(PdfFormFieldValidationError(
          fieldId: field.id,
          fullyQualifiedName: field.fullyQualifiedName,
          message: 'This field is required.',
        ));
      }

      if (field is PdfTextFormField && field.maxLength != null) {
        if (field.text.length > field.maxLength!) {
          errors.add(PdfFormFieldValidationError(
            fieldId: field.id,
            fullyQualifiedName: field.fullyQualifiedName,
            message:
                'Text exceeds maximum allowed length of ${field.maxLength} characters.',
          ));
        }
      }
    }

    return PdfFormValidationResult.fromErrors(errors);
  }

  /// Resets all fields in [sourcePath] to their default or empty state.
  Future<void> resetForm({
    required String sourcePath,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;
    await engine.resetForm(sourcePath, outputPath: outputPath);
  }

  /// Flattens all interactive form fields into page content streams.
  Future<void> flattenForm({
    required String sourcePath,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? getFormFlattenedPath(sourcePath);
    await engine.flattenForm(sourcePath, outputPath: outputPath);
  }

  /// Exports form data as standard FDF bytes to [outputPath].
  Future<void> exportFdf({
    required String sourcePath,
    required String outputPath,
  }) async {
    _assertFileExists(sourcePath);
    await engine.exportFdf(sourcePath, outputPath);
  }

  /// Imports FDF bytes into [sourcePath].
  Future<void> importFdf({
    required String sourcePath,
    required Uint8List fdfBytes,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;
    await engine.importFdf(sourcePath, fdfBytes, outputPath: outputPath);
  }

  /// Exports form data as structured JSON string to [outputPath].
  Future<void> exportJson({
    required String sourcePath,
    required String outputPath,
  }) async {
    _assertFileExists(sourcePath);
    final formDoc = await engine.loadForm(sourcePath);
    final jsonStr = PdfFdfSerializer.exportToJson(formDoc);
    final outFile = File(outputPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonStr, flush: true);
  }

  /// Imports JSON string into [sourcePath].
  Future<void> importJson({
    required String sourcePath,
    required String jsonString,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;
    final map = PdfFdfSerializer.importFromJson(jsonString);
    await engine.saveFormValues(sourcePath, map, outputPath: outputPath);
  }

  /// Derives default flattened export path (e.g. `doc_flat.pdf`).
  String getFormFlattenedPath(String sourcePath) {
    final dotIdx = sourcePath.lastIndexOf('.');
    if (dotIdx == -1) return '${sourcePath}_flat.pdf';
    return '${sourcePath.substring(0, dotIdx)}_flat.pdf';
  }

  /// Derives default filled copy path (e.g. `doc_filled.pdf`).
  String getFormFilledPath(String sourcePath) {
    final dotIdx = sourcePath.lastIndexOf('.');
    if (dotIdx == -1) return '${sourcePath}_filled.pdf';
    return '${sourcePath.substring(0, dotIdx)}_filled.pdf';
  }

  /// Derives default FDF export path (e.g. `doc.fdf`).
  String getFdfPath(String sourcePath) {
    final dotIdx = sourcePath.lastIndexOf('.');
    if (dotIdx == -1) return '$sourcePath.fdf';
    return '${sourcePath.substring(0, dotIdx)}.fdf';
  }

  /// Derives default JSON export path (e.g. `doc_form.json`).
  String getJsonPath(String sourcePath) {
    final dotIdx = sourcePath.lastIndexOf('.');
    if (dotIdx == -1) return '${sourcePath}_form.json';
    return '${sourcePath.substring(0, dotIdx)}_form.json';
  }

  void _assertFileExists(String path) {
    if (!File(path).existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $path',
          filePath: path);
    }
  }
}
