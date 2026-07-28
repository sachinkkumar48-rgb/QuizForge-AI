import 'package:test/test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('ConversationMemoryManager Tests', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(maxWindowSize: 3);
    });

    test('maintains sliding window history', () {
      const sId = 'sess_1';
      for (int i = 1; i <= 5; i++) {
        manager.addMessage(
          sId,
          MentorMessage(
            id: 'm_$i',
            sender: i % 2 == 1
                ? MentorMessageSender.user
                : MentorMessageSender.mentor,
            content: 'Message $i',
            timestamp: DateTime.now(),
          ),
        );
      }

      expect(manager.getFullHistory(sId).length, equals(5));
      final window = manager.getWindowedHistory(sId);
      expect(window.length, equals(3));
      expect(window.first.content, equals('Message 3'));
      expect(window.last.content, equals('Message 5'));
    });

    test('stores session summaries and recovers session state', () {
      const sId = 'sess_recovery';
      final history = [
        MentorMessage(
          id: 'm1',
          sender: MentorMessageSender.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        ),
      ];

      manager.recoverSession(sId, history, summary: 'Summary of session');
      expect(manager.getFullHistory(sId).length, equals(1));
      expect(manager.getSummary(sId), equals('Summary of session'));
    });
  });
}
