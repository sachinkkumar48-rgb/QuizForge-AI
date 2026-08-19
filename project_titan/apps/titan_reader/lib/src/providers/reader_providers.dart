import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_storage/titan_storage.dart';

import '../data/annotation_repository.dart';
import '../data/bookmark_repository.dart';
import '../data/document_library_repository.dart';
import '../data/note_repository.dart';
import '../data/reading_position_repository.dart';
import '../domain/entities/reader_annotation.dart';
import '../domain/entities/reader_bookmark.dart';
import '../domain/entities/reader_document.dart';
import '../domain/entities/reader_note.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../pdf/pdfrx_pdf_engine.dart';
import '../services/annotation_service.dart';
import '../services/bookmark_service.dart';
import '../services/library_service.dart';
import '../services/note_service.dart';
import '../services/reading_history_service.dart';

/// Provides the PDF engine abstraction. Overridable in tests with a fake
/// engine; the production binding is the pdfrx adapter (ADR-0004).
final Provider<PdfDocumentEngine> pdfEngineProvider =
    Provider<PdfDocumentEngine>((ref) => const PdfrxPdfEngine());

/// Provides the shared TITAN [StorageService].
///
/// Must be overridden in `main()` after [TitanStorageBootstrap]-style
/// initialization and in tests with an in-memory implementation.
final Provider<StorageService> storageServiceProvider =
    Provider<StorageService>((ref) {
  throw StateError(
      'storageServiceProvider must be overridden with an initialized '
      'StorageService before use.');
});

final Provider<DocumentLibraryRepository> documentLibraryRepositoryProvider =
    Provider<DocumentLibraryRepository>((ref) {
  return StorageDocumentLibraryRepository(ref.watch(storageServiceProvider));
});

final Provider<ReadingPositionRepository> readingPositionRepositoryProvider =
    Provider<ReadingPositionRepository>((ref) {
  return StorageReadingPositionRepository(ref.watch(storageServiceProvider));
});

final Provider<ReadingHistoryService> readingHistoryServiceProvider =
    Provider<ReadingHistoryService>((ref) {
  return ReadingHistoryService(ref.watch(storageServiceProvider));
});

final Provider<LibraryService> libraryServiceProvider =
    Provider<LibraryService>((ref) {
  return LibraryService(
    library: ref.watch(documentLibraryRepositoryProvider),
    positions: ref.watch(readingPositionRepositoryProvider),
    history: ref.watch(readingHistoryServiceProvider),
  );
});

/// All library documents in display order.
final FutureProvider<List<ReaderDocument>> libraryDocumentsProvider =
    FutureProvider<List<ReaderDocument>>((ref) {
  return ref.watch(libraryServiceProvider).getDocuments();
});

/// Recently opened documents, most recent first (the "Recent" shelf).
final FutureProvider<List<ReaderDocument>> recentDocumentsProvider =
    FutureProvider<List<ReaderDocument>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  final recentIds = await service.getRecentDocumentIds();
  if (recentIds.isEmpty) return const <ReaderDocument>[];
  final documents = await service.getDocuments();
  final byId = <String, ReaderDocument>{
    for (final document in documents) document.id: document,
  };
  return <ReaderDocument>[
    for (final id in recentIds)
      if (byId[id] != null) byId[id]!,
  ];
});

/// Single-document lookup for the reader screen.
final FutureProviderFamily<ReaderDocument?, String> documentByIdProvider =
    FutureProvider.family<ReaderDocument?, String>((ref, documentId) {
  final service = ref.watch(libraryServiceProvider);
  return service.getDocuments().then((documents) {
    for (final document in documents) {
      if (document.id == documentId) return document;
    }
    return null;
  });
});

// ---------------------------------------------------------------------------
// Phase 2: annotations, bookmarks, notes
// ---------------------------------------------------------------------------

final Provider<AnnotationRepository> annotationRepositoryProvider =
    Provider<AnnotationRepository>((ref) {
  return StorageAnnotationRepository(ref.watch(storageServiceProvider));
});

final Provider<BookmarkRepository> bookmarkRepositoryProvider =
    Provider<BookmarkRepository>((ref) {
  return StorageBookmarkRepository(ref.watch(storageServiceProvider));
});

final Provider<NoteRepository> noteRepositoryProvider =
    Provider<NoteRepository>((ref) {
  return StorageNoteRepository(ref.watch(storageServiceProvider));
});

final Provider<AnnotationService> annotationServiceProvider =
    Provider<AnnotationService>((ref) {
  return AnnotationService(repository: ref.watch(annotationRepositoryProvider));
});

final Provider<BookmarkService> bookmarkServiceProvider =
    Provider<BookmarkService>((ref) {
  return BookmarkService(repository: ref.watch(bookmarkRepositoryProvider));
});

final Provider<NoteService> noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService(repository: ref.watch(noteRepositoryProvider));
});

/// Annotations of one document; rebuilds whenever the service mutates.
/// The reader screen calls [AnnotationService.preload] when opening the
/// document; this provider reads the service cache reactively.
final FutureProviderFamily<List<ReaderAnnotation>, String>
    annotationsForDocumentProvider =
    FutureProvider.family<List<ReaderAnnotation>, String>((ref, documentId) {
  final service = ref.watch(annotationServiceProvider);
  void listener() => ref.invalidateSelf();
  service.addListener(listener);
  ref.onDispose(() => service.removeListener(listener));
  return Future.value(service.annotationsFor(documentId));
});

/// Bookmarks of one document; rebuilds whenever the service mutates.
final FutureProviderFamily<List<ReaderBookmark>, String>
    bookmarksForDocumentProvider =
    FutureProvider.family<List<ReaderBookmark>, String>((ref, documentId) {
  final service = ref.watch(bookmarkServiceProvider);
  void listener() => ref.invalidateSelf();
  service.addListener(listener);
  ref.onDispose(() => service.removeListener(listener));
  return Future.value(service.bookmarksFor(documentId));
});

/// Notes of one document; rebuilds whenever the service mutates.
final FutureProviderFamily<List<ReaderNote>, String> notesForDocumentProvider =
    FutureProvider.family<List<ReaderNote>, String>((ref, documentId) {
  final service = ref.watch(noteServiceProvider);
  void listener() => ref.invalidateSelf();
  service.addListener(listener);
  ref.onDispose(() => service.removeListener(listener));
  return Future.value(service.notesFor(documentId));
});
