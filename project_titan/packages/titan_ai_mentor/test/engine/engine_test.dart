import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('Engine Components Unit Tests', () {
    final ctx = MentorContext(
      userId: 'u_1',
      userName: 'Alex',
      weakSubjects: const ['Polity'],
    );

    test('PromptBuilder builds system prompt with learner context', () {
      const builder = PromptBuilder();
      final prompt = builder.buildSystemPrompt(ctx);

      expect(prompt, contains('Alex'));
      expect(prompt, contains('UPSC CSE'));
      expect(prompt, contains('Weak Subjects'));
    });

    test('ContextAssembler builds rich unified context', () async {
      const assembler = ContextAssembler();
      final assembled = await assembler.assembleContext(
        userId: 'u_2',
        userName: 'Priya',
      );

      expect(assembled.userName, 'Priya');
      expect(assembled.weakSubjects.isNotEmpty, isTrue);
      expect(assembled.metadata['assembledModules'], isNotNull);
    });

    test('ContextAssembler integrates 8 TITAN module suppliers correctly',
        () async {
      final assembler = ContextAssembler(
        identitySupplier: (uid) =>
            {'userName': 'Rohan', 'targetExam': 'UPSC Mains'},
        learningProfileSupplier: (uid) => {
          'weakSubjects': ['Economics'],
          'strongSubjects': ['History']
        },
        knowledgeGraphSupplier: (uid) => {'activeConcept': 'Inflation'},
        searchSupplier: (uid) => ['Fiscal Policy'],
        revisionSupplier: (uid) => 7,
        recommendationSupplier: (uid) => 'RBI Monetary Policy',
        plannerSupplier: (uid) => {'target': 8.0, 'completed': 4.5},
        analyticsSupplier: (uid) => 0.88,
      );

      final assembled = await assembler.assembleContext(
        userId: 'u_8',
        userName: 'Default',
      );

      expect(assembled.userName, 'Rohan');
      expect(assembled.targetExam, 'UPSC Mains');
      expect(assembled.weakSubjects, contains('Economics'));
      expect(assembled.strongSubjects, contains('History'));
      expect(assembled.recommendedTopic, 'RBI Monetary Policy');
      expect(assembled.recentSearchQueries, contains('Fiscal Policy'));
      expect(assembled.pendingRevisionsCount, 7);
      expect(assembled.studyHoursTarget, 8.0);
      expect(assembled.studyHoursCompleted, 4.5);
      expect(assembled.accuracyRate, 0.88);
    });

    test('ConversationMemory applies windowing and trigger rules', () {
      const memory = ConversationMemory(maxWindowSize: 3);
      final messages = List.generate(
        5,
        (i) => MentorMessage(
          id: 'msg_$i',
          sender: MentorMessageSender.user,
          content: 'Query $i',
        ),
      );

      final windowed = memory.getWindowedHistory(messages);
      expect(windowed.length, 3);
      expect(windowed.last.content, 'Query 4');
    });

    test('MentorEngine coordinates ask flow and stream broadcast', () async {
      final repo = MentorRepositoryImpl();
      final engine = MentorEngine(repository: repo);

      final response = await engine.ask(
        userId: 'u_eng',
        userName: 'Eng Learner',
        prompt: 'Explain Article 21',
      );

      expect(response.sender, MentorMessageSender.mentor);

      final sessions = await repo.getSessions('u_eng');
      expect(sessions.length, 1);
      expect(sessions.first.messages.length, 2);

      await engine.dispose();
    });
  });
}
