import '../models/library_models.dart';

/// Abstract repository interface defining digital library data management operations.
abstract class LibraryRepository {
  /// Retrieves documents, optionally filtered by category, search query, or favorite status.
  Future<List<LibraryDocument>> getDocuments({
    String? category,
    String? searchQuery,
    bool? onlyFavorites,
  });

  /// Retrieves a specific document by ID.
  Future<LibraryDocument?> getDocumentById(String id);

  /// Imports a PDF file into the Digital Library with metadata.
  Future<LibraryDocument> importPdfDocument({
    required String filePath,
    required String title,
    String? category,
    int pageCount = 10,
    int fileSize = 1024000,
  });

  /// Updates reading progress (current page and total pages) for a document.
  Future<LibraryDocument> updateReadingProgress(
    String documentId,
    int currentPage,
    int totalPages,
  );

  /// Toggles the favorite status for a document.
  Future<LibraryDocument> toggleFavorite(String documentId);

  /// Adds a bookmark to a document.
  Future<LibraryDocument> addBookmark(String documentId, Bookmark bookmark);

  /// Removes a bookmark from a document by bookmark ID.
  Future<LibraryDocument> removeBookmark(String documentId, String bookmarkId);

  /// Retrieves all library folders.
  Future<List<LibraryFolder>> getFolders();

  /// Creates a new library folder.
  Future<LibraryFolder> createFolder(
    String name, {
    String? category,
    String iconName = 'folder',
  });
}
