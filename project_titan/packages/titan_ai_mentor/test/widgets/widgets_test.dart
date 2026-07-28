import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('Material 3 Mentor Widgets Tests', () {
    final now = DateTime.now();

    final userMsg = MentorMessage(
      id: 'm_u',
      sender: MentorMessageSender.user,
      content: 'Explain Article 14',
      timestamp: now,
    );

    final mentorMsg = MentorMessage(
      id: 'm_m',
      sender: MentorMessageSender.mentor,
      content: 'Article 14 guarantees equality before law.',
      timestamp: now,
      recommendations: [
        MentorRecommendation(
          id: 'rec_w1',
          title: 'Review Right to Equality',
          description: 'Open flashcard deck.',
          actionType: 'revise',
        ),
      ],
    );

    testWidgets('MentorMessageBubble renders user and mentor bubbles',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MentorMessageBubble(message: userMsg),
                MentorMessageBubble(message: mentorMsg),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Explain Article 14'), findsOneWidget);
      expect(find.text('Article 14 guarantees equality before law.'),
          findsOneWidget);
      expect(find.text('Review Right to Equality'), findsOneWidget);
    });

    testWidgets('MentorActionCard renders recommendation and responds to press',
        (tester) async {
      var pressed = false;
      final rec = MentorRecommendation(
        id: 'rec_test',
        title: 'Start Practice Quiz',
        description: '10 Polity Questions',
        actionType: 'quiz',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorActionCard(
              recommendation: rec,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Practice Quiz'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('MentorSuggestionCard renders label and triggers callback',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorSuggestionCard(
              label: 'Explain DPSP',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Explain DPSP'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      expect(tapped, isTrue);
    });

    testWidgets('MentorTypingIndicator shows progress when thinking',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MentorTypingIndicator(isThinking: true),
          ),
        ),
      );

      expect(find.text('TITAN Mentor is thinking...'), findsOneWidget);
    });

    testWidgets('MentorSessionList renders session titles and responds to tap',
        (tester) async {
      var selected = false;
      final session = MentorSession(
        id: 'sess_w1',
        userId: 'u_w',
        title: 'Polity Basics',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorSessionList(
              sessions: [session],
              onSessionSelected: (_) => selected = true,
            ),
          ),
        ),
      );

      expect(find.text('Polity Basics'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      expect(selected, isTrue);
    });

    testWidgets('MentorInputBar renders suggestions and sends user text',
        (tester) async {
      final controller = TextEditingController();
      var sentText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorInputBar(
              controller: controller,
              onSend: (text) => sentText = text,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello Mentor');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(sentText, 'Hello Mentor');
    });

    testWidgets('MentorChatView renders chat interface', (tester) async {
      var sentText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorChatView(
              messages: [userMsg, mentorMsg],
              onSend: (text) => sentText = text,
            ),
          ),
        ),
      );

      expect(find.text('Explain Article 14'), findsOneWidget);
      expect(find.text('Article 14 guarantees equality before law.'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Test Chat View Prompt');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(sentText, 'Test Chat View Prompt');
    });
  });
}
