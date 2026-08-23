import 'package:meta/meta.dart';
import 'package:titan_pdf/titan_pdf.dart';

/// Represents actionable remedial recommendation pathways generated from weak-area performance.
enum RemedialActionType {
  /// Deep link navigation directly to the source document page in TITAN Reader.
  reviewSource,

  /// Re-attempting the incorrect or weak questions in a filtered quiz session.
  retryQuestions,

  /// Generating a targeted micro-assessment on the weak topic (Architecture-ready).
  generateMiniQuiz,

  /// Generating revision flashcards for the weak topic (Architecture-ready).
  generateFlashcards;

  String get label {
    switch (this) {
      case RemedialActionType.reviewSource:
        return 'Study in TITAN Reader';
      case RemedialActionType.retryQuestions:
        return 'Retry Questions';
      case RemedialActionType.generateMiniQuiz:
        return 'Generate Mini-Quiz';
      case RemedialActionType.generateFlashcards:
        return 'Generate Flashcards';
    }
  }
}

/// Immutable model representing a remedial study recommendation for a specific weak topic or document section.
@immutable
class RemedialStudyRecommendation {
  final String id;
  final String documentId;
  final String topic;
  final List<String> sourceChunkIds;
  final List<int> pageNumbers;
  final String reason;
  final int priority;
  final RemedialActionType recommendedAction;
  final ReaderDeepLinkRequest? deepLinkRequest;

  RemedialStudyRecommendation({
    required this.id,
    required this.documentId,
    required this.topic,
    List<String>? sourceChunkIds,
    List<int>? pageNumbers,
    required this.reason,
    this.priority = 1,
    this.recommendedAction = RemedialActionType.reviewSource,
    this.deepLinkRequest,
  })  : sourceChunkIds = List.unmodifiable(sourceChunkIds ?? const []),
        pageNumbers = List.unmodifiable(pageNumbers ?? const []);

  const RemedialStudyRecommendation.constRec({
    required this.id,
    required this.documentId,
    required this.topic,
    required this.sourceChunkIds,
    required this.pageNumbers,
    required this.reason,
    required this.priority,
    required this.recommendedAction,
    required this.deepLinkRequest,
  });

  /// Primary page number for deep-link jumping.
  int get primaryPageNumber => pageNumbers.isNotEmpty ? pageNumbers.first : 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedialStudyRecommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          topic == other.topic &&
          reason == other.reason &&
          priority == other.priority &&
          recommendedAction == other.recommendedAction;

  @override
  int get hashCode => Object.hash(
        id,
        documentId,
        topic,
        reason,
        priority,
        recommendedAction,
      );

  @override
  String toString() =>
      'RemedialStudyRecommendation(topic: $topic, action: ${recommendedAction.name}, page: $primaryPageNumber)';
}
