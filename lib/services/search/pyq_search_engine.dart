import '../../models/view/question_with_details.dart';
import '../../repositories/bookmark_repository.dart';
import '../../repositories/explanation_repository.dart';
import '../../repositories/question_repository.dart';
import '../../repositories/user_note_repository.dart';
import 'inverted_index.dart';
import 'search_query.dart';
import 'search_result.dart';

class PyqSearchEngine {
  final QuestionRepository questionRepository;
  final ExplanationRepository explanationRepository;
  final BookmarkRepository bookmarkRepository;
  final UserNoteRepository userNoteRepository;

  final InvertedIndex _index = InvertedIndex();

  PyqSearchEngine({
    required this.questionRepository,
    required this.explanationRepository,
    required this.bookmarkRepository,
    required this.userNoteRepository,
  });

  bool _isIndexBuilt = false;
  bool get isIndexBuilt => _isIndexBuilt;

  /// Build or rebuild the full inverted search index from local repositories
  Future<void> buildIndex({
    List<QuestionWithDetails>? preloadedDetails,
    Map<String, List<double>>? vectorsMap,
  }) async {
    _index.clear();

    if (preloadedDetails != null) {
      for (final detail in preloadedDetails) {
        final vector = vectorsMap?[detail.question.id];
        _index.index(detail, embeddingVector: vector);
      }
      _isIndexBuilt = true;
      return;
    }

    final questions = await questionRepository.getAllQuestions();

    for (final q in questions) {
      final explanations = await explanationRepository.getExplanations(q.id);
      final note = await userNoteRepository.getNoteForQuestion(q.id);
      final bookmark = await bookmarkRepository.getBookmark(q.id);

      final detail = QuestionWithDetails(
        question: q,
        explanations: explanations,
        userNote: note,
        bookmark: bookmark,
      );

      final vector = vectorsMap?[q.id];
      _index.index(detail, embeddingVector: vector);
    }

    _isIndexBuilt = true;
  }

  /// Instant high-performance search execution
  SearchResult search(SearchQuery query) {
    return _index.query(query);
  }

  /// Update index entry for a single question when bookmarks or notes change
  Future<void> updateIndexForQuestion(
    String questionId, {
    List<double>? vector,
  }) async {
    final q = await questionRepository.getQuestionById(questionId);
    if (q == null) return;

    final explanations =
        await explanationRepository.getExplanations(questionId);
    final note = await userNoteRepository.getNoteForQuestion(questionId);
    final bookmark = await bookmarkRepository.getBookmark(questionId);

    final detail = QuestionWithDetails(
      question: q,
      explanations: explanations,
      userNote: note,
      bookmark: bookmark,
    );

    _index.index(detail, embeddingVector: vector);
  }
}
