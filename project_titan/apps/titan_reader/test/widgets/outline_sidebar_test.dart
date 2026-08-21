import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/widgets/outline_sidebar.dart';

import '../support/fake_pdf_engine.dart';

void main() {
  late FakeViewerHandle fakeHandle;

  setUp(() {
    fakeHandle = FakeViewerHandle();
  });

  Widget buildSidebar({
    int currentPage = 1,
    void Function(ReaderOutlineEntry)? onEntrySelected,
    VoidCallback? onClose,
    double width = 260,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OutlineSidebar(
          handle: fakeHandle,
          currentPage: currentPage,
          onEntrySelected: onEntrySelected,
          onClose: onClose,
          width: width,
        ),
      ),
    );
  }

  group('OutlineSidebar Widget Tests', () {
    testWidgets('renders empty state when document has no outline',
        (tester) async {
      fakeHandle.scriptedOutline = const [];

      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('Table of Contents'), findsOneWidget);
      expect(
          find.text('This document has no table of contents.'), findsOneWidget);
      expect(find.byKey(const Key('outline-tree-list-view')), findsNothing);
      expect(find.byKey(const Key('outline-search-field')), findsNothing);
    });

    testWidgets('renders single-level outline entries with page badges',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(
            title: 'Chapter 1: Overview', path: '0', pageNumber: 1),
        ReaderOutlineEntry(title: 'Chapter 2: Setup', path: '1', pageNumber: 5),
        ReaderOutlineEntry(
            title: 'Chapter 3: Conclusion', path: '2', pageNumber: 12),
      ];

      await tester.pumpWidget(buildSidebar(currentPage: 5));
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1: Overview'), findsOneWidget);
      expect(find.text('Chapter 2: Setup'), findsOneWidget);
      expect(find.text('Chapter 3: Conclusion'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Active item styling
      final activeNode = find.byKey(const Key('outline-node-1'));
      expect(activeNode, findsOneWidget);
    });

    testWidgets('tapping an outline entry calls goToOutlineEntry and callback',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(title: 'Introduction', path: '0', pageNumber: 1),
        ReaderOutlineEntry(title: 'Deep Dive', path: '1', pageNumber: 15),
      ];

      ReaderOutlineEntry? selectedEntry;

      await tester.pumpWidget(buildSidebar(
        currentPage: 1,
        onEntrySelected: (entry) => selectedEntry = entry,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('outline-node-1')));
      await tester.pumpAndSettle();

      expect(fakeHandle.visitedOutlinePaths, contains('1'));
      expect(fakeHandle.currentPageNumber, equals(15));
      expect(selectedEntry?.title, equals('Deep Dive'));
    });

    testWidgets(
        'renders multi-level nested outline hierarchy with expansion toggle',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(
          title: 'Part I: Foundations',
          path: '0',
          pageNumber: 1,
          children: [
            ReaderOutlineEntry(
              title: '1.1 Principles',
              path: '0/0',
              pageNumber: 2,
            ),
            ReaderOutlineEntry(
              title: '1.2 Architecture',
              path: '0/1',
              pageNumber: 8,
              children: [
                ReaderOutlineEntry(
                  title: '1.2.1 Data Layer',
                  path: '0/1/0',
                  pageNumber: 10,
                ),
              ],
            ),
          ],
        ),
        ReaderOutlineEntry(
          title: 'Part II: Execution',
          path: '1',
          pageNumber: 20,
        ),
      ];

      await tester.pumpWidget(buildSidebar(currentPage: 1));
      await tester.pumpAndSettle();

      expect(find.text('Part I: Foundations'), findsOneWidget);
      expect(find.text('1.1 Principles'), findsOneWidget);
      expect(find.text('1.2 Architecture'), findsOneWidget);
      expect(find.text('1.2.1 Data Layer'), findsOneWidget);
      expect(find.text('Part II: Execution'), findsOneWidget);

      // Collapse Part I
      await tester.tap(find.byKey(const Key('toggle-expand-0')));
      await tester.pumpAndSettle();

      expect(find.text('Part I: Foundations'), findsOneWidget);
      expect(find.text('1.1 Principles'), findsNothing);
      expect(find.text('1.2 Architecture'), findsNothing);

      // Expand Part I again
      await tester.tap(find.byKey(const Key('toggle-expand-0')));
      await tester.pumpAndSettle();

      expect(find.text('1.1 Principles'), findsOneWidget);
      expect(find.text('1.2 Architecture'), findsOneWidget);
    });

    testWidgets('expand all and collapse all buttons toggle entire tree',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(
          title: 'Section A',
          path: '0',
          pageNumber: 1,
          children: [
            ReaderOutlineEntry(title: 'A.1', path: '0/0', pageNumber: 2),
          ],
        ),
        ReaderOutlineEntry(
          title: 'Section B',
          path: '1',
          pageNumber: 5,
          children: [
            ReaderOutlineEntry(title: 'B.1', path: '1/0', pageNumber: 6),
          ],
        ),
      ];

      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('A.1'), findsOneWidget);
      expect(find.text('B.1'), findsOneWidget);

      // Collapse all
      await tester.tap(find.byKey(const Key('outline-collapse-all-button')));
      await tester.pumpAndSettle();

      expect(find.text('A.1'), findsNothing);
      expect(find.text('B.1'), findsNothing);

      // Expand all
      await tester.tap(find.byKey(const Key('outline-expand-all-button')));
      await tester.pumpAndSettle();

      expect(find.text('A.1'), findsOneWidget);
      expect(find.text('B.1'), findsOneWidget);
    });

    testWidgets('filters outline tree by search query and clears filter',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(
            title: 'Authentication & Security', path: '0', pageNumber: 1),
        ReaderOutlineEntry(title: 'Database Schema', path: '1', pageNumber: 10),
        ReaderOutlineEntry(title: 'API Reference', path: '2', pageNumber: 25),
      ];

      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('Authentication & Security'), findsOneWidget);
      expect(find.text('Database Schema'), findsOneWidget);
      expect(find.text('API Reference'), findsOneWidget);

      // Filter by 'Database'
      await tester.enterText(
          find.byKey(const Key('outline-search-field')), 'Database');
      await tester.pumpAndSettle();

      expect(find.text('Database Schema'), findsOneWidget);
      expect(find.text('Authentication & Security'), findsNothing);
      expect(find.text('API Reference'), findsNothing);

      // Clear search
      await tester.tap(find.byKey(const Key('clear-outline-search-button')));
      await tester.pumpAndSettle();

      expect(find.text('Authentication & Security'), findsOneWidget);
      expect(find.text('Database Schema'), findsOneWidget);
      expect(find.text('API Reference'), findsOneWidget);
    });

    testWidgets(
        'handles outline entries with null/missing page destinations gracefully',
        (tester) async {
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(
            title: 'External Web Link', path: '0', pageNumber: null),
        ReaderOutlineEntry(title: 'Normal Page', path: '1', pageNumber: 4),
      ];

      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('External Web Link'), findsOneWidget);
      expect(find.text('Normal Page'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Tap entry with null pageNumber
      await tester.tap(find.byKey(const Key('outline-node-0')));
      await tester.pumpAndSettle();

      expect(fakeHandle.visitedOutlinePaths, contains('0'));
    });

    testWidgets('exposes close button and fires onClose callback',
        (tester) async {
      var closed = false;
      fakeHandle.scriptedOutline = const [
        ReaderOutlineEntry(title: 'Cover', path: '0', pageNumber: 1),
      ];

      await tester.pumpWidget(buildSidebar(onClose: () => closed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('close-outline-sidebar-button')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });
  });
}
