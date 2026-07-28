import 'package:flutter_test/flutter_test.dart';
import 'package:titan_live/titan_live.dart';

void main() {
  group('LiveSessionEngine Pure Dart Tests', () {
    late LiveSessionEngine engine;
    late LiveSession initialSession;

    setUp(() {
      initialSession = LiveSession(
        id: 'sess_engine_01',
        liveClassId: 'lc_engine_01',
        status: LiveSessionStatus.scheduled,
        participants: const [],
        chatMessages: const [],
        whiteboardSnapshots: const [],
        resources: const [],
        knowledgeNodeIds: const [],
      );

      engine = LiveSessionEngine(initialSession: initialSession);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('openWaitingRoom, startSession, and endSession transition status', () {
      final waiting = engine.openWaitingRoom();
      expect(waiting.status, equals(LiveSessionStatus.waitingRoomOpen));

      final live = engine.startSession();
      expect(live.status, equals(LiveSessionStatus.live));
      expect(live.actualStartTime, isNotNull);

      final ended = engine.endSession();
      expect(ended.status, equals(LiveSessionStatus.ended));
      expect(ended.actualEndTime, isNotNull);
    });

    test('addParticipant and removeParticipant manage participant list', () {
      final p = Participant(
        id: 'p_1',
        userId: 'u_1',
        name: 'Priya',
        role: ParticipantRole.student,
        joinedAt: DateTime.now(),
      );

      final updatedSession = engine.addParticipant(p);
      expect(updatedSession.participants.length, equals(1));
      expect(updatedSession.participants.first.name, equals('Priya'));

      final leftSession = engine.removeParticipant('u_1');
      expect(leftSession.participants.first.leftAt, isNotNull);
    });

    test('sendChatMessage broadcasts chat event', () async {
      final chatFuture = engine.chatStream.first;

      final msg = engine.sendChatMessage(
        senderId: 'u_2',
        senderName: 'Vikram',
        senderRole: ParticipantRole.student,
        messageText: 'Can you explain the ratio of Kesavananda Bharati?',
      );

      final emitted = await chatFuture;
      expect(emitted.id, equals(msg.id));
      expect(emitted.message, contains('Kesavananda Bharati'));
    });

    test('createPoll, votePoll, and closePoll execute interactive polling', () {
      final poll = engine.createPoll(
        question: 'Which Article covers Right to Equality?',
        optionTexts: ['Article 14', 'Article 19', 'Article 21'],
      );

      expect(poll.options.length, equals(3));
      expect(poll.status, equals(PollStatus.active));

      final votedPoll = engine.votePoll(
        userId: 'u_student_1',
        optionId: poll.options.first.id,
      );

      expect(votedPoll, isNotNull);
      expect(votedPoll!.options.first.voteCount, equals(1));

      final result = engine.closePoll();
      expect(result, isNotNull);
      expect(result!.totalVotes, equals(1));
      expect(result.winningOptionId, equals(poll.options.first.id));
    });

    test('addWhiteboardSnapshot captures drawing snapshot', () {
      final snapshot = engine.addWhiteboardSnapshot(
        title: 'Basic Structure Diagram',
        drawingDataJson: '{"lines": [1, 2, 3]}',
        capturedBy: 'Dr. Sharma',
      );

      expect(snapshot.title, equals('Basic Structure Diagram'));
      expect(engine.currentSession.whiteboardSnapshots.length, equals(1));
    });
  });
}
