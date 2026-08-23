import 'package:meta/meta.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';

/// Primary category of recommended study action.
enum StudyNextActionType {
  reviewDue,
  remedyWeakTopic,
  reviewDecliningTopic,
  practiceNewTopic,
  startFirstAssessment,
}

/// Immutable model representing the highest-priority deterministic next step for a learner.
@immutable
class StudyNextRecommendation {
  final StudyNextActionType actionType;
  final String title;
  final String description;
  final String? targetTopic;
  final String? documentId;
  final int? pageNumber;
  final String? sourceChunkId;
  final ReaderDeepLinkRequest? deepLinkRequest;
  final QuizDifficulty recommendedDifficulty;
  final String rationale;

  StudyNextRecommendation({
    required this.actionType,
    required this.title,
    required this.description,
    this.targetTopic,
    this.documentId,
    this.pageNumber,
    this.sourceChunkId,
    this.deepLinkRequest,
    this.recommendedDifficulty = QuizDifficulty.medium,
    required this.rationale,
  });

  const StudyNextRecommendation.constRecommendation({
    required this.actionType,
    required this.title,
    required this.description,
    required this.targetTopic,
    required this.documentId,
    required this.pageNumber,
    required this.sourceChunkId,
    required this.deepLinkRequest,
    required this.recommendedDifficulty,
    required this.rationale,
  });

  bool get hasDeepLink => deepLinkRequest != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyNextRecommendation &&
          runtimeType == other.runtimeType &&
          actionType == other.actionType &&
          title == other.title &&
          targetTopic == other.targetTopic &&
          recommendedDifficulty == other.recommendedDifficulty;

  @override
  int get hashCode => Object.hash(
        actionType,
        title,
        targetTopic,
        recommendedDifficulty,
      );
}
