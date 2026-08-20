import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/pdf_form_field.dart';
import '../manipulation/engine/default_pdf_form_engine.dart';
import '../manipulation/engine/pdf_form_engine.dart';
import '../manipulation/services/pdf_form_service.dart';

/// Provider for the pure Dart AST AcroForm engine.
final pdfFormEngineProvider = Provider<PdfFormEngine>((ref) {
  return const DefaultPdfFormEngine();
});

/// Provider for the AcroForm application service.
final pdfFormServiceProvider = Provider<PdfFormService>((ref) {
  final engine = ref.watch(pdfFormEngineProvider);
  return PdfFormService(engine: engine);
});

/// Provider family for loading and caching a document's form structure.
final documentFormProvider =
    FutureProvider.family<PdfFormDocument, String>((ref, pdfPath) async {
  final service = ref.watch(pdfFormServiceProvider);
  return service.loadForm(pdfPath);
});

/// State provider for tracking the currently focused form field ID.
final activeFormFieldIdProvider = StateProvider<String?>((ref) => null);
