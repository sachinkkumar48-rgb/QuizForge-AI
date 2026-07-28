import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Learning Flow Offline Tests', () {
    testWidgets('ProgressOverlay renders sync message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressOverlay(
              message: 'Saving offline progress...',
            ),
          ),
        ),
      );

      expect(find.text('Saving offline progress...'), findsOneWidget);
    });

    testWidgets('ResumeSessionBanner renders session resume prompt',
        (tester) async {
      final session = LearningSession.start(
        sessionId: 's_off',
        userId: 'u_off',
        courseId: 'c1',
        courseTitle: 'History',
        lessonId: 'l1',
        lessonTitle: '1857 Revolt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResumeSessionBanner(
              session: session,
              onResume: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('1857 Revolt'), findsOneWidget);
    });
  });
}
