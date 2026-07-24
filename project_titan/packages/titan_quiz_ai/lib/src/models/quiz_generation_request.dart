import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';

/// Immutable model representing a request to generate a Quiz using AI.
@immutable
class QuizGenerationRequest {
  final String documentId;
  final List<String> chunkIds;
  final QuizDifficulty difficulty;
  final QuizLanguage language;
  final QuizCategory category;
  final int questionsPerChunk;

  QuizGenerationRequest({
    required this.documentId,
    List<String>? chunkIds,
    this.difficulty = QuizDifficulty.medium,
    this.language = QuizLanguage.english,
    this.category = QuizCategory.upsc,
    this.questionsPerChunk = 5,
  }) : chunkIds = List<String>.unmodifiable(chunkIds ?? const []);

  const QuizGenerationRequest.constRequest({
    required this.documentId,
    required this.chunkIds,
    required this.difficulty,
    required this.language,
    required this.category,
    required this.questionsPerChunk,
  });

  /// Creates a modified copy of this [QuizGenerationRequest].
  QuizGenerationRequest copyWith({
    String? documentId,
    List<String>? chunkIds,
    QuizDifficulty? difficulty,
    QuizLanguage? language,
    QuizCategory? category,
    int? questionsPerChunk,
  }) {
    return QuizGenerationRequest(
      documentId: documentId ?? this.documentId,
      chunkIds: chunkIds ?? this.chunkIds,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      category: category ?? this.category,
      questionsPerChunk: questionsPerChunk ?? this.questionsPerChunk,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizGenerationRequest || runtimeType != other.runtimeType) {
      return false;
    }
    if (documentId != other.documentId ||
        difficulty != other.difficulty ||
        language != other.language ||
        category != other.category ||
        questionsPerChunk != other.questionsPerChunk) {
      return false;
    }
    if (chunkIds.length != other.chunkIds.length) {
      return false;
    }
    for (var i = 0; i < chunkIds.length; i++) {
      if (chunkIds[i] != other.chunkIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        documentId,
        Object.hashAll(chunkIds),
        difficulty,
        language,
        category,
        questionsPerChunk,
      );

  @override
  String toString() =>
      'QuizGenerationRequest(doc: $documentId, chunks: ${chunkIds.length}, diff: ${difficulty.name}, lang: ${language.name}, cat: ${category.name}, qPerChunk: $questionsPerChunk)';
}
