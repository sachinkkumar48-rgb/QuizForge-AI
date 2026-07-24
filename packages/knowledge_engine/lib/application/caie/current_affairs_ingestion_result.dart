import 'package:meta/meta.dart';

import '../../domain/entities/knowledge_object.dart';
import 'current_affairs_article.dart';

/// Immutable domain value object representing the output of a Current Affairs ingestion run.
@immutable
class CurrentAffairsIngestionResult {
  /// Articles successfully validated, processed, and ingested.
  final List<CurrentAffairsArticle> processedArticles;

  /// Articles skipped due to validation failure or empty content.
  final List<CurrentAffairsArticle> skippedArticles;

  /// Canonical [KnowledgeObject] entities generated from ingested articles.
  final List<KnowledgeObject> generatedKnowledgeObjects;

  /// Extensible statistics payload (e.g. `totalArticles`, `processedCount`, `skippedCount`, `executionTimeMs`).
  final Map<String, dynamic> statistics;

  /// Constructs an immutable [CurrentAffairsIngestionResult].
  CurrentAffairsIngestionResult({
    required List<CurrentAffairsArticle> processedArticles,
    required List<CurrentAffairsArticle> skippedArticles,
    required List<KnowledgeObject> generatedKnowledgeObjects,
    Map<String, dynamic> statistics = const {},
  })  : processedArticles =
            List<CurrentAffairsArticle>.unmodifiable(processedArticles),
        skippedArticles =
            List<CurrentAffairsArticle>.unmodifiable(skippedArticles),
        generatedKnowledgeObjects =
            List<KnowledgeObject>.unmodifiable(generatedKnowledgeObjects),
        statistics = Map<String, dynamic>.unmodifiable(statistics);

  /// Converts this [CurrentAffairsIngestionResult] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'processedArticles': processedArticles.map((e) => e.toMap()).toList(),
      'skippedArticles': skippedArticles.map((e) => e.toMap()).toList(),
      'generatedKnowledgeObjects':
          generatedKnowledgeObjects.map((e) => e.toMap()).toList(),
      'statistics': statistics,
    };
  }

  /// Deserializes a [CurrentAffairsIngestionResult] from a Map.
  factory CurrentAffairsIngestionResult.fromMap(Map<String, dynamic> map) {
    return CurrentAffairsIngestionResult(
      processedArticles: (map['processedArticles'] as List? ?? const [])
          .map((e) => CurrentAffairsArticle.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      skippedArticles: (map['skippedArticles'] as List? ?? const [])
          .map((e) => CurrentAffairsArticle.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      generatedKnowledgeObjects:
          (map['generatedKnowledgeObjects'] as List? ?? const [])
              .map((e) =>
                  KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
      statistics:
          Map<String, dynamic>.from(map['statistics'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CurrentAffairsIngestionResult &&
        _listEquals(other.processedArticles, processedArticles) &&
        _listEquals(other.skippedArticles, skippedArticles) &&
        _listEquals(
            other.generatedKnowledgeObjects, generatedKnowledgeObjects) &&
        _mapEquals(other.statistics, statistics);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(processedArticles),
      Object.hashAll(skippedArticles),
      Object.hashAll(generatedKnowledgeObjects),
      Object.hashAll(statistics.keys),
      Object.hashAll(statistics.values),
    );
  }

  @override
  String toString() {
    return 'CurrentAffairsIngestionResult(processed: ${processedArticles.length}, skipped: ${skippedArticles.length}, generatedObjects: ${generatedKnowledgeObjects.length})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
