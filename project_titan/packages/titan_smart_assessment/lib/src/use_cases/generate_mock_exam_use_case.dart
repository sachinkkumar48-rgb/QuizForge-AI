import 'package:titan_quiz/titan_quiz.dart';
import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for generating full-length UPSC Mock Exams.
class GenerateMockExamUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const GenerateMockExamUseCase({
    required this.repository,
    required this.engine,
  });

  Future<Assessment> execute({
    required String title,
    required Map<String, double> topicWeights,
    required List<QuizQuestion> questions,
  }) async {
    final blueprint = engine.generateBlueprint(
      title: title,
      subjectCategory: 'General Studies',
      topicWeights: topicWeights,
      totalQuestions: questions.length,
      timeLimitMinutes: 120,
    );

    final mock = Assessment(
      id: 'asmt_mock_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: 'Full-length UPSC Prelims Mock Exam',
      type: AssessmentType.mockExam,
      blueprint: blueprint,
      questions: questions,
      totalDurationMinutes: 120,
      createdAt: DateTime.now(),
    );

    await repository.saveAssessment(mock);
    return mock;
  }
}
