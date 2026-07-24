import '../models/library_models.dart';
import 'library_repository.dart';

/// Concrete implementation of [LibraryRepository] managing Digital Library documents,
/// folders, metadata, bookmarks, reading progress, and search functionality.
class LibraryRepositoryImpl implements LibraryRepository {
  final Map<String, LibraryDocument> _documents = {};
  final Map<String, LibraryFolder> _folders = {};

  LibraryRepositoryImpl(
      {List<LibraryDocument>? initialDocuments,
      List<LibraryFolder>? initialFolders}) {
    if (initialDocuments != null && initialDocuments.isNotEmpty) {
      for (final doc in initialDocuments) {
        _documents[doc.id] = doc;
      }
    } else {
      _seedDefaultDocuments();
    }

    if (initialFolders != null && initialFolders.isNotEmpty) {
      for (final folder in initialFolders) {
        _folders[folder.id] = folder;
      }
    } else {
      _seedDefaultFolders();
    }
  }

  void _seedDefaultDocuments() {
    final now = DateTime.now();

    final doc1 = LibraryDocument(
      id: 'doc_polity_01',
      title: 'Indian Polity - Constitutional Framework & Governance',
      filePath: '/storage/documents/polity_governance.pdf',
      fileSize: 4520000,
      pageCount: 120,
      category: 'Polity',
      isFavorite: true,
      createdAt: now.subtract(const Duration(days: 5)),
      lastReadAt: now.subtract(const Duration(hours: 2)),
      progress: ReadingProgress(
        currentPage: 45,
        totalPages: 120,
        completionPercentage: 37.5,
        lastReadAt: now.subtract(const Duration(hours: 2)),
      ),
      bookmarks: [
        Bookmark(
          id: 'bm_1',
          documentId: 'doc_polity_01',
          pageNumber: 14,
          label: 'Preamble & Key Features',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        Bookmark(
          id: 'bm_2',
          documentId: 'doc_polity_01',
          pageNumber: 42,
          label: 'Fundamental Rights & Writs',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      tags: const ['UPSC', 'Polity', 'GS-2', 'Constitution'],
      aiAnnotations: [
        AiAnnotation(
          id: 'ai_1',
          documentId: 'doc_polity_01',
          pageNumber: 14,
          prompt: 'Summarize Key Features of Preamble',
          aiSummary:
              'The Preamble embodies the basic structure and philosophy of the Indian Constitution.',
          keyTakeaways: const [
            'Sovereign, Socialist, Secular, Democratic, Republic',
            'Justice: Social, Economic, and Political',
          ],
          tags: const ['Preamble', 'Basic Structure'],
        ),
      ],
    );

    final doc2 = LibraryDocument(
      id: 'doc_economy_01',
      title: 'Indian Economy - Banking, Inflation & Fiscal Policy',
      filePath: '/storage/documents/economy_summary.pdf',
      fileSize: 3200000,
      pageCount: 85,
      category: 'Economy',
      isFavorite: true,
      createdAt: now.subtract(const Duration(days: 10)),
      lastReadAt: now.subtract(const Duration(days: 1)),
      progress: ReadingProgress(
        currentPage: 60,
        totalPages: 85,
        completionPercentage: 70.6,
        lastReadAt: now.subtract(const Duration(days: 1)),
      ),
      bookmarks: [
        Bookmark(
          id: 'bm_3',
          documentId: 'doc_economy_01',
          pageNumber: 25,
          label: 'RBI Monetary Policy Tools',
          createdAt: now.subtract(const Duration(days: 4)),
        ),
      ],
      tags: const ['UPSC', 'Economy', 'GS-3', 'Banking'],
    );

    final doc3 = LibraryDocument(
      id: 'doc_history_01',
      title: 'Modern Indian History - Freedom Struggle & Movements',
      filePath: '/storage/documents/modern_history.pdf',
      fileSize: 5100000,
      pageCount: 150,
      category: 'History',
      isFavorite: false,
      createdAt: now.subtract(const Duration(days: 15)),
      lastReadAt: now.subtract(const Duration(days: 4)),
      progress: ReadingProgress(
        currentPage: 15,
        totalPages: 150,
        completionPercentage: 10.0,
        lastReadAt: now.subtract(const Duration(days: 4)),
      ),
      tags: const ['UPSC', 'History', 'GS-1', 'Freedom Struggle'],
    );

    final doc4 = LibraryDocument(
      id: 'doc_env_01',
      title: 'Environment & Ecology - Conventions & Biodiversity',
      filePath: '/storage/documents/environment_ecology.pdf',
      fileSize: 2800000,
      pageCount: 95,
      category: 'Environment',
      isFavorite: false,
      createdAt: now.subtract(const Duration(days: 20)),
      lastReadAt: now.subtract(const Duration(days: 7)),
      progress: ReadingProgress.initial(95),
      tags: const ['UPSC', 'Environment', 'GS-3', 'Biodiversity'],
    );

    _documents[doc1.id] = doc1;
    _documents[doc2.id] = doc2;
    _documents[doc3.id] = doc3;
    _documents[doc4.id] = doc4;
  }

  void _seedDefaultFolders() {
    final now = DateTime.now();

    final f1 = LibraryFolder(
      id: 'folder_polity',
      name: 'GS-2 Polity & Governance',
      iconName: 'gavel',
      category: 'Polity',
      documentIds: const ['doc_polity_01'],
      createdAt: now.subtract(const Duration(days: 10)),
    );

    final f2 = LibraryFolder(
      id: 'folder_economy',
      name: 'GS-3 Economy & Finance',
      iconName: 'account_balance',
      category: 'Economy',
      documentIds: const ['doc_economy_01'],
      createdAt: now.subtract(const Duration(days: 12)),
    );

    final f3 = LibraryFolder(
      id: 'folder_history',
      name: 'GS-1 History & Culture',
      iconName: 'menu_book',
      category: 'History',
      documentIds: const ['doc_history_01'],
      createdAt: now.subtract(const Duration(days: 15)),
    );

    _folders[f1.id] = f1;
    _folders[f2.id] = f2;
    _folders[f3.id] = f3;
  }

  @override
  Future<List<LibraryDocument>> getDocuments({
    String? category,
    String? searchQuery,
    bool? onlyFavorites,
  }) async {
    var result = _documents.values.toList();

    if (category != null && category.trim().isNotEmpty && category != 'All') {
      result = result
          .where((d) => d.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (onlyFavorites == true) {
      result = result.where((d) => d.isFavorite).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((d) {
        final titleMatch = d.title.toLowerCase().contains(query);
        final categoryMatch = d.category.toLowerCase().contains(query);
        final tagMatch = d.tags.any((t) => t.toLowerCase().contains(query));
        return titleMatch || categoryMatch || tagMatch;
      }).toList();
    }

    // Sort by lastReadAt descending
    result.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return result;
  }

  @override
  Future<LibraryDocument?> getDocumentById(String id) async {
    return _documents[id];
  }

  @override
  Future<LibraryDocument> importPdfDocument({
    required String filePath,
    required String title,
    String? category,
    int pageCount = 10,
    int fileSize = 1024000,
  }) async {
    final now = DateTime.now();
    final id = 'doc_imported_${now.millisecondsSinceEpoch}';

    final doc = LibraryDocument(
      id: id,
      title: title,
      filePath: filePath,
      fileSize: fileSize,
      pageCount: pageCount,
      category: category ?? 'General Studies',
      createdAt: now,
      lastReadAt: now,
      progress: ReadingProgress.initial(pageCount),
      tags: const ['Imported', 'PDF'],
    );

    _documents[id] = doc;
    return doc;
  }

  @override
  Future<LibraryDocument> updateReadingProgress(
    String documentId,
    int currentPage,
    int totalPages,
  ) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw Exception('Document [$documentId] not found.');
    }

    final now = DateTime.now();
    final updatedProgress = doc.progress.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadAt: now,
    );

    final updatedDoc = doc.copyWith(
      progress: updatedProgress,
      lastReadAt: now,
    );

    _documents[documentId] = updatedDoc;
    return updatedDoc;
  }

  @override
  Future<LibraryDocument> toggleFavorite(String documentId) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw Exception('Document [$documentId] not found.');
    }

    final updatedDoc = doc.copyWith(isFavorite: !doc.isFavorite);
    _documents[documentId] = updatedDoc;
    return updatedDoc;
  }

