import '../../domain/entities/evidence_source.dart';
import '../health/source_health.dart';

/// Abstract contract for managing evidence source registrations and health monitoring.
abstract class EvidenceSourceRegistry {
  Future<void> register(EvidenceSource source);
  Future<bool> unregister(String sourceId);
  Future<bool> enable(String sourceId);
  Future<bool> disable(String sourceId);
  Future<EvidenceSource?> find(String sourceId);
  Future<List<EvidenceSource>> list({bool? enabledOnly});
  Future<List<String>> supportedSources();
  Future<SourceHealth?> health(String sourceId);
}

/// In-memory thread-safe implementation of [EvidenceSourceRegistry].
class InMemoryEvidenceSourceRegistry implements EvidenceSourceRegistry {
  final Map<String, EvidenceSource> _sources = {};
  final Map<String, SourceHealth> _healthMap = {};

  @override
  Future<void> register(EvidenceSource source) async {
    _sources[source.id] = source;
    _healthMap[source.id] = SourceHealth(
      source: source.name,
      enabled: source.isVerified,
      status: source.isVerified ? SourceHealthStatus.healthy : SourceHealthStatus.unknown,
    );
  }

  @override
  Future<bool> unregister(String sourceId) async {
    _healthMap.remove(sourceId);
    return _sources.remove(sourceId) != null;
  }

  @override
  Future<bool> enable(String sourceId) async {
    final src = _sources[sourceId];
    if (src == null) return false;

    _sources[sourceId] = src.copyWith(isVerified: true);
    final health = _healthMap[sourceId];
    if (health != null) {
      _healthMap[sourceId] = health.copyWith(enabled: true, status: SourceHealthStatus.healthy);
    }
    return true;
  }

  @override
  Future<bool> disable(String sourceId) async {
    final src = _sources[sourceId];
    if (src == null) return false;

    _sources[sourceId] = src.copyWith(isVerified: false);
    final health = _healthMap[sourceId];
    if (health != null) {
      _healthMap[sourceId] = health.copyWith(enabled: false, status: SourceHealthStatus.unavailable);
    }
    return true;
  }

  @override
  Future<EvidenceSource?> find(String sourceId) async {
    return _sources[sourceId];
  }

  @override
  Future<List<EvidenceSource>> list({bool? enabledOnly}) async {
    if (enabledOnly == true) {
      return _sources.values.where((s) => s.isVerified).toList();
    }
    return _sources.values.toList();
  }

  @override
  Future<List<String>> supportedSources() async {
    return _sources.values.map((s) => s.name).toList();
  }

  @override
  Future<SourceHealth?> health(String sourceId) async {
    return _healthMap[sourceId];
  }
}
