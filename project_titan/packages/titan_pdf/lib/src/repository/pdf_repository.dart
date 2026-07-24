import 'package:titan_domain/titan_domain.dart';

import '../models/chunk_options.dart';
import '../models/pdf_chunk.dart';
import '../models/pdf_document.dart';
import '../models/pdf_import_result.dart';
import '../models/pdf_metadata.dart';

/// Repository contract for managing PDF documents, text extraction, and chunk persistence in Project TITAN.
abstract class PdfRepository implements Repository<PdfDocument> {
  /// Imports and validates a PDF document from [filePath].
  Future<PdfImportResult> importPdf(
    String filePath, {
    String? displayName,
    int? sizeBytes,
    int? pageCount,
    PdfMetadata? metadata,
    List<int>? headerBytes,
    bool isEncrypted,
    bool isCorrupted,
    bool isEmpty,
  });

  /// Loads a [PdfDocument] by [documentId]. Returns null if not found.
  Future<PdfDocument?> loadPdf(String documentId);

  /// Deletes a PDF document and its associated chunks by [documentId].
  Future<void> deletePdf(String documentId);

  /// Returns a list of all imported [PdfDocument]s.
  Future<List<PdfDocument>> listDocuments();

  /// Extracts text content from [documentId].
  Future<String> extractText(String documentId);

  /// Segments extracted text from [documentId] into a list of [PdfChunk]s.
  Future<List<PdfChunk>> createChunks(
    String documentId, {
    ChunkOptions? options,
  });

  /// Persists [chunks] for [documentId].
  Future<void> saveChunks(String documentId, List<PdfChunk> chunks);
}