  @override
  Future<LibraryDocument> addBookmark(
      String documentId, Bookmark bookmark) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw Exception('Document [$documentId] not found.');
    }

    final updatedBookmarks = List<Bookmark>.from(doc.bookmarks)..add(bookmark);
    final updatedDoc = doc.copyWith(bookmarks: updatedBookmarks);
    _documents[documentId] = updatedDoc;
    return updatedDoc;
  }

  @override
  Future<LibraryDocument> removeBookmark(
      String documentId, String bookmarkId) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw Exception('Document [$documentId] not found.');
    }

    final updatedBookmarks =
        doc.bookmarks.where((b) => b.id != bookmarkId).toList();
    final updatedDoc = doc.copyWith(bookmarks: updatedBookmarks);
    _documents[documentId] = updatedDoc;
    return updatedDoc;
  }

  @override
  Future<List<LibraryFolder>> getFolders() async {
    final list = _folders.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<LibraryFolder> createFolder(
    String name, {
    String? category,
    String iconName = 'folder',
  }) async {
    final now = DateTime.now();
    final id = 'folder_${now.millisecondsSinceEpoch}';

    final folder = LibraryFolder(
      id: id,
      name: name,
      iconName: iconName,
      category: category ?? 'General',
      documentIds: const [],
      createdAt: now,
    );

    _folders[id] = folder;
    return folder;
  }
}
