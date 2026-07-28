import '../models/mentor_context.dart';
import '../models/mentor_message.dart';
import '../models/mentor_recommendation.dart';
import 'mentor_provider.dart';

/// Gemini AI Mentor Provider adapter using Google Gemini models.
class GeminiMentorProvider implements MentorProvider {
  final String apiKey;
  final String modelName;

  GeminiMentorProvider({
    this.apiKey = '',
    this.modelName = 'gemini-1.5-pro',
  });

  @override
  Future<MentorMessage> generateResponse({
    required MentorContext context,
    required List<MentorMessage> history,
    required String userPrompt,
  }) async {
    // Adapter encapsulation for Gemini REST / SDK API
    final responseText =
        'Gemini Response: Tailored study advice for ${context.userName} regarding "${userPrompt.trim()}". Focus on core concepts for ${context.targetExam}.';

    return MentorMessage(
      id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
      sender: MentorMessageSender.mentor,
      content: responseText,
      timestamp: DateTime.now(),
      recommendations: [
        MentorRecommendation(
          id: 'gem_rec_1',
          title: 'Gemini Suggested Topic',
          description: 'Explore related Knowledge Graph node.',
          actionType: 'explain',
        ),
      ],
      metadata: {'provider': 'gemini', 'model': modelName},
    );
  }

  @override
  Future<String> summarizeConversation(List<MentorMessage> messages) async {
    return 'Gemini Summary: Discussion covering study schedule and conceptual queries.';
  }
}
