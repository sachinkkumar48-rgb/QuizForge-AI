library;

import 'package:meta/meta.dart';

/// Available AI reading assistant tasks in TITAN Reader.
enum AIReadingTask {
  /// Explain concepts, terms, or phrases in the selection or document context.
  explain,

  /// Simplify complex or academic language while preserving facts, names, and dates.
  simplify,

  /// Summarize selected text, page, or document (short, medium, or detailed).
  summarize,

  /// Document-grounded Q&A with exact source page citations.
  askQuestion,

  /// Extract core bulleted takeaways and main arguments.
  keyPoints,

  /// Generate study flashcards (front/back) from the content.
  generateFlashcards,

  /// Generate comprehension/revision questions (MCQs, short answer).
  generateQuestions,

  /// Translate the selected content into a target language.
  translate,
}

/// Scope of context provided to the AI reading assistant.
enum AIContextScope {
  /// Selected text snippet only.
  selection,

  /// Current visible page text.
  page,

  /// Entire document (retrieved via chunk indexing / RAG).
  document,
}

/// Detail level for summarization.
enum AISummaryLength { short, medium, detailed }

/// Simplification level.
enum AISimplifyLevel { simple, verySimple }

/// Exact source citation linking an AI answer or explanation back to the PDF.
@immutable
class SourceReference {
  /// Document ID the citation originates from.
  final String documentId;

  /// Page number (1-indexed) in the PDF.
  final int pageNumber;

  /// Optional chunk identifier.
  final String? chunkId;

  /// Exact excerpt matching the citation.
  final String excerpt;

  const SourceReference({
    required this.documentId,
    required this.pageNumber,
    required this.excerpt,
    this.chunkId,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'documentId': documentId,
        'pageNumber': pageNumber,
        'chunkId': chunkId,
        'excerpt': excerpt,
      };

  factory SourceReference.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final excerpt = json['excerpt'];
    if (documentId is! String || pageNumber is! int || excerpt is! String) {
      throw const FormatException(
          'SourceReference JSON requires documentId, pageNumber and excerpt.');
    }
    final chunkId = json['chunkId'];
    return SourceReference(
      documentId: documentId,
      pageNumber: pageNumber,
      excerpt: excerpt,
      chunkId: chunkId is String ? chunkId : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceReference &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          chunkId == other.chunkId &&
          excerpt == other.excerpt;

  @override
  int get hashCode => Object.hash(documentId, pageNumber, chunkId, excerpt);

  @override
  String toString() => 'SourceReference(doc: $documentId, p. $pageNumber)';
}

/// AI-generated study flashcard.
@immutable
class AIFlashcard {
  final String id;
  final String front;
  final String back;
  final String? documentId;
  final int? pageNumber;
  final DateTime createdAt;

  const AIFlashcard({
    required this.id,
    required this.front,
    required this.back,
    this.documentId,
    this.pageNumber,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'front': front,
        'back': back,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AIFlashcard.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final front = json['front'];
    final back = json['back'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        front is! String ||
        back is! String ||
        createdAt is! String) {
      throw const FormatException(
          'AIFlashcard JSON requires id, front, back, and createdAt.');
    }
    return AIFlashcard(
      id: id,
      front: front,
      back: back,
      documentId: json['documentId'] as String?,
      pageNumber: json['pageNumber'] as int?,
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIFlashcard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          front == other.front &&
          back == other.back;

  @override
  int get hashCode => Object.hash(id, front, back);
}

/// AI-generated study question.
@immutable
class AIQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int? correctOptionIndex;
  final String explanation;
  final String? documentId;
  final int? pageNumber;

  const AIQuestion({
    required this.id,
    required this.question,
    this.options = const [],
    this.correctOptionIndex,
    required this.explanation,
    this.documentId,
    this.pageNumber,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'question': question,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        'explanation': explanation,
        'documentId': documentId,
        'pageNumber': pageNumber,
      };

  factory AIQuestion.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final question = json['question'];
    final explanation = json['explanation'];
    if (id is! String || question is! String || explanation is! String) {
      throw const FormatException(
          'AIQuestion JSON requires id, question, and explanation.');
    }
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? List<String>.unmodifiable(rawOptions.whereType<String>())
        : const <String>[];
    return AIQuestion(
      id: id,
      question: question,
      options: options,
      correctOptionIndex: json['correctOptionIndex'] as int?,
      explanation: explanation,
      documentId: json['documentId'] as String?,
      pageNumber: json['pageNumber'] as int?,
    );
  }
}
