import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('Mentor Use Cases Unit Tests', () {
    late MentorRepository repository;
    late MentorEngine engine;

    setUp(() {
      repository = MentorRepositoryImpl();
      engine = MentorEngine(repository: repository);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('AskMentorUseCase executes prompt and returns response', () async {
      final useCase = AskMentorUseCase(engine);
      final response = await useCase.execute(
        userId: 'uc_1',
        userName: 'Priya',
        prompt: 'What are Fundamental Rights?',
      );

      expect(response.sender, MentorMessageSender.mentor);
      expect(response.content.isNotEmpty, isTrue);
    });

    test('ContinueConversationUseCase appends message to existing session',
        () async {
      final askUseCase = AskMentorUseCase(engine);
      await askUseCase.execute(
        userId: 'uc_2',
        userName: 'Rahul',
        prompt: 'Start session',
      );

      final sessions = await repository.getSessions('uc_2');
      final sessionId = sessions.first.id;

      final continueUseCase = ContinueConversationUseCase(engine);
      final response = await continueUseCase.execute(
        userId: 'uc_2',
        userName: 'Rahul',
        sessionId: sessionId,
        prompt: 'Next question',
      );

      expect(response.sender, MentorMessageSender.mentor);
      final updated = await repository.getSession(sessionId);
      expect(updated?.messages.length, 4); // 2 user + 2 mentor
    });

    test('ExplainConceptUseCase executes concept explanation request',
        () async {
      final useCase = ExplainConceptUseCase(engine);
      final response = await useCase.execute(
        userId: 'uc_3',
        userName: 'Ananya',
        conceptName: 'Basic Structure Doctrine',
      );

      expect(response.sender, MentorMessageSender.mentor);
    });

    test('GenerateStudyPlanUseCase executes study plan prompt', () async {
      final useCase = GenerateStudyPlanUseCase(engine);
      final response = await useCase.execute(
        userId: 'uc_4',
        userName: 'Karan',
      );

      expect(response.sender, MentorMessageSender.mentor);
      expect(response.content, contains('study plan'));
    });

    test('SuggestRevisionUseCase executes revision priority request', () async {
      final useCase = SuggestRevisionUseCase(engine);
      final response = await useCase.execute(
        userId: 'uc_5',
        userName: 'Deepa',
      );

      expect(response.sender, MentorMessageSender.mentor);
    });
  });
}
