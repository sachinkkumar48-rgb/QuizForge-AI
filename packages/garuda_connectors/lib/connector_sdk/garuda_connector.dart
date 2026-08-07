library;

import 'package:garuda_evidence/garuda_evidence.dart';
import 'connector_health.dart';
import 'connector_metadata.dart';
import 'raw_evidence_payload.dart';

/// Primary abstract SDK contract for all external data connectors in Project TITAN.
/// Every future connector (PIB, Supreme Court, PRS, Parliament, RBI, SEBI, ISRO, DRDO, WHO, IMF, World Bank)
/// MUST implement this interface.
abstract class GarudaConnector implements EvidenceCollector {
  /// Metadata descriptor for the connector.
  ConnectorMetadata metadata();

  /// Source entity represented by this connector.
  EvidenceSource source();

  /// Supported UPSC/exam categories.
  List<String> supportedCategories();

  /// Supported subjects.
  List<String> supportedSubjects();

  /// Discover new items available at the source gateway.
  Future<List<RawEvidencePayload>> discover({Map<String, dynamic>? params});

  /// Fetch raw evidence payload for a given item identifier.
  Future<RawEvidencePayload> fetch(String identifier);

  /// Parse a [RawEvidencePayload] into a production-ready [EvidenceObject].
  Future<EvidenceObject> parseRaw(RawEvidencePayload payload);

  /// Run detailed health check diagnostic on the connector.
  Future<ConnectorHealth> healthCheckDiagnostic();
}
