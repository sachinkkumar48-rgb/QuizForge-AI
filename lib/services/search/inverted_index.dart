import 'dart:math';
import '../../models/view/question_with_details.dart';
import 'search_query.dart';
import 'search_result.dart';

class InvertedIndex {
  final Map<String, Set<String>> _termToQuestionIds = {};
  final Map<String, Set<String>> _trigramToTerms = {};

  final Map<int, Set<String>> _yearToQuestionIds = {};
  final Map<String, Set<String>> _subjectToQuestionIds = {};
  final Map<String, Set<String>> _topicToQuestionIds = {};
  final Map<String, Set<String>> _difficultyToQuestionIds = {};
  final Map<String, Set<String>> _tagToQuestionIds = {};

  final Set<String> _bookmarkedQuestionIds = {};
  final Set<String> _userNoteQuestionIds = {};

  final Map<String, List<double>> _vectorIndex = {};
  final Map<String, QuestionWithDetails> _detailsStore = {};

  void clear() {
    _termToQuestionIds.clear();
    _trigramToTerms.clear();
    _yearToQuestionIds.clear();
    _subjectToQuestionIds.clear();
    _topicToQuestionIds.clear();
    _difficultyToQuestionIds.clear();
    _tagToQuestionIds.clear();
    _bookmarkedQuestionIds.clear();
    _userNoteQuestionIds.clear();
    _vectorIndex.clear();
    _detailsStore.clear();
  }

  /// Add or update a QuestionWithDetails item in the inverted index
  void index(QuestionWithDetails detail, {List<double>? embeddingVector}) {
    final qId = detail.question.id;
    _detailsStore[qId] = detail;

    // Index Year
    _yearToQuestionIds.putIfAbsent(detail.question.year, () => {}).add(qId);

    // Index Subject
    final subjectKey = detail.question.subject.trim().toLowerCase();
    if (subjectKey.isNotEmpty) {
      _subjectToQuestionIds.putIfAbsent(subjectKey, () => {}).add(qId);
    }

    // Index Topic
    final topicKey = detail.question.topic.trim().toLowerCase();
    if (topicKey.isNotEmpty) {
      _topicToQuestionIds.putIfAbsent(topicKey, () => {}).add(qId);
    }

    // Index Difficulty
    final difficultyKey = detail.question.difficulty.trim().toLowerCase();
    if (difficultyKey.isNotEmpty) {
      _difficultyToQuestionIds.putIfAbsent(difficultyKey, () => {}).add(qId);
    }

    // Index Tags
    for (final tag in detail.question.tags) {
      final tagKey = tag.trim().toLowerCase();
      if (tagKey.isNotEmpty) {
        _tagToQuestionIds.putIfAbsent(tagKey, () => {}).add(qId);
      }
    }

    // Index Bookmarks
    if (detail.isBookmarked) {
      _bookmarkedQuestionIds.add(qId);
    } else {
      _bookmarkedQuestionIds.remove(qId);
    }

    // Index User Notes
    if (detail.hasUserNote) {
      _userNoteQuestionIds.add(qId);
    } else {
      _userNoteQuestionIds.remove(qId);
    }

    // Index Vector for Semantic Search
    if (embeddingVector != null) {
      _vectorIndex[qId] = embeddingVector;
    }

    // Tokenize text fields for full-text term index
    final StringBuffer textBuffer = StringBuffer();
    textBuffer.write(' ${detail.question.question} ');
    textBuffer.write(' ${detail.question.subject} ');
    textBuffer.write(' ${detail.question.topic} ');
    textBuffer.write(' ${detail.question.year} ');
    textBuffer.write(' ${detail.question.difficulty} ');
    textBuffer.write(' ${detail.question.tags.join(' ')} ');
    textBuffer.write(' ${detail.question.options.join(' ')} ');

    for (final exp in detail.explanations) {
      textBuffer.write(' ${exp.content} ');
      textBuffer.write(' ${exp.source} ');
      textBuffer.write(' ${exp.explanationType} ');
    }

    if (detail.userNote != null) {
      textBuffer.write(' ${detail.userNote!.title} ');
      textBuffer.write(' ${detail.userNote!.content} ');
      textBuffer.write(' ${detail.userNote!.tags.join(' ')} ');
    }

    if (detail.bookmark != null) {
      textBuffer.write(' ${detail.bookmark!.category} ');
      if (detail.bookmark!.noteSnippet != null) {
        textBuffer.write(' ${detail.bookmark!.noteSnippet} ');
      }
    }

    final tokens = _tokenize(textBuffer.toString());
    for (final token in tokens) {
      _termToQuestionIds.putIfAbsent(token, () => {}).add(qId);
      _indexTrigrams(token);
    }
  }

