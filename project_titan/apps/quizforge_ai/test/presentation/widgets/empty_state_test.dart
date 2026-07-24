import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('Renders title, message, and icon cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No Items',
              message: 'List is empty',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('List is empty'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });
  });
}
