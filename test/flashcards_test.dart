import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/flashcards_viewmodel.dart';
import 'package:quizforge_upsc/pages/flashcards_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GARUDA Flashcards & Smart Notes (Sprint 8.3 / TITAN-S8.3.001)', () {
    testWidgets('Verification: FlashcardsPage loads and renders AI Flashcards and navigation controls', (WidgetTester tester) async {
      final viewModel = FlashcardsViewModel(topicId: 't_polity_14');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: FlashcardsPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Tab rendering
      expect(find.text('GARUDA Flashcards & Smart Notes'), findsOneWidget);
      expect(find.text('AI Flashcards'), findsOneWidget);
      expect(find.text('Smart Notes'), findsOneWidget);

      // Verify Card 1 Question
      expect(find.text('What is Article 14 of the Indian Constitution?'), findsOneWidget);
      expect(find.text('Card 1 of 3'), findsOneWidget);

      // Flip Card
      await tester.tap(find.byIcon(Icons.flip_rounded));
      await tester.pumpAndSettle();

      expect(viewModel.isFlipped, isTrue);

      // Next Card
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Card 2 of 3'), findsOneWidget);
      expect(find.textContaining('Kesavananda Bharati'), findsOneWidget);
    });

    testWidgets('Verification: PDF Grounding metadata is displayed when pdfDocumentId is present', (WidgetTester tester) async {
      final viewModel = FlashcardsViewModel(
        topicId: 't_polity_14',
        pdfDocumentId: 'doc_const_summary',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: FlashcardsPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PDF banner metadata
      expect(find.text('PDF Grounded Workspace'), findsOneWidget);
      expect(find.textContaining('PDF: Indian_Constitution_Summary.pdf (Page 14)'), findsOneWidget);
    });

    testWidgets('Verification: Search and Difficulty filters accurately filter flashcard list', (WidgetTester tester) async {
      final viewModel = FlashcardsViewModel(topicId: 't_polity_14');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: FlashcardsPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Filter by 'Hard' difficulty
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      expect(viewModel.flashcards.length, equals(1));
      expect(viewModel.flashcards.first.question, contains('Kesavananda Bharati'));

      // Filter by Search Query
      viewModel.setDifficultyFilter('All');
      viewModel.setSearchQuery('Monetary Policy');
      await tester.pumpAndSettle();

      expect(viewModel.flashcards.length, equals(1));
      expect(viewModel.flashcards.first.topic, equals('Economy'));
    });

    testWidgets('Verification: Adaptive Revision Engine (SM-2 Algorithm) updates ease factor & interval', (WidgetTester tester) async {
      final viewModel = FlashcardsViewModel(topicId: 't_polity_14');
      await viewModel.loadData();

      final initialCard = viewModel.currentCard!;
      expect(initialCard.repetitions, equals(0));
      expect(initialCard.intervalDays, equals(1));

      // Mark Known (Quality 5)
      viewModel.markCardKnown(known: true);

      final updatedCard = viewModel.flashcards.firstWhere((c) => c.id == initialCard.id);
      expect(updatedCard.isKnown, isTrue);
      expect(updatedCard.isInRevisionQueue, isTrue);
      expect(updatedCard.repetitions, equals(1));
      expect(updatedCard.intervalDays, equals(1));
      expect(updatedCard.nextReviewDate, isNotNull);

      // Mark Unknown (Quality 1)
      viewModel.previousCard();
      viewModel.markCardKnown(known: false);
      final resetCard = viewModel.flashcards.firstWhere((c) => c.id == initialCard.id);
      expect(resetCard.repetitions, equals(0));
      expect(resetCard.intervalDays, equals(1));
    });

    testWidgets('Verification: Smart Notes tab renders AI summary, key points, and comparative table', (WidgetTester tester) async {
      final viewModel = FlashcardsViewModel(
        topicId: 't_polity_14',
        pdfDocumentId: 'doc_const_summary',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: FlashcardsPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Smart Notes Tab
      await tester.tap(find.text('Smart Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Comprehensive Notes: Fundamental Rights & Article 14'), findsOneWidget);
      expect(find.text('AI Executive Summary'), findsOneWidget);
      expect(find.textContaining('Article 14 is the cornerstone of democratic equality'), findsOneWidget);
      expect(find.text('Key Takeaways & Points'), findsOneWidget);
      expect(find.text('Comparative Reference Table'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
    });
  });
}
