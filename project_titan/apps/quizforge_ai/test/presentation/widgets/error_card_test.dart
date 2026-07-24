import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('ErrorCard Widget Tests', () {
    testWidgets(
        'Renders error message and invokes retry callback on button tap',
        (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              message: 'Failed to import document',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to import document'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });
}
