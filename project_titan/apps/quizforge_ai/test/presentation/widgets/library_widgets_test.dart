import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/widgets/library/continue_reading_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/library/document_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/library/favorites_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/library/folder_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/library/library_search_bar.dart';
import 'package:titan_content/titan_content.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Digital Library M3 Widgets Tests', () {
    final sampleDoc = LibraryDocument(
      id: 'doc_1',
      title: 'UPSC Polity Notes',
      filePath: '/path/polity.pdf',
      fileSize: 2048000,
      pageCount: 50,
      category: 'Polity',
      isFavorite: true,
      createdAt: DateTime.now(),
      lastReadAt: DateTime.now(),
      progress: ReadingProgress(
        currentPage: 25,
        totalPages: 50,
        completionPercentage: 50.0,
        lastReadAt: DateTime.now(),
      ),
    );

    testWidgets('FolderCard renders folder details', (tester) async {
      final folder = LibraryFolder(
        id: 'f1',
        name: 'GS-2 Polity',
        iconName: 'gavel',
        category: 'Polity',
        documentIds: const ['doc_1'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestableWidget(FolderCard(folder: folder)));

      expect(find.text('GS-2 Polity'), findsOneWidget);
      expect(find.text('1 Document'), findsOneWidget);
    });

    testWidgets('DocumentCard renders title, category, and progress',
        (tester) async {
      await tester
          .pumpWidget(buildTestableWidget(DocumentCard(document: sampleDoc)));

      expect(find.text('UPSC Polity Notes'), findsOneWidget);
      expect(find.text('Polity'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('ContinueReadingCard renders current page and Resume button',
        (tester) async {
      await tester.pumpWidget(
          buildTestableWidget(ContinueReadingCard(document: sampleDoc)));

      expect(find.text('Continue Reading'), findsOneWidget);
      expect(find.text('Page 25 of 50'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('FavoritesCard renders starred items', (tester) async {
      await tester.pumpWidget(
          buildTestableWidget(FavoritesCard(favorites: [sampleDoc])));

      expect(find.text('Starred & Favorites'), findsOneWidget);
      expect(find.text('UPSC Polity Notes'), findsOneWidget);
    });

    testWidgets('LibrarySearchBar renders search field and filter chips',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LibrarySearchBar(
            searchQuery: 'Polity',
            selectedCategory: 'Polity',
          ),
        ),
      );

      expect(find.text('Polity'), findsAtLeastNWidgets(1));
      expect(find.byType(FilterChip), findsAtLeastNWidgets(1));
    });
  });
}
