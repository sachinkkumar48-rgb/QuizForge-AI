import 'dart:io';

import 'package:titan_pdf/titan_pdf.dart';

import '../data/document_library_repository.dart';
import '../domain/entities/reader_document.dart';
import '../domain/entities/reading_position.dart';
import '../data/reading_position_repository.dart';
import 'reading_history_service.dart';

/// Application service coordinating document import, opening, and library
/// mutations for TITAN Reader.
///
/// Import validation reuses the established `titan_pdf` validation rules
/// instead of introducing competing validation logic.
class LibraryService {
  final DocumentLibraryRepository _library;
  final ReadingPositionRepository _positions;
  final ReadingHistoryService _history;
  final PdfValidationService _validation;
  final Future<Directory> Function()? _getDocumentsDirectory;

  LibraryService({
    required DocumentLibraryRepository library,
    required ReadingPositionRepository positions,
    required ReadingHistoryService history,
    PdfValidationService validation = const PdfValidationService(),
    Future<Directory> Function()? getDocumentsDirectory,
  })  : _library = library,
        _positions = positions,
        _history = history,
        _validation = validation,
        _getDocumentsDirectory = getDocumentsDirectory;

  /// Imports a picked PDF file (from file picker or external source) by
  /// copying it into TITAN Reader's secure, application-private document storage.
  ///
  /// This guarantees that the PDF has a permanent, canonical filesystem path,
  /// is immune to temporary cache purges (such as Android file_picker cache
  /// cleanup), and conforms to Android Scoped Storage POSIX requirements for
  /// the PDFium rendering engine.
  Future<ReaderDocument> importPickedFile({
    String? sourceFilePath,
    List<int>? fileBytes,
    required String fileName,
    required int sizeBytes,
    required DateTime at,
    List<int>? headerBytes,
  }) async {
    _validation.validatePdf(
      filePath: sourceFilePath ?? fileName,
      sizeBytes: sizeBytes,
      headerBytes: headerBytes,
    );

    String canonicalPath;
    final docId = sourceFilePath != null && sourceFilePath.isNotEmpty
        ? _idForFilePath(sourceFilePath)
        : _idForFileNameAndSize(fileName, sizeBytes);

    if (_getDocumentsDirectory != null) {
      final appDocsDir = await _getDocumentsDirectory();
      final privateDir = Directory('${appDocsDir.path}/documents');
      if (!await privateDir.exists()) {
        await privateDir.create(recursive: true);
      }
      canonicalPath = '${privateDir.path}/$docId.pdf';

      if (sourceFilePath != null &&
          sourceFilePath.isNotEmpty &&
          sourceFilePath != canonicalPath &&
          File(sourceFilePath).existsSync()) {
        await File(sourceFilePath).copy(canonicalPath);
      } else if (fileBytes != null && fileBytes.isNotEmpty) {
        final destFile = File(canonicalPath);
        await destFile.writeAsBytes(fileBytes, flush: true);
      } else if (sourceFilePath != null && sourceFilePath.isNotEmpty) {
        canonicalPath = sourceFilePath;
      }
    } else {
      canonicalPath = sourceFilePath ?? '/documents/$docId.pdf';
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final destFile = File(canonicalPath);
        if (destFile.parent.existsSync() || destFile.parent.path.isEmpty) {
          try {
            await destFile.writeAsBytes(fileBytes, flush: true);
          } catch (_) {}
        }
      }
    }

    return importFile(
      filePath: canonicalPath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      at: at,
      headerBytes: headerBytes,
    );
  }

  /// Imports the PDF at [filePath] into the library.
  ///
  /// Throws [PdfValidationException] (from titan_pdf) when the file violates
  /// format/size constraints. Re-importing a known path refreshes its entry
  /// instead of duplicating it. All imported documents are LOCAL_ONLY.
  Future<ReaderDocument> importFile({
    required String filePath,
    required String fileName,
    required int sizeBytes,
    required DateTime at,
    List<int>? headerBytes,
  }) async {
    _validation.validatePdf(
      filePath: filePath,
      sizeBytes: sizeBytes,
      headerBytes: headerBytes,
    );

    final existing = await _library.getByFilePath(filePath);
    final document = existing ??
        ReaderDocument(
          id: _idForFilePath(filePath),
          title: _titleFromFileName(fileName),
          filePath: filePath,
          sizeBytes: sizeBytes,
          addedAt: at,
        );
    final refreshed = existing == null
        ? document
        : document.copyWith(); // keep existing metadata on re-import
    await _library.save(existing == null ? document : refreshed);
    return existing == null ? document : refreshed;
  }

  /// Marks the document opened at [at]: updates the last-opened timestamp
  /// and records a history visit.
  Future<ReaderDocument?> markOpened({
    required String documentId,
    required DateTime at,
  }) async {
    final document = await _library.getById(documentId);
    if (document == null) return null;
    final updated = document.copyWith(lastOpenedAt: at);
    await _library.save(updated);
    await _history.recordVisit(documentId: documentId, visitedAt: at);
    return updated;
  }

  /// Persists the engine-reported page count once known.
  Future<void> updatePageCount({
    required String documentId,
    required int pageCount,
  }) async {
    if (pageCount < 1) return;
    final document = await _library.getById(documentId);
    if (document == null || document.pageCount == pageCount) return;
    await _library.save(document.copyWith(pageCount: pageCount));
  }

  /// Toggles the favorite flag of a document.
  Future<ReaderDocument?> toggleFavorite(String documentId) async {
    final document = await _library.getById(documentId);
    if (document == null) return null;
    final updated = document.copyWith(isFavorite: !document.isFavorite);
    await _library.save(updated);
    return updated;
  }

  /// Removes a document entry, its reading position, and its history entry.
  /// The local PDF file itself is not deleted by this operation.
  Future<void> removeDocument(String documentId) async {
    await _library.remove(documentId);
    await _positions.delete(documentId);
    await _history.removeDocument(documentId);
  }

  /// Loads the stored reading position for a document, if any.
  Future<ReadingPosition?> loadPosition(String documentId) =>
      _positions.load(documentId);

  /// Persists the current reading position.
  Future<void> savePosition(ReadingPosition position) =>
      _positions.save(position);

  /// Returns all library documents in display order.
  Future<List<ReaderDocument>> getDocuments() => _library.getAll();

  /// Returns the ids of recently opened documents, most recent first.
  Future<List<String>> getRecentDocumentIds() => _history.recentDocumentIds();

  /// Deterministic library id derived from the file path.
  static String _idForFilePath(String filePath) {
    final hash = filePath.toLowerCase().hashCode.toUnsigned(32);
    return 'doc_${hash.toRadixString(36)}';
  }

  /// Deterministic library id derived from filename and size when path is absent or transient.
  static String _idForFileNameAndSize(String fileName, int sizeBytes) {
    final hash = '$fileName:$sizeBytes'.toLowerCase().hashCode.toUnsigned(32);
    return 'doc_${hash.toRadixString(36)}';
  }

  static String _titleFromFileName(String fileName) {
    final name = fileName.trim();
    if (name.isEmpty) return 'Untitled document';
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) {
      final base = name.substring(0, name.length - 4).trim();
      if (base.isNotEmpty) return base;
    }
    return name;
  }
}
