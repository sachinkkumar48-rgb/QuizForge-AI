import 'package:titan_quiz/titan_quiz.dart';
import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for generating Computerized Adaptive Testing (CAT) assessments.
class GenerateAdaptiveAssessmentUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const GenerateAdaptiveAssessmentUseCase({
    required this.repository,
    required this.engine,
  });

  Future<Assessment> execute({
    required String title,
    required String subjectCategory,
    required List<QuizQuestion> candidateQuestions,
  }) async {
    final blueprint = engine.generateBlueprint(
      title: title,
      subjectCategory: subjectCategory,
      totalQuestions: candidateQuestions.length,
    );

    final assessment = Assessment(
      id: 'asmt_cat_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description:
          'Adaptive CAT test dynamically calibrated for $subjectCategory',
      type: AssessmentType.adaptiveTest,
      blueprint: blueprint,
      questions: candidateQuestions,
      createdAt: DateTime.now(),
    );

    await repository.saveAssessment(assessment);
    return assessment;
  }
}
