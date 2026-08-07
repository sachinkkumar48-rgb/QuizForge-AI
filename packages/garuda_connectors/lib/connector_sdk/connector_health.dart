library;

import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:meta/meta.dart';

/// Detailed operational health report for a GARUDA Connector.
@immutable
class ConnectorHealth {
  final String connectorName;
  final SourceHealthStatus status;
  final double latencyMs;
  final DateTime? lastSuccessfulSync;
  final int failureCount;
  final double availabilityScore;
  final String message;

  const ConnectorHealth({
    required this.connectorName,
    this.status = SourceHealthStatus.healthy,
    this.latencyMs = 0.0,
    this.lastSuccessfulSync,
    this.failureCount = 0,
    this.availabilityScore = 1.0,
    this.message = 'Connector operational',
  });

  Map<String, dynamic> toJson() => {
        'connectorName': connectorName,
        'status': status.name,
        'latencyMs': latencyMs,
        'lastSuccessfulSync': lastSuccessfulSync?.toIso8601String(),
        'failureCount': failureCount,
        'availabilityScore': availabilityScore,
        'message': message,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectorHealth &&
        other.connectorName == connectorName &&
        other.status == status &&
        other.availabilityScore == availabilityScore;
  }

  @override
  int get hashCode =>
      Object.hash(connectorName, status, availabilityScore);
}
