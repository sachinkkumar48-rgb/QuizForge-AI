import 'package:test/test.dart';
import 'package:titan_content/titan_content.dart';

void main() {
  group('ManageLibraryUseCase & LibraryRepositoryImpl', () {
    late LibraryRepository repository;
    late ManageLibraryUseCase useCase;

    setUp(() {
      repository = LibraryRepositoryImpl();
      useCase = ManageLibraryUseCase(repository);
    });

    test('should fetch initial seeded documents and folders', () async {
      final docs = await useCase.getDocuments();
      final folders = await useCase.getFolders();

      expect(docs, isNotEmpty);
      expect(folders, isNotEmpty);
      expect(docs.any((d) => d.category == 'Polity'), isTrue);
    });

    test('should filter documents by category and search query', () async {
      final polityDocs = await useCase.getDocuments(category: 'Polity');
      expect(polityDocs.every((d) => d.category == 'Polity'), isTrue);

      final searchDocs = await useCase.getDocuments(searchQuery: 'Governance');
      expect(searchDocs, isNotEmpty);
      expect(searchDocs.first.title.contains('Governance'), isTrue);
    });

    test('should retrieve continue reading and favorite documents', () async {
      final continueReading = await useCase.getContinueReadingDocuments();
      final favorites = await useCase.getFavoriteDocuments();

      expect(continueReading, isNotEmpty);
      expect(favorites, isNotEmpty);
      expect(favorites.every((d) => d.isFavorite), isTrue);
    });

    test('should import PDF document with metadata', () async {
      final doc = await useCase.importPdfDocument(
        filePath: '/storage/new_upsc.pdf',
        title: 'UPSC Art & Culture Notes',
        category: 'History',
        pageCount: 50,
      );

      expect(doc.title, equals('UPSC Art & Culture Notes'));
      expect(doc.category, equals('History'));
      expect(doc.pageCount, equals(50));

      final allDocs = await useCase.getDocuments();
      expect(allDocs.any((d) => d.id == doc.id), isTrue);
    });

    test('should toggle favorite status', () async {
      final docs = await useCase.getDocuments();
      final firstDoc = docs.first;
      final initialFavorite = firstDoc.isFavorite;

      final updated = await useCase.toggleFavorite(firstDoc.id);
      expect(updated.isFavorite, equals(!initialFavorite));
    });

    test('should update reading progress correctly', () async {
      final docs = await useCase.getDocuments();
      final firstDoc = docs.first;

      final updated = await useCase.updateReadingProgress(firstDoc.id, 50, 100);
      expect(updated.progress.currentPage, equals(50));
      expect(updated.progress.totalPages, equals(100));
      expect(updated.progress.completionPercentage, equals(50.0));
    });

    test('should add and remove bookmark', () async {
      final docs = await useCase.getDocuments();
      final firstDoc = docs.first;

      final bookmark = Bookmark(
        id: 'bm_test_1',
        documentId: firstDoc.id,
        pageNumber: 22,
        label: 'Test Bookmark',
        createdAt: DateTime.now(),
      );

      final withBookmark = await useCase.addBookmark(firstDoc.id, bookmark);
      expect(withBookmark.bookmarks.any((b) => b.id == 'bm_test_1'), isTrue);

      final removed = await useCase.removeBookmark(firstDoc.id, 'bm_test_1');
      expect(removed.bookmarks.any((b) => b.id == 'bm_test_1'), isFalse);
    });

    test('placeholder annotation models should instantiate correctly', () {
      final now = DateTime.now();
      final highlight = HighlightAnnotation(
        id: 'h1',
        documentId: 'doc1',
        pageNumber: 5,
        selectedText: 'Basic Structure',
        colorHex: '#FF0000',
        createdAt: now,
      );
      expect(highlight.selectedText, equals('Basic Structure'));

      final note = NoteAnnotation(
        id: 'n1',
        documentId: 'doc1',
        pageNumber: 5,
        noteText: 'Important for Prelims',
        createdAt: now,
        updatedAt: now,
      );
      expect(note.noteText, equals('Important for Prelims'));

      final aiAnnotation = AiAnnotation(
        id: 'ai1',
        documentId: 'doc1',
        pageNumber: 5,
        prompt: 'Summarize page',
        aiSummary: 'Summary text',
        keyTakeaways: const ['Point 1'],
        tags: const ['Tag 1'],
      );
      expect(aiAnnotation.aiSummary, equals('Summary text'));
    });
  });
}
