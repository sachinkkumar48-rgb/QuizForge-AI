import '../../domain/entities/pdf_native_annotation.dart';

/// Contract interface for PDF-native annotation manipulation and persistence.
abstract class PdfNativeAnnotationEngine {
  /// Loads all native annotations from [pdfPath]. If [pageIndex] is specified,
  /// loads only annotations on that 0-based page.
  Future<List<PdfNativeAnnotation>> loadAnnotations(
    String pdfPath, {
    int? pageIndex,
  });

  /// Adds a [annotation] to [sourcePath], writing output to [outputPath] (or replacing [sourcePath] if omitted).
  Future<void> addAnnotation(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  });

  /// Updates an existing [annotation] in [sourcePath].
  Future<void> updateAnnotation(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  });

  /// Deletes the annotation identified by [annotationId] from [sourcePath].
  Future<void> deleteAnnotation(
    String sourcePath,
    String annotationId, {
    String? outputPath,
  });

  /// Persists a full list of [annotations] into [sourcePath].
  Future<void> saveAllAnnotations(
    String sourcePath,
    List<PdfNativeAnnotation> annotations, {
    String? outputPath,
  });

  /// Exports [sourcePath] with [annotations] embedded to a new [outputPath].
  Future<void> exportWithNativeAnnotations(
    String sourcePath,
    List<PdfNativeAnnotation> annotations,
    String outputPath,
  );

  /// Flattens annotations into page contents streams. If [annotationIds] is omitted,
  /// flattens all supported annotations.
  Future<void> flattenAnnotations(
    String sourcePath, {
    List<String>? annotationIds,
    String? outputPath,
  });
}
