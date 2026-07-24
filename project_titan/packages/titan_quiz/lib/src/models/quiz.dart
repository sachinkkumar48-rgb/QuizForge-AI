import 'package:meta/meta.dart';
import '../enums/quiz_category.dart';
import '../enums/quiz_difficulty.dart';
import '../enums/quiz_language.dart';
import 'quiz_metadata.dart';
import 'quiz_question.dart';

/// Immutable domain entity representing a complete Quiz in Project TITAN.
@immutable
class Quiz {
  final String id;
  final String title;
  final String? description;
  final String? sourceDocumentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QuizDifficulty difficulty;
  final QuizLanguage language;
  final QuizCategory category;
  final List<QuizQuestion> questions;
  final QuizMetadata metadata;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    this.sourceDocumentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.difficulty = QuizDifficulty.medium,
    this.language = QuizLanguage.english,
    this.category = QuizCategory.upsc,
    required List<QuizQuestion> questions,
    QuizMetadata? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        questions = List<QuizQuestion>.unmodifiable(questions),
        metadata = metadata ??
            QuizMetadata(
              totalQuestions: questions.length,
              estimatedDurationMinutes: questions.length * 2,
            );

  const Quiz.constQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceDocumentId,
    required this.createdAt,
    required this.updatedAt,
    required this.difficulty,
    required this.language,
    required this.category,
    required this.questions,
    required this.metadata,
  });

  /// Creates a copy of this [Quiz] with updated parameters.
  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? sourceDocumentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    QuizDifficulty? difficulty,
    QuizLanguage? language,
    QuizCategory? category,
    List<QuizQuestion>? questions,
    QuizMetadata? metadata,
  }) {
    final updatedQuestions = questions ?? this.questions;
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      category: category ?? this.category,
      questions: updatedQuestions,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Quiz || runtimeType != other.runtimeType) return false;
    if (id != other.id ||
        title != other.title ||
        description != other.description ||
        sourceDocumentId != other.sourceDocumentId ||
        createdAt != other.createdAt ||
        updatedAt != other.updatedAt ||
        difficulty != other.difficulty ||
        language != other.language ||
        category != other.category ||
        metadata != other.metadata) {
      return false;
    }
    if (questions.length != other.questions.length) return false;
    for (var i = 0; i < questions.length; i++) {
      if (questions[i] != other.questions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        sourceDocumentId,
        createdAt,
        updatedAt,
        difficulty,
        language,
        category,
        Object.hashAll(questions),
        metadata,
      );

  @override
  String toString() =>
      'Quiz($id: "$title", questions: ${questions.length}, category: ${category.name})';
}
