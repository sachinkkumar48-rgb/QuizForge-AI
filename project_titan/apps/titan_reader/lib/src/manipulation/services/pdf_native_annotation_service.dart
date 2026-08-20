import 'dart:io';
import '../../domain/entities/pdf_native_annotation.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../../services/reader_undo_stack.dart';
import '../engine/default_pdf_native_annotation_engine.dart';
import '../engine/pdf_native_annotation_engine.dart';

/// Orchestrates PDF-native annotation persistence, non-destructive export,
/// and Reader-scoped undo/redo operations.
class PdfNativeAnnotationService {
  final PdfNativeAnnotationEngine engine;
  final ReaderUndoStack undoStack;

  PdfNativeAnnotationService({
    PdfNativeAnnotationEngine? engine,
    ReaderUndoStack? undoStack,
  })  : engine = engine ?? const DefaultPdfNativeAnnotationEngine(),
        undoStack = undoStack ?? ReaderUndoStack();

  /// Loads all native annotations from [pdfPath].
  Future<List<PdfNativeAnnotation>> loadAnnotations(
    String pdfPath, {
    int? pageIndex,
  }) async {
    _assertFileExists(pdfPath);
    return engine.loadAnnotations(pdfPath, pageIndex: pageIndex);
  }

  /// Adds [annotation] to [sourcePath] with undo/redo support.
  Future<void> addAnnotation({
    required String sourcePath,
    required PdfNativeAnnotation annotation,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;

    if (engine is DefaultPdfNativeAnnotationEngine) {
      final defaultEngine = engine as DefaultPdfNativeAnnotationEngine;
      undoStack.perform(ReaderOperation(
        label: 'Add Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          defaultEngine.addAnnotationSync(sourcePath, annotation,
              outputPath: outputPath);
        },
        revert: () {
          defaultEngine.deleteAnnotationSync(outputPath, annotation.id,
              outputPath: outputPath);
        },
      ));
    } else {
      await engine.addAnnotation(sourcePath, annotation,
          outputPath: outputPath);
      undoStack.perform(ReaderOperation(
        label: 'Add Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          engine.addAnnotation(sourcePath, annotation, outputPath: outputPath);
        },
        revert: () {
          engine.deleteAnnotation(outputPath, annotation.id,
              outputPath: outputPath);
        },
      ));
    }
  }

  /// Updates [annotation] in [sourcePath] with undo/redo support.
  Future<void> updateAnnotation({
    required String sourcePath,
    required PdfNativeAnnotation annotation,
    required PdfNativeAnnotation previousAnnotation,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;

    if (engine is DefaultPdfNativeAnnotationEngine) {
      final defaultEngine = engine as DefaultPdfNativeAnnotationEngine;
      undoStack.perform(ReaderOperation(
        label: 'Update Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          defaultEngine.updateAnnotationSync(sourcePath, annotation,
              outputPath: outputPath);
        },
        revert: () {
          defaultEngine.updateAnnotationSync(outputPath, previousAnnotation,
              outputPath: outputPath);
        },
      ));
    } else {
      await engine.updateAnnotation(sourcePath, annotation,
          outputPath: outputPath);
      undoStack.perform(ReaderOperation(
        label: 'Update Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          engine.updateAnnotation(sourcePath, annotation,
              outputPath: outputPath);
        },
        revert: () {
          engine.updateAnnotation(outputPath, previousAnnotation,
              outputPath: outputPath);
        },
      ));
    }
  }

  /// Deletes [annotation] from [sourcePath] with undo/redo support.
  Future<void> deleteAnnotation({
    required String sourcePath,
    required PdfNativeAnnotation annotation,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final outputPath = customOutputPath ?? sourcePath;

    if (engine is DefaultPdfNativeAnnotationEngine) {
      final defaultEngine = engine as DefaultPdfNativeAnnotationEngine;
      undoStack.perform(ReaderOperation(
        label: 'Delete Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          defaultEngine.deleteAnnotationSync(sourcePath, annotation.id,
              outputPath: outputPath);
        },
        revert: () {
          defaultEngine.addAnnotationSync(outputPath, annotation,
              outputPath: outputPath);
        },
      ));
    } else {
      await engine.deleteAnnotation(sourcePath, annotation.id,
          outputPath: outputPath);
      undoStack.perform(ReaderOperation(
        label: 'Delete Native ${annotation.subtype}',
        scope: 'native_annotations',
        apply: () {
          engine.deleteAnnotation(sourcePath, annotation.id,
              outputPath: outputPath);
        },
        revert: () {
          engine.addAnnotation(outputPath, annotation, outputPath: outputPath);
        },
      ));
    }
  }

  /// Exports [sourcePath] with [annotations] to a newly generated safe output file.
  Future<String> exportAnnotatedPdf({
    required String sourcePath,
    required List<PdfNativeAnnotation> annotations,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final targetPath =
        customOutputPath ?? generateAnnotatedOutputPath(sourcePath);
    await engine.exportWithNativeAnnotations(
        sourcePath, annotations, targetPath);
    return targetPath;
  }

  /// Flattens annotations in [sourcePath] to a new flattened PDF file.
  Future<String> flattenAnnotatedPdf({
    required String sourcePath,
    List<String>? annotationIds,
    String? customOutputPath,
  }) async {
    _assertFileExists(sourcePath);
    final targetPath =
        customOutputPath ?? generateFlattenedOutputPath(sourcePath);
    await engine.flattenAnnotations(sourcePath,
        annotationIds: annotationIds, outputPath: targetPath);
    return targetPath;
  }

  /// Generates a non-destructive filename `original_annotated.pdf` or `original_annotated_1.pdf`.
  String generateAnnotatedOutputPath(String sourcePath) {
    final file = File(sourcePath);
    final dir = file.parent.path;
    final base = file.uri.pathSegments.last.replaceAll('.pdf', '');

    var candidate = '$dir/${base}_annotated.pdf';
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = '$dir/${base}_annotated_$counter.pdf';
      counter++;
    }
    return candidate;
  }

  /// Generates a non-destructive filename `original_flattened.pdf`.
  String generateFlattenedOutputPath(String sourcePath) {
    final file = File(sourcePath);
    final dir = file.parent.path;
    final base = file.uri.pathSegments.last.replaceAll('.pdf', '');

    var candidate = '$dir/${base}_flattened.pdf';
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = '$dir/${base}_flattened_$counter.pdf';
      counter++;
    }
    return candidate;
  }

  void _assertFileExists(String path) {
    if (!File(path).existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $path',
          filePath: path);
    }
  }
}
