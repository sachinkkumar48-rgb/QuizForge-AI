import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'generation_statistics.dart';
import 'generated_question.dart';

/// Immutable model representing the result of an assessment generation pipeline execution.
@immutable
class AssessmentGenerationResult {
  final Quiz quiz;
  final List<GeneratedQuestion> generatedQuestions;
  final GenerationStatistics statistics;
  final List<String> warnings;
  final Duration processingTime;

  AssessmentGenerationResult({
    required this.quiz,
    required List<GeneratedQuestion> generatedQuestions,
    required this.statistics,
    List<String>? warnings,
    required this.processingTime,
  })  : generatedQuestions = List.unmodifiable(generatedQuestions),
        warnings = List.unmodifiable(warnings ?? const []);

  const AssessmentGenerationResult.constResult({
    required this.quiz,
    required this.generatedQuestions,
    required this.statistics,
    required this.warnings,
    required this.processingTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentGenerationResult &&
          runtimeType == other.runtimeType &&
          quiz == other.quiz &&
          statistics == other.statistics &&
          processingTime == other.processingTime;

  @override
  int get hashCode => Object.hash(quiz, statistics, processingTime);
}
