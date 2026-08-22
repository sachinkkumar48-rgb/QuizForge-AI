import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pdf_encryption_service.dart';

/// Predicate provider for checking file existence without hitting disk in widget tests.
final encryptionFileExistsProvider =
    Provider<Future<bool> Function(String filePath)?>((ref) => null);

/// Provider for the [PdfEncryptionService].
final pdfEncryptionServiceProvider = Provider<PdfEncryptionService>((ref) {
  final fileExists = ref.watch(encryptionFileExistsProvider);
  return PdfEncryptionService(fileExists: fileExists);
});
