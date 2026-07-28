import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_live/titan_live.dart';

void main() {
  group('Chat, Poll, and Attendance Widget & Engine Integration Tests', () {
    testWidgets('ChatPanel renders chat messages and input field',
        (WidgetTester tester) async {
      final textController = TextEditingController();
      final messages = [
        ChatMessage(
          id: 'm1',
          sessionId: 's1',
          senderId: 'u1',
          senderName: 'Rahul',
          senderRole: ParticipantRole.student,
          message: 'What is the case law name?',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanel(
              messages: messages,
              textController: textController,
              onSendPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Rahul • student'), findsOneWidget);
      expect(find.text('What is the case law name?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('PollWidget renders question and selectable options',
        (WidgetTester tester) async {
      final poll = Poll(
        id: 'poll_t1',
        sessionId: 's1',
        question: 'Is Right to Privacy a Fundamental Right?',
        options: const [
          PollOption(id: 'o1', optionText: 'Yes (Article 21)', voteCount: 10),
          PollOption(id: 'o2', optionText: 'No', voteCount: 2),
        ],
        status: PollStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PollWidget(poll: poll),
          ),
        ),
      );

      expect(find.text('LIVE POLL'), findsOneWidget);
      expect(find.text('Is Right to Privacy a Fundamental Right?'),
          findsOneWidget);
      expect(find.text('Yes (Article 21)'), findsOneWidget);
      expect(find.text('10 votes'), findsOneWidget);
    });

    testWidgets('AttendanceCard and InstructorProfileCard render details',
        (WidgetTester tester) async {
      final attendance = Attendance(
        id: 'a1',
        sessionId: 's1',
        userId: 'u1',
        userName: 'Aspirant Rahul',
        joinedAt: DateTime.now(),
        watchDurationMinutes: 45,
      );

      const instructor = InstructorSession(
        id: 'i1',
        instructorId: 'dr_s',
        instructorName: 'Dr. Sharma',
        title: 'Senior UPSC Faculty - Polity',
        bio: '15+ years experience mentoring IAS aspirants.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AttendanceCard(attendance: attendance),
                const InstructorProfileCard(instructor: instructor),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Aspirant Rahul'), findsOneWidget);
      expect(find.text('Dr. Sharma'), findsOneWidget);
      expect(find.text('Senior UPSC Faculty - Polity'), findsOneWidget);
    });
  });
}
