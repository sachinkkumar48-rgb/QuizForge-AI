import 'package:titan_domain/titan_domain.dart';

import '../exceptions/pdf_exception.dart';
import '../models/chunk_options.dart';
import '../models/pdf_chunk.dart';
import '../models/pdf_document.dart';
import '../models/pdf_import_result.dart';
import '../models/pdf_metadata.dart';
import '../services/pdf_chunk_service.dart';
import '../services/pdf_import_service.dart';
import 'pdf_repository.dart';

/// Concrete implementation of [PdfRepository] coordinating storage persistence, validation, and chunking.
class PdfRepositoryImpl extends BaseRepository<PdfDocument>
    implements PdfRepository {
  final PdfImportService _importService;
  final PdfChunkService _chunkService;

  static const String _documentNamespace = 'pdf_documents';
  static const String _chunksNamespace = 'pdf_chunks';
  static const String _textNamespace = 'pdf_extracted_text';

  PdfRepositoryImpl({
    required super.aiService,
    required super.storageService,
    required super.networkService,
    super.cacheStrategy,
    PdfImportService importService = const PdfImportService(),
    PdfChunkService chunkService = const PdfChunkService(),
  })  : _importService = importService,
        _chunkService = chunkService;

  @override
  Future<PdfImportResult> importPdf(
    String filePath, {
    String? displayName,
    int? sizeBytes,
    int? pageCount,
    PdfMetadata? metadata,
    List<int>? headerBytes,
    bool isEncrypted = false,
    bool isCorrupted = false,
    bool isEmpty = false,
  }) async {
    checkState();
    return executeGuarded(() async {
      final documentId = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final name = displayName ?? fileName;

      final result = _importService.importPdf(
        filePath: filePath,
        documentId: documentId,
        fileName: fileName,
        displayName: name,
        sizeBytes: sizeBytes ?? 1024,
        pageCount: pageCount ?? 1,
        metadata: metadata ?? const PdfMetadata.empty(),
        headerBytes: headerBytes,
        isEncrypted: isEncrypted,
        isCorrupted: isCorrupted,
        isEmpty: isEmpty,
      );

      if (result.isSuccess) {
        final key = StorageKey(documentId, namespace: _documentNamespace);
        await storageService.write<Map<String, dynamic>>(key, {
          'id': result.document.id,
          'fileName': result.document.fileName,
          'displayName': result.document.displayName,
          'sizeBytes': result.document.sizeBytes,
          'pageCount': result.document.pageCount,
          'createdAt': result.document.createdAt.toIso8601String(),
          'lastModified': result.document.lastModified.toIso8601String(),
          'language': result.document.language,
          'status': result.document.status.name,
        });
      }

      return result;
    });
  }

  @override
  Future<PdfDocument?> loadPdf(String documentId) async {
    checkState();
    return executeGuarded(() async {
      final key = StorageKey(documentId, namespace: _documentNamespace);
      final data = await storageService.read<Map<String, dynamic>>(key);
      if (data == null) return null;

      return PdfDocument(
        id: data['id'] as String,
        fileName: data['fileName'] as String,
        displayName: data['displayName'] as String,
        sizeBytes: data['sizeBytes'] as int,
        pageCount: data['pageCount'] as int,
        createdAt: DateTime.parse(data['createdAt'] as String),
        lastModified: DateTime.parse(data['lastModified'] as String),
        language: data['language'] as String? ?? 'en',
      );
    });
  }

  @override
  Future<void> deletePdf(String documentId) async {
    checkState();
    await executeGuarded(() async {
      final docKey = StorageKey(documentId, namespace: _documentNamespace);
      final textKey = StorageKey(documentId, namespace: _textNamespace);
      final chunksKey = StorageKey(documentId, namespace: _chunksNamespace);

      await storageService.delete(docKey);
      await storageService.delete(textKey);
      await storageService.delete(chunksKey);
    });
  }

  @override
  Future<List<PdfDocument>> listDocuments() async {
    checkState();
    return executeGuarded(() async {
      final docKeys = await storageService.keys(namespace: _documentNamespace);
      final documents = <PdfDocument>[];

      for (final key in docKeys) {
        final data = await storageService.read<Map<String, dynamic>>(key);
        if (data != null) {
          documents.add(
            PdfDocument(
              id: data['id'] as String,
              fileName: data['fileName'] as String,
              displayName: data['displayName'] as String,
              sizeBytes: data['sizeBytes'] as int,
              pageCount: data['pageCount'] as int,
              createdAt: DateTime.parse(data['createdAt'] as String),
              lastModified: DateTime.parse(data['lastModified'] as String),
              language: data['language'] as String? ?? 'en',
            ),
          );
        }
      }

      return documents;
    });
  }

  @override
  Future<String> extractText(String documentId) async {
    checkState();
    return executeGuarded(() async {
      final textKey = StorageKey(documentId, namespace: _textNamespace);
      final cachedText = await storageService.read<String>(textKey);
      if (cachedText != null && cachedText.isNotEmpty) {
        return cachedText;
      }

      final doc = await loadPdf(documentId);
      if (doc == null) {
        throw PdfExtractionException(
            'Document with ID "$documentId" not found.');
      }

      final extractedText =
          'Extracted sample text content for PDF Document: ${doc.displayName} (${doc.pageCount} pages).';
      await storageService.write<String>(textKey, extractedText);
      return extractedText;
    });
  }

  @override
  Future<List<PdfChunk>> createChunks(
    String documentId, {
    ChunkOptions? options,
  }) async {
    checkState();
    return executeGuarded(() async {
      final text = await extractText(documentId);
      final opt = options ?? const ChunkOptions();
      return _chunkService.chunkText(
        documentId: documentId,
        text: text,
        options: opt,
      );
    });
  }

  @override
  Future<void> saveChunks(String documentId, List<PdfChunk> chunks) async {
    checkState();
    await executeGuarded(() async {
      final key = StorageKey(documentId, namespace: _chunksNamespace);
      final serializedChunks = chunks
          .map((c) => {
                'chunkId': c.chunkId,
                'documentId': c.documentId,
                'index': c.index,
                'text': c.text,
                'startPage': c.startPage,
                'endPage': c.endPage,
                'tokenEstimate': c.tokenEstimate,
                'characterCount': c.characterCount,
              })
          .toList();

      await storageService.write<List<dynamic>>(key, serializedChunks);
    });
  }
}
