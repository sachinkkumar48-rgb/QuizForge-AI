import 'package:meta/meta.dart';

/// Immutable metadata container for a quiz document.
@immutable
class QuizMetadata {
  final int totalQuestions;
  final int estimatedDurationMinutes;
  final String generatedBy;
  final String version;
  final List<String> tags;

  QuizMetadata({
    required this.totalQuestions,
    required this.estimatedDurationMinutes,
    this.generatedBy = 'TITAN AI Generator',
    this.version = '1.0.0',
    List<String>? tags,
  }) : tags = List<String>.unmodifiable(tags ?? const []);

  const QuizMetadata.constMetadata({
    required this.totalQuestions,
    required this.estimatedDurationMinutes,
    required this.generatedBy,
    required this.version,
    required this.tags,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizMetadata || runtimeType != other.runtimeType) {
      return false;
    }
    if (totalQuestions != other.totalQuestions ||
        estimatedDurationMinutes != other.estimatedDurationMinutes ||
        generatedBy != other.generatedBy ||
        version != other.version) {
      return false;
    }
    if (tags.length != other.tags.length) {
      return false;
    }
    for (var i = 0; i < tags.length; i++) {
      if (tags[i] != other.tags[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        totalQuestions,
        estimatedDurationMinutes,
        generatedBy,
        version,
        Object.hashAll(tags),
      );

  @override
  String toString() =>
      'QuizMetadata(questions: $totalQuestions, duration: ${estimatedDurationMinutes}m, by: $generatedBy)';
}
