import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'generation_statistics.dart';

/// Immutable model representing the output result of an AI quiz generation pipeline run.
@immutable
class QuizGenerationResult {
  final Quiz quiz;
  final List<String> warnings;
  final GenerationStatistics statistics;
  final Duration processingTime;

  QuizGenerationResult({
    required this.quiz,
    List<String>? warnings,
    required this.statistics,
    required this.processingTime,
  }) : warnings = List<String>.unmodifiable(warnings ?? const []);

  const QuizGenerationResult.constResult({
    required this.quiz,
    required this.warnings,
    required this.statistics,
    required this.processingTime,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizGenerationResult || runtimeType != other.runtimeType) {
      return false;
    }
    if (quiz != other.quiz ||
        statistics != other.statistics ||
        processingTime != other.processingTime) {
      return false;
    }
    if (warnings.length != other.warnings.length) {
      return false;
    }
    for (var i = 0; i < warnings.length; i++) {
      if (warnings[i] != other.warnings[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        quiz,
        Object.hashAll(warnings),
        statistics,
        processingTime,
      );

  @override
  String toString() =>
      'QuizGenerationResult(quiz: "${quiz.title}", questions: ${quiz.questions.length}, warnings: ${warnings.length}, time: ${processingTime.inMilliseconds}ms)';
}
