import '../models/mentor_context.dart';
import '../models/mentor_message.dart';

/// Builder service for assembling system prompts and context-infused instructions for AI.
class PromptBuilder {
  const PromptBuilder();

  /// Constructs the system prompt incorporating [context] from all TITAN packages.
  String buildSystemPrompt(MentorContext context) {
    final buffer = StringBuffer()
      ..writeln(
          'You are TITAN AI Mentor 2.0, a world-class personalized learning companion for ${context.targetExam}.')
      ..writeln('Learner Name: ${context.userName}')
      ..writeln('Target Exam: ${context.targetExam}');

    if (context.weakSubjects.isNotEmpty) {
      buffer.writeln(
          'Weak Subjects / Focus Areas: ${context.weakSubjects.join(", ")}');
    }
    if (context.strongSubjects.isNotEmpty) {
      buffer.writeln('Strong Subjects: ${context.strongSubjects.join(", ")}');
    }
    if (context.recommendedTopic != null) {
      buffer
          .writeln('Currently Recommended Topic: ${context.recommendedTopic}');
    }
    buffer.writeln(
        'Daily Target: ${context.studyHoursTarget} hrs | Completed: ${context.studyHoursCompleted} hrs');
    buffer.writeln(
        'Accuracy Rate: ${(context.accuracyRate * 100).toStringAsFixed(1)}% | Pending Revisions: ${context.pendingRevisionsCount}');
    if (context.recentSearchQueries.isNotEmpty) {
      buffer.writeln(
          'Recent Search Queries: ${context.recentSearchQueries.take(3).join(", ")}');
    }

    buffer.writeln('\nInstructions:');
    buffer.writeln(
        '1. Provide clear, authoritative, and encouragement-driven study advice.');
    buffer.writeln(
        '2. Break down complex concepts into structured bullet points with UPSC relevance.');
    buffer.writeln(
        '3. Proactively suggest revision, study plan updates, or practice questions when appropriate.');

    return buffer.toString();
  }

  /// Formats conversation [history] into prompt turns.
  List<Map<String, String>> formatHistory(List<MentorMessage> history) {
    return history.map((msg) {
      return {
        'role': msg.sender == MentorMessageSender.user ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();
  }
}
