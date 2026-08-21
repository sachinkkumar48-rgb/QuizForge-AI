import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/print_service.dart';

/// Provider for the platform-level PDF print adapter.
/// Overridable in widget and integration tests with mock/fake implementations.
final pdfPrintAdapterProvider = Provider<PdfPrintAdapter>((ref) {
  return const PlatformPdfPrintAdapter();
});

/// Predicate provider for checking file existence without hitting real disk in test harnesses.
final printFileExistsProvider =
    Provider<Future<bool> Function(String filePath)?>((ref) => null);

/// Provider for the high-level [PrintService].
final printServiceProvider = Provider<PrintService>((ref) {
  final adapter = ref.watch(pdfPrintAdapterProvider);
  final fileExists = ref.watch(printFileExistsProvider);
  return PrintService(adapter, fileExists: fileExists);
});
