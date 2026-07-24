import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('Material 3 Search Widgets Tests', () {
    final now = DateTime.now();

    testWidgets('TitanSearchBar renders input and handles text entry',
        (tester) async {
      final controller = TextEditingController();
      var submittedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TitanSearchBar(
              controller: controller,
              onSubmitted: (val) => submittedText = val,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Polity Notes');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedText, 'Polity Notes');
    });

    testWidgets('SearchResultCard renders title, scope, and handles tap',
        (tester) async {
      var tapped = false;
      final result = SearchResult(
        id: 'r_1',
        title: 'Article 32 Writs',
        snippet: 'Habeas Corpus and Mandamus...',
        scope: SearchScope.notes,
        score: 0.88,
        matchedTerms: const ['Article 32', 'Writs'],
        timestamp: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultCard(
              result: result,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Article 32 Writs'), findsOneWidget);
      expect(find.text('Study Notes'), findsOneWidget);
      expect(find.text('Score 88%'), findsOneWidget);

      await tester.tap(find.byType(SearchResultCard));
      expect(tapped, isTrue);
    });

    testWidgets('SearchFilterChip renders and triggers selection callback',
        (tester) async {
      var isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Exact Match',
              selected: isSelected,
              onSelected: (val) => isSelected = val,
            ),
          ),
        ),
      );

      expect(find.text('Exact Match'), findsOneWidget);

      await tester.tap(find.byType(FilterChip));
      expect(isSelected, isTrue);
    });

    testWidgets('RecentSearchCard renders query and trigger callbacks',
        (tester) async {
      var tapped = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentSearchCard(
              query: 'Geography Monsoon',
              onTap: () => tapped = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Geography Monsoon'), findsOneWidget);

      await tester.tap(find.text('Geography Monsoon'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, isTrue);
    });

    testWidgets('SuggestedQueryCard renders suggestion and responds to tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestedQueryCard(
              suggestion: 'Presidential Powers',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Presidential Powers'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('SearchScopeSelector renders scope chips and handles toggling',
        (tester) async {
      Set<SearchScope> selectedScopes = {SearchScope.pdf};

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: SearchScopeSelector(
                  selectedScopes: selectedScopes,
                  onScopesChanged: (newScopes) {
                    setState(() {
                      selectedScopes = newScopes;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('PDF Documents'), findsOneWidget);
      expect(find.text('Study Notes'), findsOneWidget);

      await tester.tap(find.text('Study Notes'));
      await tester.pump();

      expect(selectedScopes.contains(SearchScope.notes), isTrue);
    });

    testWidgets('SearchEmptyState renders title, message and reset action',
        (tester) async {
      var resetClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              onResetFilters: () => resetClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.text('Reset Scopes & Filters'), findsOneWidget);

      await tester.tap(find.text('Reset Scopes & Filters'));
      expect(resetClicked, isTrue);
    });
  });
}
