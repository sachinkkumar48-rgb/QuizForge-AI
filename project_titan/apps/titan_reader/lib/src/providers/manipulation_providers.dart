import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_pdf/titan_pdf.dart';
import '../manipulation/engine/pdf_manipulation_engine.dart';
import '../manipulation/engine/default_pdf_manipulation_engine.dart';
import '../manipulation/services/pdf_document_manipulation_service.dart';

/// Provider for the lower-level PDF manipulation engine.
final pdfManipulationEngineProvider = Provider<PdfManipulationEngine>((ref) {
  return const DefaultPdfManipulationEngine();
});

/// Provider for the high-level PDF document manipulation service.
final pdfManipulationServiceProvider =
    Provider<PdfDocumentManipulationService>((ref) {
  final engine = ref.watch(pdfManipulationEngineProvider);
  return PdfDocumentManipulationService(
    engine: engine,
    validator: const PdfValidationService(),
  );
});
