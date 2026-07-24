import '../models/library_models.dart';
import '../repository/library_repository.dart';

/// Clean Architecture Use Case encapsulating business logic for the Digital Library.
class ManageLibraryUseCase {
  final LibraryRepository _repository;

  const ManageLibraryUseCase(this._repository);

  /// Retrieves documents matching category, search query, or favorite filter.
  Future<List<LibraryDocument>> getDocuments({
    String? category,
    String? searchQuery,
    bool? onlyFavorites,
  }) {
    return _repository.getDocuments(
      category: category,
      searchQuery: searchQuery,
      onlyFavorites: onlyFavorites,
    );
  }

  /// Retrieves a single document by ID.
  Future<LibraryDocument?> getDocumentById(String id) {
    return _repository.getDocumentById(id);
  }

  /// Retrieves documents with active reading progress (> 0% and < 100%).
  Future<List<LibraryDocument>> getContinueReadingDocuments() async {
    final docs = await _repository.getDocuments();
    return docs
        .where((d) =>
            d.progress.completionPercentage > 0.0 &&
            d.progress.completionPercentage < 100.0)
        .toList();
  }

  /// Retrieves starred / favorite documents.
  Future<List<LibraryDocument>> getFavoriteDocuments() {
    return _repository.getDocuments(onlyFavorites: true);
  }

  /// Imports a PDF file into the library with metadata.
  Future<LibraryDocument> importPdfDocument({
    required String filePath,
    required String title,
    String? category,
    int pageCount = 10,
    int fileSize = 1024000,
  }) {
    return _repository.importPdfDocument(
      filePath: filePath,
      title: title,
      category: category,
      pageCount: pageCount,
      fileSize: fileSize,
    );
  }

  /// Updates reading progress for a given document.
  Future<LibraryDocument> updateReadingProgress(
    String documentId,
    int currentPage,
    int totalPages,
  ) {
    return _repository.updateReadingProgress(
        documentId, currentPage, totalPages);
  }

  /// Toggles favorite status for a document.
  Future<LibraryDocument> toggleFavorite(String documentId) {
    return _repository.toggleFavorite(documentId);
  }

  /// Adds a bookmark to a document.
  Future<LibraryDocument> addBookmark(String documentId, Bookmark bookmark) {
    return _repository.addBookmark(documentId, bookmark);
  }

  /// Removes a bookmark from a document by bookmark ID.
  Future<LibraryDocument> removeBookmark(String documentId, String bookmarkId) {
    return _repository.removeBookmark(documentId, bookmarkId);
  }

  /// Retrieves library folders.
  Future<List<LibraryFolder>> getFolders() {
    return _repository.getFolders();
  }

  /// Creates a new library folder.
  Future<LibraryFolder> createFolder(
    String name, {
    String? category,
    String iconName = 'folder',
  }) {
    return _repository.createFolder(name,
        category: category, iconName: iconName);
  }
}
