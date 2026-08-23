import '../exceptions/pdf_exception.dart';
import '../models/chunk_options.dart';
import '../models/document_ingestion_result.dart';
import '../models/document_source.dart';
import '../models/learning_document.dart';
import '../models/learning_page.dart';
import '../models/text_provenance.dart';
import 'pdf_chunk_service.dart';
import 'pdf_text_extractor.dart';
import 'pdf_validation_service.dart';

/// Central domain service interface for ingesting documents into normalized,
/// AI-ready [LearningDocument] instances with deterministic chunks and provenance.
abstract interface class DocumentIntelligenceService {
  /// Ingests a [DocumentSource], extracts text natively or via OCR fallback,
  /// normalizes content, creates structured [LearningPage]s, and segments into
  /// deterministic [LearningDocumentChunk]s.
  Future<DocumentIngestionResult> ingestDocument(
    DocumentSource source, {
    ChunkOptions options = const ChunkOptions(),
    bool forceOcr = false,
  });
}

/// Production implementation of [DocumentIntelligenceService].
class DefaultDocumentIntelligenceService
    implements DocumentIntelligenceService {
  final PdfTextExtractor _textExtractor;
  final PdfChunkService _chunkService;
  final PdfValidationService _validationService;

  const DefaultDocumentIntelligenceService({
    required PdfTextExtractor textExtractor,
    PdfChunkService chunkService = const PdfChunkService(),
    PdfValidationService validationService = const PdfValidationService(),
  })  : _textExtractor = textExtractor,
        _chunkService = chunkService,
        _validationService = validationService;

  @override
  Future<DocumentIngestionResult> ingestDocument(
    DocumentSource source, {
    ChunkOptions options = const ChunkOptions(),
    bool forceOcr = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    // 1. Pre-flight validation
    final isEncrypted = source.metadata['isEncrypted'] == true;
    final isCorrupted = source.metadata['isCorrupted'] == true;
    final isEmpty = source.metadata['isEmpty'] == true;

    try {
      _validationService.validatePdf(
        filePath: source.fileName,
        sizeBytes: source.sizeBytes,
        headerBytes: source.bytes != null && source.bytes!.length >= 4
            ? source.bytes!.sublist(0, 4)
            : null,
        isEncrypted: isEncrypted,
        isCorrupted: isCorrupted,
        isEmpty: isEmpty,
      );
    } on PdfValidationException catch (e) {
      stopwatch.stop();
      if (isEncrypted) {
        return DocumentIngestionResult.failure(
          status: DocumentIngestionStatus.encrypted,
          errorMessage: e.message,
          processingTime: stopwatch.elapsed,
        );
      }
      if (isCorrupted) {
        return DocumentIngestionResult.failure(
          status: DocumentIngestionStatus.corrupted,
          errorMessage: e.message,
          processingTime: stopwatch.elapsed,
        );
      }
      if (isEmpty) {
        return DocumentIngestionResult.failure(
          status: DocumentIngestionStatus.emptyDocument,
          errorMessage: e.message,
          processingTime: stopwatch.elapsed,
        );
      }
      return DocumentIngestionResult.failure(
        status: DocumentIngestionStatus.failed,
        errorMessage: e.message,
        processingTime: stopwatch.elapsed,
      );
    }

    try {
      // 2. Resolve page count
      final totalPages = await _textExtractor.getPageCount(source);
      if (totalPages <= 0) {
        stopwatch.stop();
        return DocumentIngestionResult.empty(
          message: 'Document has 0 pages.',
          processingTime: stopwatch.elapsed,
        );
      }

      // 3. Extract text page-by-page
      final learningPages = <LearningPage>[];
      var hasOcrFallback = false;
      var hasNativeText = false;
      final scriptCounts = <String, int>{};

      for (var pageNum = 1; pageNum <= totalPages; pageNum++) {
        final extracted = await _textExtractor.extractPageText(
          source: source,
          pageNumber: pageNum,
          forceOcr: forceOcr,
        );

        if (extracted.provenance == TextProvenance.ocr) {
          hasOcrFallback = true;
        } else if (extracted.text.trim().isNotEmpty) {
          hasNativeText = true;
        }

        scriptCounts[extracted.script] =
            (scriptCounts[extracted.script] ?? 0) + 1;

        learningPages.add(
          LearningPage(
            documentId: source.documentId,
            pageNumber: pageNum,
            text: extracted.text,
            provenance: extracted.provenance,
            script: extracted.script,
            confidence: extracted.confidence,
            characterCount: extracted.text.length,
            blocks: extracted.blocks,
          ),
        );
      }

      // Check if any text was extracted
      final hasAnyText = learningPages.any((p) => p.text.trim().isNotEmpty);
      if (!hasAnyText) {
        stopwatch.stop();
        return DocumentIngestionResult.empty(
          message:
              'Document was processed but yielded no extractable text content.',
          processingTime: stopwatch.elapsed,
        );
      }

      // Determine primary document language / script
      var primaryLanguage = source.languageCode ?? 'en';
      final hasBilingualScript = scriptCounts.containsKey('bilingual') ||
          (scriptCounts.containsKey('devanagari') &&
              scriptCounts.containsKey('latin'));
      if (hasBilingualScript) {
        primaryLanguage = 'bilingual';
      } else if (scriptCounts.containsKey('devanagari')) {
        primaryLanguage = 'hi';
      }

      // 4. Deterministic Chunking
      final chunks = _chunkService.chunkLearningPages(
        documentId: source.documentId,
        pages: learningPages,
        options: options,
      );

      if (hasOcrFallback && hasNativeText) {
        warnings.add(
            'Document contains mixed text extraction layers (native PDF + OCR fallback).');
      }

      final learningDoc = LearningDocument(
        id: source.documentId,
        fileName: source.fileName,
        displayName: source.displayName,
        totalPages: totalPages,
        sizeBytes: source.sizeBytes,
        primaryLanguage: primaryLanguage,
        createdAt: DateTime.now(),
        pages: List.unmodifiable(learningPages),
        chunks: List.unmodifiable(chunks),
        metadata: source.metadata,
      );

      stopwatch.stop();
      return DocumentIngestionResult.success(
        document: learningDoc,
        warnings: warnings,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return DocumentIngestionResult.failure(
        status: DocumentIngestionStatus.failed,
        errorMessage: 'Document ingestion failed: ${e.toString()}',
        warnings: warnings,
        processingTime: stopwatch.elapsed,
      );
    }
  }
}
