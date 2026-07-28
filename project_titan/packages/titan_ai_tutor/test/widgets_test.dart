import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Tutor M3 Responsive Widgets Tests', () {
    testWidgets('TutorLessonCard renders correctly', (tester) async {
      final lesson = TutorLesson(
        id: 'l1',
        title: 'Fundamental Rights Overview',
        conceptId: 'c1',
        explanation: 'Detailed overview of Part III.',
        analogy: 'Shield protecting citizen rights',
        mnemonic: 'F.R.E.E.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorLessonCard(lesson: lesson),
          ),
        ),
      );

      expect(find.text('Fundamental Rights Overview'), findsOneWidget);
      expect(find.text('Detailed overview of Part III.'), findsOneWidget);
      expect(find.textContaining('Shield protecting'), findsOneWidget);
    });

    testWidgets('TutorProgressCard renders progress bar and mastery',
        (tester) async {
      final progress = TutorProgress(
        conceptId: 'c1',
        masteryLevel: 75.0,
        confidenceLevel: 0.8,
        lastAttemptAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorProgressCard(progress: progress),
          ),
        ),
      );

      expect(find.text('Mastery Progress'), findsOneWidget);
      expect(find.text('Score: 75.0%'), findsOneWidget);
    });

    testWidgets('TutorChatView renders input field and sends message',
        (tester) async {
      final session = TutorSession(
        id: 's1',
        learnerId: 'u1',
        conceptId: 'c1',
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorChatView(
              session: session,
              onSendMessage: (msg) => sentText = msg,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Explain Article 14');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(sentText, equals('Explain Article 14'));
    });
  });
}
