import 'dart:math';

import '../models/search_index.dart';
import '../models/search_result.dart';
import 'query_parser.dart';

/// Extensible multi-factor ranking engine for Knowledge Graph-powered semantic search.
class RankingEngine {
  final double keywordWeight;
  final double kgWeight;
  final double learningProfileWeight;
  final double recommendationWeight;
  final double recencyWeight;

  const RankingEngine({
    this.keywordWeight = 0.40,
    this.kgWeight = 0.20,
    this.learningProfileWeight = 0.15,
    this.recommendationWeight = 0.15,
    this.recencyWeight = 0.10,
  });

  /// Ranks a list of [SearchIndexItem] candidates against a [ParsedQuery].
  List<SearchResult> rank({
    required List<SearchIndexItem> candidates,
    required ParsedQuery parsedQuery,
    Map<String, double>? userTopicWeights,
    Set<String>? recommendedContentIds,
  }) {
    final results = <SearchResult>[];

    for (final item in candidates) {
      final scoreResult = computeScore(
        item: item,
        parsedQuery: parsedQuery,
        userTopicWeights: userTopicWeights,
        recommendedContentIds: recommendedContentIds,
      );

      if (scoreResult.score > 0.0) {
        results.add(scoreResult);
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Calculates individual feature scores and composite final score.
  SearchResult computeScore({
    required SearchIndexItem item,
    required ParsedQuery parsedQuery,
    Map<String, double>? userTopicWeights,
    Set<String>? recommendedContentIds,
  }) {
    final titleLower = item.title.toLowerCase();
    final contentLower = item.content.toLowerCase();
    final matchedTerms = <String>{};

    // 1. Keyword Score Calculation
    double rawKwScore = 0.0;

    // Exact phrase match bonus
    for (final phrase in parsedQuery.exactPhrases) {
      if (titleLower.contains(phrase)) {
        rawKwScore += 5.0;
        matchedTerms.add(phrase);
      }
      if (contentLower.contains(phrase)) {
        rawKwScore += 3.0;
        matchedTerms.add(phrase);
      }
    }

    // Token matching
    for (final token in parsedQuery.tokens) {
      if (titleLower.contains(token)) {
        rawKwScore += 3.0;
        matchedTerms.add(token);
      }
      if (contentLower.contains(token)) {
        rawKwScore += 1.0;
        matchedTerms.add(token);
      }
      for (final tag in item.tags) {
        if (tag.toLowerCase().contains(token)) {
          rawKwScore += 2.0;
          matchedTerms.add(token);
        }
      }

      // Fuzzy / Levenshtein check if fuzzy match enabled
      if (parsedQuery.originalQuery.fuzzyMatch) {
        for (final word in titleLower.split(RegExp(r'\s+'))) {
          if (_levenshteinDistance(token, word) <= 1 && token.length > 3) {
            rawKwScore += 1.5;
            matchedTerms.add(word);
          }
        }
      }
    }

    // Synonym matching
    for (final entry in parsedQuery.synonyms.entries) {
      for (final syn in entry.value) {
        final synLower = syn.toLowerCase();
        if (titleLower.contains(synLower) || contentLower.contains(synLower)) {
          rawKwScore += 1.2;
          matchedTerms.add(syn);
        }
      }
    }

    final keywordScore = min(1.0, rawKwScore / 10.0);

    // 2. Knowledge Graph Proximity Score
    double kgScore = 0.0;
    if (parsedQuery.expandedConcepts.isNotEmpty) {
      int conceptMatches = 0;
      for (final concept in item.conceptIds) {
        if (parsedQuery.expandedConcepts
            .any((c) => c.toLowerCase() == concept.toLowerCase())) {
          conceptMatches++;
        }
      }
      kgScore = min(1.0, conceptMatches * 0.4);
    }

    // 3. Learning Profile Weighting
    double lpScore = 0.0;
    if (userTopicWeights != null && userTopicWeights.isNotEmpty) {
      for (final tag in item.tags) {
        final weight = userTopicWeights[tag.toLowerCase()];
        if (weight != null) {
          lpScore = max(lpScore, min(1.0, weight));
        }
      }
    }

    // 4. Recommendation Priority
    double recScore = 0.0;
    if (recommendedContentIds != null &&
        recommendedContentIds.contains(item.contentId)) {
      recScore = 1.0;
    }

    // 5. Recency Score
    final daysOld =
        DateTime.now().difference(item.timestamp).inDays.clamp(0, 365);
    final recencyScore = max(0.1, 1.0 - (daysOld / 365.0));

    // Final Composite Score Calculation
    final compositeScore = (keywordWeight * keywordScore) +
        (kgWeight * kgScore) +
        (learningProfileWeight * lpScore) +
        (recommendationWeight * recScore) +
        (recencyWeight * recencyScore);

    // Build snippet
    final snippet = item.content.length > 120
        ? '${item.content.substring(0, 120)}...'
        : item.content;

    return SearchResult(
      id: item.id,
      title: item.title,
      snippet: snippet,
      scope: item.scope,
      score: double.parse(compositeScore.toStringAsFixed(3)),
      keywordScore: double.parse(keywordScore.toStringAsFixed(3)),
      knowledgeGraphScore: double.parse(kgScore.toStringAsFixed(3)),
      learningProfileScore: double.parse(lpScore.toStringAsFixed(3)),
      recommendationScore: double.parse(recScore.toStringAsFixed(3)),
      recencyScore: double.parse(recencyScore.toStringAsFixed(3)),
      matchedTerms: matchedTerms.toList(),
      metadata: item.metadata,
      timestamp: item.timestamp,
    );
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final v0 = List<int>.generate(b.length + 1, (i) => i);
    final v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a.codeUnitAt(i) == b.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }
}
