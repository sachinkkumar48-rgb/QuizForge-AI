import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  final now = DateTime.now();
  final sampleNote = SmartNote(
    id: 'w_n_01',
    title: 'Polity Smart Note',
    content: 'Sample content for testing widgets.',
    type: NoteType.manual,
    knowledgeNodeIds: const ['node_1'],
    sections: const [
      NoteSection(
          id: 'sec_1',
          heading: 'Section 1',
          content: 'Section 1 content',
          orderIndex: 0),
    ],
    tags: const [
      NoteTag(id: 't1', label: 'POLITY'),
    ],
    attachments: const [],
    bookmarks: const [],
    versions: const [],
    comments: const [],
    references: const [],
    highlights: const [],
    annotations: const [],
    summary: NoteSummary(
      overview: 'Summary overview',
      keyTakeaways: const ['Takeaway 1'],
      upscRelevance: const ['GS II'],
    ),
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('SmartNoteCard renders title and tag',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartNoteCard(
            note: sampleNote,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Polity Smart Note'), findsOneWidget);
    expect(find.text('#POLITY'), findsOneWidget);
  });

  testWidgets('AIAssistantPanel renders AI action chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIAssistantPanel(
            onExplainNote: () {},
            onImproveNote: () {},
            onSimplifyNote: () {},
            onGenerateSummary: () {},
            onConvertToFlashcards: () {},
          ),
        ),
      ),
    );

    expect(find.text('AI Note Assistant'), findsOneWidget);
    expect(find.text('Explain Note'), findsOneWidget);
    expect(find.text('AI Summary'), findsOneWidget);
  });

  testWidgets('NoteSummaryCard renders overview and takeaway',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSummaryCard(
            summary: sampleNote.summary!,
          ),
        ),
      ),
    );

    expect(find.text('AI Executive Summary'), findsOneWidget);
    expect(find.text('Summary overview'), findsOneWidget);
    expect(find.text('• Takeaway 1'), findsOneWidget);
  });

  testWidgets('FlashcardGeneratorCard renders flashcard prompt',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashcardGeneratorCard(
            flashcards: const [
              {'front': 'Question 1', 'back': 'Answer 1'},
            ],
            onGenerate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Flashcards (1)'), findsOneWidget);
    expect(find.text('Q: Question 1'), findsOneWidget);
  });
}
