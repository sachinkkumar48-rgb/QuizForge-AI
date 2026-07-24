import '../../models/view/question_with_details.dart';

class MatchRange {
  final int start;
  final int end;

  const MatchRange(this.start, this.end);

  @override
  String toString() => 'MatchRange($start, $end)';
}

class MatchSnippet {
  final String
      fieldName; // 'question', 'topic', 'explanation', 'userNote', etc.
  final String snippetText;
  final List<MatchRange> highlightRanges;

  const MatchSnippet({
    required this.fieldName,
    required this.snippetText,
    required this.highlightRanges,
  });
}

class SearchResultItem {
  final QuestionWithDetails questionDetails;
  final double score;
  final List<MatchSnippet> matchSnippets;

  const SearchResultItem({
    required this.questionDetails,
    required this.score,
    required this.matchSnippets,
  });
}

class SearchResult {
  final List<SearchResultItem> items;
  final int totalMatches;
  final int executionTimeMs;

  const SearchResult({
    required this.items,
    required this.totalMatches,
    required this.executionTimeMs,
  });
}
