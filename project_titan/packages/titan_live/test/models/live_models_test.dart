import 'package:flutter_test/flutter_test.dart';
import 'package:titan_live/titan_live.dart';

void main() {
  group('Live Classes Domain Models Tests', () {
    test('Participant instantiates and serializes to JSON round-trip', () {
      final now = DateTime.now();
      final participant = Participant(
        id: 'p_01',
        userId: 'u_100',
        name: 'Aspirant Rahul',
        role: ParticipantRole.student,
        joinedAt: now,
        isHandRaised: true,
        isMuted: false,
        isVideoOn: true,
      );

      expect(participant.name, equals('Aspirant Rahul'));
      expect(participant.role, equals(ParticipantRole.student));
      expect(participant.isHandRaised, isTrue);

      final json = participant.toJson();
      final restored = Participant.fromJson(json);

      expect(restored.id, equals(participant.id));
      expect(restored.userId, equals(participant.userId));
      expect(restored.name, equals(participant.name));
      expect(restored.isHandRaised, equals(participant.isHandRaised));
    });

    test('ChatMessage instantiates and converts to JSON correctly', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'msg_01',
        sessionId: 'sess_100',
        senderId: 'inst_01',
        senderName: 'Dr. Sharma',
        senderRole: ParticipantRole.instructor,
        message: 'Important discussion on Article 21.',
        type: ChatMessageType.announcement,
        timestamp: now,
        isPinned: true,
      );

      final json = message.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, equals('msg_01'));
      expect(restored.message, contains('Article 21'));
      expect(restored.type, equals(ChatMessageType.announcement));
      expect(restored.isPinned, isTrue);
    });

    test('LiveSessionStatusX and PollOption behave as expected', () {
      expect(LiveSessionStatus.live.label, equals('LIVE'));
      expect(LiveSessionStatus.scheduled.label, equals('Scheduled'));

      const option = PollOption(
        id: 'opt_1',
        optionText: 'Puttaswamy Case',
        voteCount: 15,
      );
      expect(option.voteCount, equals(15));
      expect(option.optionText, equals('Puttaswamy Case'));
    });
  });
}
