import 'package:meta/meta.dart';

import 'search_scope.dart';

/// Immutable domain model representing a ranked search result item.
@immutable
class SearchResult {
  final String id;
  final String title;
  final String snippet;
  final SearchScope scope;
  final double score;
  final double keywordScore;
  final double knowledgeGraphScore;
  final double learningProfileScore;
  final double recommendationScore;
  final double recencyScore;
  final List<String> matchedTerms;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  SearchResult({
    required this.id,
    required this.title,
    required this.snippet,
    required this.scope,
    required this.score,
    this.keywordScore = 0.0,
    this.knowledgeGraphScore = 0.0,
    this.learningProfileScore = 0.0,
    this.recommendationScore = 0.0,
    this.recencyScore = 0.0,
    List<String>? matchedTerms,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  })  : matchedTerms = List<String>.unmodifiable(matchedTerms ?? []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {}),
        timestamp = timestamp ?? DateTime.now();

  SearchResult copyWith({
    String? id,
    String? title,
    String? snippet,
    SearchScope? scope,
    double? score,
    double? keywordScore,
    double? knowledgeGraphScore,
    double? learningProfileScore,
    double? recommendationScore,
    double? recencyScore,
    List<String>? matchedTerms,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      scope: scope ?? this.scope,
      score: score ?? this.score,
      keywordScore: keywordScore ?? this.keywordScore,
      knowledgeGraphScore: knowledgeGraphScore ?? this.knowledgeGraphScore,
      learningProfileScore: learningProfileScore ?? this.learningProfileScore,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recencyScore: recencyScore ?? this.recencyScore,
      matchedTerms: matchedTerms ?? this.matchedTerms,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'snippet': snippet,
        'scope': scope.name,
        'score': score,
        'keywordScore': keywordScore,
        'knowledgeGraphScore': knowledgeGraphScore,
        'learningProfileScore': learningProfileScore,
        'recommendationScore': recommendationScore,
        'recencyScore': recencyScore,
        'matchedTerms': matchedTerms,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        id: json['id'] as String,
        title: json['title'] as String,
        snippet: json['snippet'] as String,
        scope: SearchScope.values.firstWhere(
          (e) => e.name == json['scope'],
          orElse: () => SearchScope.notes,
        ),
        score: (json['score'] as num).toDouble(),
        keywordScore: (json['keywordScore'] as num? ?? 0.0).toDouble(),
        knowledgeGraphScore:
            (json['knowledgeGraphScore'] as num? ?? 0.0).toDouble(),
        learningProfileScore:
            (json['learningProfileScore'] as num? ?? 0.0).toDouble(),
        recommendationScore:
            (json['recommendationScore'] as num? ?? 0.0).toDouble(),
        recencyScore: (json['recencyScore'] as num? ?? 0.0).toDouble(),
        matchedTerms: (json['matchedTerms'] as List? ?? []).cast<String>(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          scope == other.scope &&
          score == other.score;

  @override
  int get hashCode => Object.hash(id, title, scope, score);
}
