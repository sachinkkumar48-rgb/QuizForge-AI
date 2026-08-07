import '../../infrastructure/collectors/evidence_collector.dart';
import '../entities/evidence_object.dart';

/// Use case for collecting evidence objects via an [EvidenceCollector].
class CollectEvidenceUseCase {
  final EvidenceCollector collector;

  CollectEvidenceUseCase(this.collector);

  Future<List<EvidenceObject>> call({Map<String, dynamic>? params}) async {
    return await collector.collect(params: params);
  }
}
