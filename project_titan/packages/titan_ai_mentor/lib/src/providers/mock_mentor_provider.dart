import '../models/mentor_context.dart';
import '../models/mentor_message.dart';
import '../models/mentor_recommendation.dart';
import 'mentor_provider.dart';

/// Offline mock AI provider for testing and fallback operation.
class MockMentorProvider implements MentorProvider {
  final bool shouldSimulateDelay;
  bool shouldFail;

  MockMentorProvider({
    this.shouldSimulateDelay = false,
    this.shouldFail = false,
  });

  @override
  Future<MentorMessage> generateResponse({
    required MentorContext context,
    required List<MentorMessage> history,
    required String userPrompt,
  }) async {
    if (shouldSimulateDelay) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (shouldFail) {
      throw StateError('AI Provider network error');
    }

    final lower = userPrompt.toLowerCase();
    String responseContent;
    final recs = <MentorRecommendation>[];

    if (lower.contains('plan') || lower.contains('schedule')) {
      responseContent =
          'Based on your target of ${context.studyHoursTarget} hours/day for ${context.targetExam}, here is a custom study plan focusing on your weak areas: ${context.weakSubjects.join(", ")}.';
      recs.add(MentorRecommendation(
        id: 'rec_plan_1',
        title: 'Start 2-Hour Polity Block',
        description: 'Review Articles 14 to 32 and complete PYQs.',
        actionType: 'plan',
      ));
    } else if (lower.contains('explain') || lower.contains('concept')) {
      responseContent =
          'Here is a clear breakdown of the concept tailored to your learning profile. Focus on core principles, landmark cases, and recent UPSC trends.';
      recs.add(MentorRecommendation(
        id: 'rec_explain_1',
        title: 'Review Concept Card',
        description: 'Open detailed Knowledge Graph node.',
        actionType: 'explain',
      ));
    } else if (lower.contains('revision') || lower.contains('revise')) {
      responseContent =
          'You currently have ${context.pendingRevisionsCount} items in your revision queue. Revisit spaced repetition flashcards today.';
      recs.add(MentorRecommendation(
        id: 'rec_rev_1',
        title: 'Start Revision Queue',
        description: 'Execute spaced repetition quiz.',
        actionType: 'revise',
      ));
    } else {
      responseContent =
          'Hello ${context.userName}! As your TITAN AI Mentor, I recommend focusing on ${context.recommendedTopic ?? "Indian Polity"} today. How can I assist your study session?';
    }

    return MentorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MentorMessageSender.mentor,
      content: responseContent,
      timestamp: DateTime.now(),
      recommendations: recs,
    );
  }

  @override
  Future<String> summarizeConversation(List<MentorMessage> messages) async {
    if (messages.isEmpty) return 'Empty conversation';
    final userMsgs =
        messages.where((m) => m.sender == MentorMessageSender.user).length;
    return 'Session containing $userMsgs user queries on study guidance and exam strategy.';
  }
}
