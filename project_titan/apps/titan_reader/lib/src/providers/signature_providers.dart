import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/pdf_visual_signature.dart';
import '../services/signature_service.dart';
import 'reader_providers.dart';

/// Provides the singleton [SignatureService] instance bound to the active [StorageService].
final Provider<SignatureService> signatureServiceProvider =
    Provider<SignatureService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SignatureService(storage);
});

/// Asynchronously provides all saved visual signatures.
final FutureProvider<List<PdfVisualSignature>> signaturesListProvider =
    FutureProvider<List<PdfVisualSignature>>((ref) async {
  final service = ref.watch(signatureServiceProvider);
  return service.ensureLoaded();
});
