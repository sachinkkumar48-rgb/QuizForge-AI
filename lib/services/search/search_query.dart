class SearchQuery {
  final String queryText;
  final String? subject;
  final String? topic;
  final int? year;
  final String? difficulty;
  final List<String> tags;
  final bool onlyBookmarked;
  final bool onlyWithNotes;
  final bool enableFuzzy;
  final int limit;
  final int offset;

  /// Optional vector embedding representation for future semantic search.
  final List<double>? queryVector;

  const SearchQuery({
    this.queryText = '',
    this.subject,
    this.topic,
    this.year,
    this.difficulty,
    this.tags = const [],
    this.onlyBookmarked = false,
    this.onlyWithNotes = false,
    this.enableFuzzy = true,
    this.limit = 20,
    this.offset = 0,
    this.queryVector,
  });

  bool get isEmpty =>
      queryText.trim().isEmpty &&
      subject == null &&
      topic == null &&
      year == null &&
      difficulty == null &&
      tags.isEmpty &&
      !onlyBookmarked &&
      !onlyWithNotes &&
      queryVector == null;
}
