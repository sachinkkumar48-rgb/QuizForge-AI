import '../cache/knowledge_cache.dart';
import '../indexing/knowledge_index.dart';

/// Telemetry metrics container reporting Search Latency, Cache Hit Rate, Index Size & Coverage.
class KnowledgeSearchAnalytics {
  final KnowledgeIndex index;
  final KnowledgeCache cache;

  final List<double> _latencies = [];
  int _totalSearches = 0;
  int _missingIndexQueries = 0;

  KnowledgeSearchAnalytics({
    required this.index,
    required this.cache,
  });

  void recordSearch(double latencyMs, bool hasResults) {
    _totalSearches++;
    _latencies.add(latencyMs);
    if (!hasResults) {
      _missingIndexQueries++;
    }
  }

  int get indexSize => index.totalIndexedObjects;
  int get objectsIndexed => index.totalIndexedObjects;
  double get averageSearchLatencyMs =>
      _latencies.isEmpty ? 0.0 : _latencies.reduce((a, b) => a + b) / _latencies.length;
  double get cacheHitRate => cache.cacheHitRate;
  double get indexCoverage => indexSize > 0 ? 1.0 : 0.0;
  int get missingIndexEntries => _missingIndexQueries;
  int get totalSearches => _totalSearches;

  Map<String, dynamic> generateReport() {
    return {
      'indexSize': indexSize,
      'objectsIndexed': objectsIndexed,
      'averageSearchLatencyMs': double.parse(averageSearchLatencyMs.toStringAsFixed(2)),
      'cacheHitRate': double.parse((cacheHitRate * 100).toStringAsFixed(1)),
      'indexCoveragePercentage': (indexCoverage * 100).toInt(),
      'missingIndexEntries': missingIndexEntries,
      'totalSearchesExecuted': totalSearches,
    };
  }
}
