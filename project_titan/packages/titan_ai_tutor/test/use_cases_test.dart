import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Tutor Engine Use Cases Tests', () {
    late TutorRepository repository;
    late TutorEngine engine;
    late TutorConcept sampleConcept;

    setUp(() {
      repository = TutorRepositoryImpl();
      engine = const TutorEngine();
      sampleConcept = const TutorConcept(
        id: 'c1',
        title: 'Basic Structure Doctrine',
        description: 'Kesavananda Bharati case 1973',
        subjectCategory: 'Polity',
        prerequisiteConceptIds: [],
        relatedTopicIds: [],
      );
    });

    test('StartTutorSessionUseCase starts active session', () async {
      final useCase = StartTutorSessionUseCase(
        repository: repository,
        engine: engine,
      );

      final session = await useCase.execute(
        learnerId: 'learner1',
        conceptId: 'c1',
        persona: TutorPersona.upscMode,
      );

      expect(session.learnerId, equals('learner1'));
      expect(session.status, equals(TutorSessionStatus.active));
      expect(session.persona, equals(TutorPersona.upscMode));
    });

    test('ContinueTutorSessionUseCase updates session state', () async {
      final startUseCase = StartTutorSessionUseCase(
        repository: repository,
        engine: engine,
      );
      final session = await startUseCase.execute(
        learnerId: 'learner1',
        conceptId: 'c1',
      );

      final continueUseCase = ContinueTutorSessionUseCase(
        repository: repository,
        engine: engine,
      );

      final updated = await continueUseCase.execute(
        sessionId: session.id,
        userResponse:
            'The Basic Structure doctrine limits amending power of Parliament.',
      );

      expect(updated.status, equals(TutorSessionStatus.active));
    });

    test('ExplainConceptUseCase saves and returns lesson', () async {
      final useCase = ExplainConceptUseCase(
        engine: engine,
        repository: repository,
      );

      final lesson = await useCase.execute(
        concept: sampleConcept,
        persona: TutorPersona.beginner,
      );

      expect(lesson.conceptId, equals('c1'));
      final saved = await repository.getLesson(lesson.id);
      expect(saved, isNotNull);
    });

    test('EvaluateAnswerUseCase evaluates answer and updates progress',
        () async {
      final useCase = EvaluateAnswerUseCase(
        engine: engine,
        repository: repository,
      );

      const exercise = TutorExercise(
        id: 'ex1',
        conceptId: 'c1',
        title: 'Doctrine exercise',
        prompt: 'What is basic structure?',
      );

      final eval = await useCase.execute(
        exercise: exercise,
        studentResponse: 'It protects fundamental features of Constitution.',
        concept: sampleConcept,
      );

      expect(eval.score, greaterThan(50.0));
      final progress = await repository.getProgress('c1');
      expect(progress, isNotNull);
      expect(progress!.exercisesAttempted, equals(1));
    });

    test('EndTutorSessionUseCase marks session completed', () async {
      final startUseCase = StartTutorSessionUseCase(
        repository: repository,
        engine: engine,
      );
      final session = await startUseCase.execute(
        learnerId: 'learner1',
        conceptId: 'c1',
      );

      final endUseCase = EndTutorSessionUseCase(
        repository: repository,
        engine: engine,
      );

      final ended = await endUseCase.execute(session.id);
      expect(ended.status, equals(TutorSessionStatus.completed));
      expect(ended.evaluation, isNotNull);
    });
  });
}
