import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Smart Assessment Use Cases Tests', () {
    late AssessmentRepository repository;
    late AssessmentEngine engine;

    setUp(() {
      repository = AssessmentRepositoryImpl();
      engine = const AssessmentEngine();
    });

    test('StartAssessmentUseCase starts session in progress', () async {
      final useCase = StartAssessmentUseCase(
        repository: repository,
        engine: engine,
      );

      final session = await useCase.execute(
        assessmentId: 'asmt100',
        userId: 'user1',
      );

      expect(session.assessmentId, equals('asmt100'));
      expect(session.status, equals(AssessmentStatus.inProgress));
    });

    test('SubmitAnswerUseCase records attempt and increments question index',
        () async {
      final startUseCase = StartAssessmentUseCase(
        repository: repository,
        engine: engine,
      );
      final session = await startUseCase.execute(
        assessmentId: 'asmt100',
        userId: 'user1',
      );

      final submitUseCase = SubmitAnswerUseCase(
        repository: repository,
        engine: engine,
      );

      final updated = await submitUseCase.execute(
        sessionId: session.id,
        questionId: 'q1',
        selectedOptionId: 'optA',
        isCorrect: true,
      );

      expect(updated.attempts, hasLength(1));
      expect(updated.currentQuestionIndex, equals(1));
    });

    test('FinishAssessmentUseCase updates status to completed', () async {
      final startUseCase = StartAssessmentUseCase(
        repository: repository,
        engine: engine,
      );
      final session = await startUseCase.execute(
        assessmentId: 'asmt100',
        userId: 'user1',
      );

      final finishUseCase = FinishAssessmentUseCase(
        repository: repository,
        engine: engine,
      );

      final finished = await finishUseCase.execute(session.id);
      expect(finished.status, equals(AssessmentStatus.completed));
      expect(finished.completedAt, isNotNull);
    });

    test('GeneratePracticeAssessmentUseCase creates practice test', () async {
      final useCase = GeneratePracticeAssessmentUseCase(
        repository: repository,
        engine: engine,
      );

      final practice = await useCase.execute(
        title: 'Polity Practice 1',
        subjectCategory: 'Polity',
        questions: const [],
      );

      expect(practice.type, equals(AssessmentType.practiceTest));
      final saved = await repository.getAssessment(practice.id);
      expect(saved, isNotNull);
    });
  });
}
