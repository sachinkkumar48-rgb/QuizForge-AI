import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_storage/titan_storage.dart';

import '../data/document_library_repository.dart';
import '../data/reading_position_repository.dart';
import '../domain/entities/reader_document.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../pdf/pdfrx_pdf_engine.dart';
import '../services/library_service.dart';
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
