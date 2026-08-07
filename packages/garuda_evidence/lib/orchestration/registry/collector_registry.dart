import '../../domain/entities/evidence_object.dart';
import '../../infrastructure/collectors/evidence_collector.dart';

/// Abstract contract for managing evidence collectors as pluggable infrastructure components.
abstract class CollectorRegistry {
  Future<void> registerCollector(EvidenceCollector collector);
  Future<bool> removeCollector(String sourceName);
  Future<EvidenceCollector?> findCollector(String sourceName);
  Future<List<String>> supportedCollectors();
  Future<List<EvidenceObject>> executeCollector(
    String sourceName, {
    Map<String, dynamic>? params,
  });
}

/// In-memory thread-safe implementation of [CollectorRegistry].
class InMemoryCollectorRegistry implements CollectorRegistry {
  final Map<String, EvidenceCollector> _collectors = {};

  @override
  Future<void> registerCollector(EvidenceCollector collector) async {
    _collectors[collector.sourceName.toLowerCase()] = collector;
  }

  @override
  Future<bool> removeCollector(String sourceName) async {
    return _collectors.remove(sourceName.toLowerCase()) != null;
  }

  @override
  Future<EvidenceCollector?> findCollector(String sourceName) async {
    return _collectors[sourceName.toLowerCase()];
  }

  @override
  Future<List<String>> supportedCollectors() async {
    return _collectors.values.map((c) => c.sourceName).toList();
  }

  @override
  Future<List<EvidenceObject>> executeCollector(
    String sourceName, {
    Map<String, dynamic>? params,
  }) async {
    final collector = await findCollector(sourceName);
    if (collector == null) {
      throw ArgumentError('Collector for source "$sourceName" is not registered.');
    }
    return await collector.collect(params: params);
  }
}
