import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../manipulation/engine/default_pdf_native_annotation_engine.dart';
import '../manipulation/engine/pdf_native_annotation_engine.dart';
import '../manipulation/services/pdf_native_annotation_service.dart';

/// Provider for the lower-level PDF native annotation engine.
final pdfNativeAnnotationEngineProvider =
    Provider<PdfNativeAnnotationEngine>((ref) {
  return const DefaultPdfNativeAnnotationEngine();
});

/// Provider for the high-level PDF native annotation service.
final pdfNativeAnnotationServiceProvider =
    Provider<PdfNativeAnnotationService>((ref) {
  final engine = ref.watch(pdfNativeAnnotationEngineProvider);
  return PdfNativeAnnotationService(engine: engine);
});
