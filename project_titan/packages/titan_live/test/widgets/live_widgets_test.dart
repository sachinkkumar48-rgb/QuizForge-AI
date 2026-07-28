import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_live/titan_live.dart';

void main() {
  group('Live Classes Material 3 Widgets Tests', () {
    late LiveClass sampleClass;
    late LiveSession sampleSession;

    setUp(() {
      final now = DateTime.now();
      sampleSession = LiveSession(
        id: 'sess_w_01',
        liveClassId: 'lc_w_01',
        status: LiveSessionStatus.live,
        actualStartTime: now,
        participants: [
          Participant(
            id: 'p_w_1',
            userId: 'u_1',
            name: 'Priya',
            role: ParticipantRole.student,
            joinedAt: now,
          ),
        ],
        chatMessages: const [],
        whiteboardSnapshots: const [],
        resources: const [],
        knowledgeNodeIds: const [],
      );

      sampleClass = LiveClass(
        id: 'lc_w_01',
        title: 'Polity Article 21 Masterclass',
        description: 'Right to Life and Personal Liberty.',
        subjectCategory: 'Polity',
        instructorId: 'inst_01',
        instructorName: 'Dr. Sharma',
        schedule: SessionSchedule(
          id: 'sch_w_01',
          liveClassId: 'lc_w_01',
          scheduledStartTime: now.add(const Duration(hours: 1)),
          scheduledEndTime: now.add(const Duration(hours: 3)),
        ),
        activeSession: sampleSession,
        knowledgeNodeIds: const [],
        createdAt: now,
      );
    });

    testWidgets('LiveClassCard renders title, instructor, and join button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveClassCard(
              liveClass: sampleClass,
              onJoinTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Polity Article 21 Masterclass'), findsOneWidget);
      expect(find.text('Dr. Sharma'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Join LIVE'), findsOneWidget);
    });

    testWidgets('LivePlayer renders player container with LIVE badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePlayer(session: sampleSession),
          ),
        ),
      );

      expect(find.text('LIVE CLASS IN PROGRESS'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('ParticipantGrid renders connected participant tiles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticipantGrid(participants: sampleSession.participants),
          ),
        ),
      );

      expect(find.text('Priya'), findsOneWidget);
    });

    testWidgets('UpcomingClassesCard renders class list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingClassesCard(upcomingClasses: [sampleClass]),
          ),
        ),
      );

      expect(find.text('Upcoming Live Classes'), findsOneWidget);
      expect(find.text('Polity Article 21 Masterclass'), findsOneWidget);
    });
  });
}
