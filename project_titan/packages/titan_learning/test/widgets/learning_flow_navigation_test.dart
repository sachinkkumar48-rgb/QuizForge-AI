import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Learning Flow Navigation Tests', () {
    testWidgets('ExitConfirmationDialog renders pause and abandon options',
        (tester) async {
      bool pauseTapped = false;
      bool abandonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationDialog(
              onPauseAndExit: () {
                pauseTapped = true;
              },
              onAbandon: () {
                abandonTapped = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Exit Study Session?'), findsOneWidget);

      await tester.tap(find.text('Pause & Save'));
      await tester.pump();
      expect(pauseTapped, isTrue);

      await tester.tap(find.text('Abandon'));
      await tester.pump();
      expect(abandonTapped, isTrue);
    });

    testWidgets('ContinueDialog triggers onContinue callback', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContinueDialog(
              title: 'Next Chapter',
              message: 'Proceed to Judicial Review?',
              onContinue: () {
                continued = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continued, isTrue);
    });
  });
}