  /// Execute high-performance index lookup with field filters, fuzzy matching, and snippet highlighting
  SearchResult query(SearchQuery searchQuery) {
    final stopwatch = Stopwatch()..start();

    if (_detailsStore.isEmpty) {
      return const SearchResult(items: [], totalMatches: 0, executionTimeMs: 0);
    }

    Set<String>? matchingSet;

    // 1. Text Search Filtering via Inverted Term Index & Fuzzy Matching
    final rawQuery = searchQuery.queryText.trim().toLowerCase();
    if (rawQuery.isNotEmpty) {
      final queryTokens = _tokenize(rawQuery);
      for (final qToken in queryTokens) {
        final tokenMatches =
            _getQuestionIdsForToken(qToken, searchQuery.enableFuzzy);
        if (matchingSet == null) {
          matchingSet = Set<String>.from(tokenMatches);
        } else {
          matchingSet = matchingSet.intersection(tokenMatches);
        }
      }
    }

    // If queryText was empty, start with all indexed IDs
    Set<String> candidateIds = matchingSet ?? _detailsStore.keys.toSet();

    // 2. Apply Field Filters via Direct Map Lookups (Instant Set Intersections)
    if (searchQuery.year != null) {
      final yearSet = _yearToQuestionIds[searchQuery.year!] ?? {};
      candidateIds = candidateIds.intersection(yearSet);
    }

    if (searchQuery.subject != null && searchQuery.subject!.isNotEmpty) {
      final subKey = searchQuery.subject!.toLowerCase();
      final subSet = _subjectToQuestionIds[subKey] ?? {};
      candidateIds = candidateIds.intersection(subSet);
    }

    if (searchQuery.topic != null && searchQuery.topic!.isNotEmpty) {
      final topicKey = searchQuery.topic!.toLowerCase();
      final topicSet = _topicToQuestionIds[topicKey] ?? {};
      candidateIds = candidateIds.intersection(topicSet);
    }

    if (searchQuery.difficulty != null && searchQuery.difficulty!.isNotEmpty) {
      final diffKey = searchQuery.difficulty!.toLowerCase();
      final diffSet = _difficultyToQuestionIds[diffKey] ?? {};
      candidateIds = candidateIds.intersection(diffSet);
    }

    for (final tag in searchQuery.tags) {
      final tagKey = tag.toLowerCase();
      final tagSet = _tagToQuestionIds[tagKey] ?? {};
      candidateIds = candidateIds.intersection(tagSet);
    }

    if (searchQuery.onlyBookmarked) {
      candidateIds = candidateIds.intersection(_bookmarkedQuestionIds);
    }

    if (searchQuery.onlyWithNotes) {
      candidateIds = candidateIds.intersection(_userNoteQuestionIds);
    }

    final totalCount = candidateIds.length;

    // 3. Rank & Highlight Match Snippets
    final List<SearchResultItem> resultItems = [];

    for (final qId in candidateIds) {
      final detail = _detailsStore[qId]!;
      final score =
          _calculateRelevanceScore(detail, rawQuery, searchQuery.queryVector);
      final snippets = _generateMatchSnippets(detail, rawQuery);

      resultItems.add(SearchResultItem(
        questionDetails: detail,
        score: score,
        matchSnippets: snippets,
      ));
    }

    // Sort by relevance score descending
    resultItems.sort((a, b) => b.score.compareTo(a.score));

    // Pagination slice
    final pagedItems =
        resultItems.skip(searchQuery.offset).take(searchQuery.limit).toList();

    stopwatch.stop();

    return SearchResult(
      items: pagedItems,
      totalMatches: totalCount,
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  Set<String> _getQuestionIdsForToken(String token, bool enableFuzzy) {
    final direct = _termToQuestionIds[token];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    if (!enableFuzzy || token.length < 3) {
      return {};
    }

    // Fuzzy matching via Trigram similarity & Levenshtein distance
    final Set<String> fuzzyQuestionIds = {};
    final trigrams = _generateTrigrams(token);
    final Set<String> candidateTerms = {};

    for (final tri in trigrams) {
      final terms = _trigramToTerms[tri];
      if (terms != null) {
        candidateTerms.addAll(terms);
      }
    }

    for (final candTerm in candidateTerms) {
      if (_levenshteinDistance(token, candTerm) <= 2) {
        final qIds = _termToQuestionIds[candTerm];
        if (qIds != null) {
          fuzzyQuestionIds.addAll(qIds);
        }
      }
    }

    return fuzzyQuestionIds;
  }

  double _calculateRelevanceScore(
    QuestionWithDetails detail,
    String rawQuery,
    List<double>? queryVector,
  ) {
    double score = 1.0;

    if (rawQuery.isNotEmpty) {
      final tokens = _tokenize(rawQuery);
      final qTextLower = detail.question.question.toLowerCase();
      final subjectLower = detail.question.subject.toLowerCase();
      final topicLower = detail.question.topic.toLowerCase();

      for (final token in tokens) {
        if (qTextLower.contains(token)) score += 5.0;
        if (subjectLower.contains(token)) score += 3.0;
        if (topicLower.contains(token)) score += 3.0;
        if (detail.question.tags.any((t) => t.toLowerCase().contains(token))) {
          score += 2.0;
        }
        for (final exp in detail.explanations) {
          if (exp.content.toLowerCase().contains(token)) score += 2.0;
        }
        if (detail.userNote != null &&
            detail.userNote!.content.toLowerCase().contains(token)) {
          score += 2.0;
        }
      }
    }

    // Semantic Vector Similarity Score Calculation
    if (queryVector != null && _vectorIndex.containsKey(detail.question.id)) {
      final docVector = _vectorIndex[detail.question.id]!;
      final sim = cosineSimilarity(queryVector, docVector);
      score += sim * 10.0;
    }

    return score;
  }

  List<MatchSnippet> _generateMatchSnippets(
      QuestionWithDetails detail, String rawQuery) {
    if (rawQuery.isEmpty) return const [];
    final List<MatchSnippet> snippets = [];

    // Highlight in Question text
    final qText = detail.question.question;
    final qRanges = _findHighlightRanges(qText, rawQuery);
    if (qRanges.isNotEmpty) {
      snippets.add(MatchSnippet(
        fieldName: 'question',
        snippetText: _extractSnippetWindow(qText, qRanges.first.start),
        highlightRanges: qRanges,
      ));
    }

    // Highlight in Subject & Topic
    final subText = detail.question.subject;
    final subRanges = _findHighlightRanges(subText, rawQuery);
    if (subRanges.isNotEmpty) {
      snippets.add(MatchSnippet(
        fieldName: 'subject',
        snippetText: subText,
        highlightRanges: subRanges,
      ));
    }

    final topText = detail.question.topic;
    final topRanges = _findHighlightRanges(topText, rawQuery);
    if (topRanges.isNotEmpty) {
      snippets.add(MatchSnippet(
        fieldName: 'topic',
        snippetText: topText,
        highlightRanges: topRanges,
      ));
    }

    // Highlight in Tags
    if (detail.question.tags.isNotEmpty) {
      final tagsText = detail.question.tags.join(', ');
      final tagRanges = _findHighlightRanges(tagsText, rawQuery);
      if (tagRanges.isNotEmpty) {
        snippets.add(MatchSnippet(
          fieldName: 'tags',
          snippetText: tagsText,
          highlightRanges: tagRanges,
        ));
      }
    }

    // Highlight in Explanations
    for (final exp in detail.explanations) {
      final expRanges = _findHighlightRanges(exp.content, rawQuery);
      if (expRanges.isNotEmpty) {
        snippets.add(MatchSnippet(
          fieldName: 'explanation (${exp.explanationType})',
          snippetText:
              _extractSnippetWindow(exp.content, expRanges.first.start),
          highlightRanges: expRanges,
        ));
      }
    }

    // Highlight in User Notes
    if (detail.userNote != null) {
      final noteTitle = detail.userNote!.title;
      final noteContent = detail.userNote!.content;
      final noteText =
          noteTitle.isNotEmpty ? '$noteTitle: $noteContent' : noteContent;
      final noteRanges = _findHighlightRanges(noteText, rawQuery);
      if (noteRanges.isNotEmpty) {
        snippets.add(MatchSnippet(
          fieldName: 'userNote',
          snippetText: _extractSnippetWindow(noteText, noteRanges.first.start),
          highlightRanges: noteRanges,
        ));
      }
    }

    // Highlight in Bookmark Note Snippet
    if (detail.bookmark?.noteSnippet != null &&
        detail.bookmark!.noteSnippet!.isNotEmpty) {
      final bmText = detail.bookmark!.noteSnippet!;
      final bmRanges = _findHighlightRanges(bmText, rawQuery);
      if (bmRanges.isNotEmpty) {
        snippets.add(MatchSnippet(
          fieldName: 'bookmark',
          snippetText: _extractSnippetWindow(bmText, bmRanges.first.start),
          highlightRanges: bmRanges,
        ));
      }
    }

    return snippets;
  }

  List<MatchRange> _findHighlightRanges(String text, String rawQuery) {
    if (text.isEmpty || rawQuery.trim().isEmpty) return const [];
    final textLower = text.toLowerCase();
    final queryTokens = _tokenize(rawQuery);

    if (queryTokens.isEmpty) {
      queryTokens.add(rawQuery.trim().toLowerCase());
    }

    final List<MatchRange> ranges = [];

    // Check full query phrase match first
    final rawQueryLower = rawQuery.trim().toLowerCase();
    int start = 0;
    while ((start = textLower.indexOf(rawQueryLower, start)) != -1) {
      ranges.add(MatchRange(start, start + rawQueryLower.length));
      start += rawQueryLower.length;
    }

    // Check individual tokens
    for (final qToken in queryTokens) {
      int pos = 0;
      while ((pos = textLower.indexOf(qToken, pos)) != -1) {
        ranges.add(MatchRange(pos, pos + qToken.length));
        pos += qToken.length;
      }
    }

    if (ranges.isEmpty) return const [];

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final List<MatchRange> merged = [ranges.first];

    for (int i = 1; i < ranges.length; i++) {
      final last = merged.last;
      final current = ranges[i];
      if (current.start <= last.end) {
        merged[merged.length - 1] =
            MatchRange(last.start, max(last.end, current.end));
      } else {
        merged.add(current);
      }
    }

    return merged;
  }

  String _extractSnippetWindow(String text, int targetOffset,
      {int maxLen = 120}) {
    if (text.length <= maxLen) return text;
    int start = max(0, targetOffset - 40);
    int end = min(text.length, start + maxLen);
    String snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    return snippet;
  }

  Set<String> _tokenize(String input) {
    final clean = input.replaceAll(RegExp(r'[^\w\s]'), ' ').toLowerCase();
    return clean.split(RegExp(r'\s+')).where((t) => t.length >= 2).toSet();
  }

  void _indexTrigrams(String token) {
    for (final tri in _generateTrigrams(token)) {
      _trigramToTerms.putIfAbsent(tri, () => {}).add(token);
    }
  }

  List<String> _generateTrigrams(String token) {
    final List<String> trigrams = [];
    final padded = '  $token ';
    for (int i = 0; i < padded.length - 2; i++) {
      trigrams.add(padded.substring(i, i + 3));
    }
    return trigrams;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
