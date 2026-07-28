import 'package:titan_quiz/titan_quiz.dart';
import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for generating practice assessments.
class GeneratePracticeAssessmentUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const GeneratePracticeAssessmentUseCase({
    required this.repository,
    required this.engine,
  });

  Future<Assessment> execute({
    required String title,
    required String subjectCategory,
    required List<QuizQuestion> questions,
  }) async {
    final blueprint = engine.generateBlueprint(
      title: title,
      subjectCategory: subjectCategory,
      totalQuestions: questions.length,
    );

    final assessment = Assessment(
      id: 'asmt_prac_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: 'Practice test for $subjectCategory',
      type: AssessmentType.practiceTest,
      blueprint: blueprint,
      questions: questions,
      createdAt: DateTime.now(),
    );

    await repository.saveAssessment(assessment);
    return assessment;
  }
}
