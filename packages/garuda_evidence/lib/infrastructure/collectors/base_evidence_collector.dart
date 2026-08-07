import '../../domain/entities/evidence_object.dart';
import '../validators/composite_evidence_validator.dart';
import '../validators/validation_result.dart';
import 'evidence_collector.dart';

/// Abstract base implementation of [EvidenceCollector] providing standard stub logic.
abstract class BaseEvidenceCollector implements EvidenceCollector {
  final CompositeEvidenceValidator _validator = CompositeEvidenceValidator.standard();

  @override
  Future<List<EvidenceObject>> collect({Map<String, dynamic>? params}) async {
    // Stub implementation: No network calls or scraping executed.
    return <EvidenceObject>[];
  }

  @override
  Future<EvidenceObject> parse(dynamic rawData) async {
    if (rawData is EvidenceObject) return rawData;
    if (rawData is Map<String, dynamic>) {
      return EvidenceObject.fromJson(rawData);
    }
    throw UnimplementedError('Raw data parsing not implemented for $sourceName');
  }

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    return await _validator.validate(evidence);
  }

  @override
  Future<bool> store(EvidenceObject evidence) async {
    return true;
  }

  @override
  Future<bool> update(EvidenceObject evidence) async {
    return true;
  }

  @override
  Future<HealthCheckResult> healthCheck() async {
    return HealthCheckResult(
      isHealthy: true,
      sourceName: sourceName,
      message: 'Gateway ready for ingestion architecture (Offline/Stub mode)',
      timestamp: DateTime.now(),
    );
  }
}
