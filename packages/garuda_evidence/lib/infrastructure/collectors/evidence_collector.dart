import 'package:meta/meta.dart';
import '../../domain/entities/evidence_object.dart';
import '../validators/validation_result.dart';

/// Health check status for a collector.
@immutable
class HealthCheckResult {
  final bool isHealthy;
  final String sourceName;
  final String message;
  final DateTime timestamp;

  const HealthCheckResult({
    required this.isHealthy,
    required this.sourceName,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'isHealthy': isHealthy,
        'sourceName': sourceName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Abstract interface for all external evidence collectors in Project TITAN.
/// Single architectural contract for gathering, parsing, validating, and storing evidence.
abstract class EvidenceCollector {
  String get sourceName;

  /// Collect raw evidence objects.
  Future<List<EvidenceObject>> collect({Map<String, dynamic>? params});

  /// Parse raw data into a structured EvidenceObject.
  Future<EvidenceObject> parse(dynamic rawData);

  /// Validate an EvidenceObject against collector-specific and system rules.
  Future<ValidationResult> validate(EvidenceObject evidence);

  /// Store an EvidenceObject into storage/repository.
  Future<bool> store(EvidenceObject evidence);

  /// Update an existing EvidenceObject.
  Future<bool> update(EvidenceObject evidence);

  /// Perform health check diagnostic on the evidence source gateway.
  Future<HealthCheckResult> healthCheck();
}
