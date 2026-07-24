import '../bookmark.dart';
import '../explanation.dart';
import '../question.dart';
import '../question_statistics.dart';
import '../user_note.dart';

class QuestionWithDetails {
  final Question question;
  final List<Explanation> explanations;
  final Bookmark? bookmark;
  final UserNote? userNote;
  final QuestionStatistics? statistics;
  final String? userSelectedAnswer;

  QuestionWithDetails({
    required this.question,
    this.explanations = const [],
    this.bookmark,
    this.userNote,
    this.statistics,
    this.userSelectedAnswer,
  });

  bool get isBookmarked => bookmark != null;
  bool get hasUserNote => userNote != null && userNote!.content.isNotEmpty;
  bool get isAttempted =>
      userSelectedAnswer != null ||
      (statistics != null && statistics!.totalAttempts > 0);

  Explanation? get officialExplanation =>
      explanations.cast<Explanation?>().firstWhere(
            (e) => e?.explanationType.toLowerCase() == 'official',
            orElse: () => null,
          );

  Explanation? get aiExplanation =>
      explanations.cast<Explanation?>().firstWhere(
            (e) => e?.explanationType.toLowerCase() == 'ai_generated',
            orElse: () => null,
          );

  Explanation? get editorialExplanation =>
      explanations.cast<Explanation?>().firstWhere(
            (e) => e?.explanationType.toLowerCase() == 'editorial',
            orElse: () => null,
          );
}
