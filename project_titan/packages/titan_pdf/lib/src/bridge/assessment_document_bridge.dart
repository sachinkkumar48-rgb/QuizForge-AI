import '../models/learning_document.dart';
import '../models/learning_document_chunk.dart';
import '../models/pdf_chunk.dart';
import '../models/pdf_document.dart';
import '../repository/pdf_repository.dart';

/// Bridge adapter facilitating seamless interoperability between the TITAN Document Intelligence
/// pipeline ([LearningDocument], [LearningDocumentChunk]) and QuizForge AI assessment systems.
class AssessmentDocumentBridge {
  const AssessmentDocumentBridge._();

  /// Converts a list of [LearningDocumentChunk]s into legacy [PdfChunk]s for backward compatibility.
  static List<PdfChunk> toPdfChunks(List<LearningDocumentChunk> chunks) {
    return chunks.map((c) => c.toPdfChunk()).toList();
  }

  /// Converts legacy [PdfChunk]s into [LearningDocumentChunk]s.
  static List<LearningDocumentChunk> fromPdfChunks(List<PdfChunk> chunks) {
    return chunks.map((c) => LearningDocumentChunk.fromPdfChunk(c)).toList();
  }

  /// Registers a [LearningDocument] into a [PdfRepository], ensuring its metadata,
  /// raw text, and structured chunks are persistently queryable by QuizForge AI pipelines.
  static Future<PdfDocument> registerLearningDocument({
    required LearningDocument document,
    required PdfRepository pdfRepository,
  }) async {
    final pdfDoc = document.toPdfDocument();

    // Persist document record
    final importResult = await pdfRepository.importPdf(
      document.fileName,
      displayName: document.displayName,
      sizeBytes: document.sizeBytes,
      pageCount: document.totalPages,
      metadata: pdfDoc.metadata,
    );

    // Save corresponding chunks
    if (document.chunks.isNotEmpty) {
      final legacyChunks = toPdfChunks(document.chunks);
      await pdfRepository.saveChunks(importResult.document.id, legacyChunks);
    }

    return importResult.document;
  }
}
