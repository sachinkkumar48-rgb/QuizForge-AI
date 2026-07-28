import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('AI Providers Unit Tests', () {
    final ctx = MentorContext(userId: 'u_test', userName: 'Test Learner');

    test('MockMentorProvider generates contextual response and summary',
        () async {
      final provider = MockMentorProvider();
      final response = await provider.generateResponse(
        context: ctx,
        history: const [],
        userPrompt: 'Please generate a study plan',
      );

      expect(response.sender, MentorMessageSender.mentor);
      expect(response.content, contains('study plan'));
      expect(response.recommendations.isNotEmpty, isTrue);

      final summary = await provider.summarizeConversation([response]);
      expect(summary.isNotEmpty, isTrue);
    });

    test('GeminiMentorProvider generates structured response', () async {
      final provider = GeminiMentorProvider();
      final response = await provider.generateResponse(
        context: ctx,
        history: const [],
        userPrompt: 'Explain Preamble',
      );

      expect(response.sender, MentorMessageSender.mentor);
      expect(response.metadata['provider'], 'gemini');
    });

    test('OpenAIMentorProvider generates structured response', () async {
      final provider = OpenAIMentorProvider();
      final response = await provider.generateResponse(
        context: ctx,
        history: const [],
        userPrompt: 'Suggest revision',
      );

      expect(response.sender, MentorMessageSender.mentor);
      expect(response.metadata['provider'], 'openai');
    });
  });
}
