import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/pdf_embedded_file.dart';
import '../services/pdf_attachment_service.dart';

/// Test override hook for checking file existence.
final attachmentFileExistsProvider =
    Provider<Future<bool> Function(String filePath)?>((ref) => null);

/// Test override hook for reading file bytes without disk I/O.
final attachmentReadFileBytesProvider =
    Provider<Future<Uint8List> Function(String filePath)?>((ref) => null);

/// Provider for the [PdfAttachmentService].
final pdfAttachmentServiceProvider = Provider<PdfAttachmentService>((ref) {
  final fileExists = ref.watch(attachmentFileExistsProvider);
  final readFileBytes = ref.watch(attachmentReadFileBytesProvider);
  return PdfAttachmentService(
    fileExists: fileExists,
    readFileBytes: readFileBytes,
  );
});

/// FutureProvider loading the list of attachments for a specific PDF [filePath].
final attachmentsForDocumentProvider =
    FutureProvider.family<List<PdfEmbeddedFile>, String>((ref, filePath) async {
  final service = ref.watch(pdfAttachmentServiceProvider);
  return service.listAttachments(filePath: filePath);
});
