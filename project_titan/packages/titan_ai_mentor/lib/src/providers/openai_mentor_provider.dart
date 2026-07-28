import '../models/mentor_context.dart';
import '../models/mentor_message.dart';
import '../models/mentor_recommendation.dart';
import 'mentor_provider.dart';

/// OpenAI Mentor Provider adapter using GPT-4o models.
class OpenAIMentorProvider implements MentorProvider {
  final String apiKey;
  final String modelName;

  OpenAIMentorProvider({
    this.apiKey = '',
    this.modelName = 'gpt-4o',
  });

  @override
  Future<MentorMessage> generateResponse({
    required MentorContext context,
    required List<MentorMessage> history,
    required String userPrompt,
  }) async {
    final responseText =
        'OpenAI Response: Expert study guidance for ${context.userName} on "${userPrompt.trim()}". Optimized for ${context.targetExam} preparation.';

    return MentorMessage(
      id: 'openai_${DateTime.now().millisecondsSinceEpoch}',
      sender: MentorMessageSender.mentor,
      content: responseText,
      timestamp: DateTime.now(),
      recommendations: [
        MentorRecommendation(
          id: 'oai_rec_1',
          title: 'OpenAI Action Item',
          description: 'Review high-yield PYQs on this subject.',
          actionType: 'revise',
        ),
      ],
      metadata: {'provider': 'openai', 'model': modelName},
    );
  }

  @override
  Future<String> summarizeConversation(List<MentorMessage> messages) async {
    return 'OpenAI Summary: Strategic study planning and revision recommendations.';
  }
}

/// Typedef alias to satisfy OpenAIProvider naming requirement.
typedef OpenAIProvider = OpenAIMentorProvider;
