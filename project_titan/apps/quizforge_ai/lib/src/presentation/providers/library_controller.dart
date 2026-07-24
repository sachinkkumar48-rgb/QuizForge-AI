import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_content/titan_content.dart';

import '../states/library_state.dart';

/// Provider exposing the abstract [LibraryRepository] contract.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl();
});

/// Provider exposing the Clean Architecture [ManageLibraryUseCase].
final manageLibraryUseCaseProvider = Provider<ManageLibraryUseCase>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return ManageLibraryUseCase(repository);
});

/// Riverpod Controller managing presentation state for the Digital Library MVP.
///
/// Adheres strictly to Clean Architecture by interacting exclusively with
/// [ManageLibraryUseCase] to keep presentation independent of infrastructure.
class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() {
    return const LibraryState.initial();
  }

  /// Initializes or refreshes the Digital Library documents, folders, and stats.
  Future<void> loadLibrary() async {
    state = state.copyWith(status: LibraryStateStatus.loading);
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);

      final documents = await useCase.getDocuments(
        category: state.selectedCategory,
        searchQuery: state.searchQuery,
      );
      final folders = await useCase.getFolders();
      final continueReading = await useCase.getContinueReadingDocuments();
      final favorites = await useCase.getFavoriteDocuments();

      state = state.copyWith(
        status: LibraryStateStatus.success,
        documents: documents,
        folders: folders,
        continueReadingDocuments: continueReading,
        favoriteDocuments: favorites,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: LibraryStateStatus.error,
        errorMessage: 'Failed to load Digital Library: ${e.toString()}',
      );
    }
  }

  /// Searches library documents by keyword across titles, categories, and tags.
  Future<void> searchDocuments(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadLibrary();
  }

  /// Filters library documents by selected subject category.
  Future<void> selectCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
    await loadLibrary();
  }

  /// Toggles favorite status for a document.
  Future<void> toggleFavorite(String documentId) async {
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);
      await useCase.toggleFavorite(documentId);
      await loadLibrary();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to update favorite status: ${e.toString()}',
      );
    }
  }

  /// Imports a PDF file into the library with metadata.
  Future<LibraryDocument?> importPdfDocument({
    required String filePath,
    required String title,
    String? category,
    int pageCount = 10,
    int fileSize = 1024000,
  }) async {
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);
      final doc = await useCase.importPdfDocument(
        filePath: filePath,
        title: title,
        category: category,
        pageCount: pageCount,
        fileSize: fileSize,
      );
      await loadLibrary();
      return doc;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to import PDF document: ${e.toString()}',
      );
      return null;
    }
  }

  /// Updates reading progress for a given document.
  Future<void> updateReadingProgress(
    String documentId,
    int currentPage,
    int totalPages,
  ) async {
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);
      await useCase.updateReadingProgress(documentId, currentPage, totalPages);
      await loadLibrary();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to update reading progress: ${e.toString()}',
      );
    }
  }

  /// Adds a bookmark to a document.
  Future<void> addBookmark(String documentId, Bookmark bookmark) async {
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);
      await useCase.addBookmark(documentId, bookmark);
      await loadLibrary();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to add bookmark: ${e.toString()}',
      );
    }
  }

  /// Removes a bookmark from a document.
  Future<void> removeBookmark(String documentId, String bookmarkId) async {
    try {
      final useCase = ref.read(manageLibraryUseCaseProvider);
      await useCase.removeBookmark(documentId, bookmarkId);
      await loadLibrary();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to remove bookmark: ${e.toString()}',
      );
    }
  }
}

/// Riverpod provider for [LibraryController].
final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);
