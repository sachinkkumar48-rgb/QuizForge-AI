import 'package:titan_quiz/titan_quiz.dart';
import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';

/// Use case for analyzing assessment performance and skill gaps.
class AnalyzePerformanceUseCase {
  final AssessmentEngine engine;

  const AnalyzePerformanceUseCase({required this.engine});

  Future<AssessmentAnalysis> execute({
    required AssessmentSession session,
    required List<QuizQuestion> questions,
    required String assessmentId,
  }) async {
    return engine.analyzeSkillGaps(
      session: session,
      questions: questions,
      assessmentId: assessmentId,
    );
  }
}
