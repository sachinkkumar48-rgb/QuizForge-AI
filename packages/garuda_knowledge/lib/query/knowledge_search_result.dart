import 'package:meta/meta.dart';
import '../domain/entities/knowledge_object.dart';
import 'knowledge_query.dart';
import 'knowledge_search_hit.dart';

/// Top-level result object returned by KnowledgeQueryEngine containing search hits & metrics.
@immutable
class KnowledgeSearchResult {
  final List<KnowledgeSearchHit> hits;
  final int totalHits;
  final double latencyMs;
  final bool isCacheHit;
  final KnowledgeQuery query;

  const KnowledgeSearchResult({
    required this.hits,
    required this.totalHits,
    required this.latencyMs,
    this.isCacheHit = false,
    required this.query,
  });

  /// Convenience getter to extract raw objects.
  List<KnowledgeObject> get objects => hits.map((h) => h.object).toList();
}
