/// GARUDA Connector SDK and reference connectors package for Project TITAN.
library;

// Connector SDK
export 'connector_sdk/connector_health.dart';
export 'connector_sdk/connector_metadata.dart';
export 'connector_sdk/garuda_connector.dart';
export 'connector_sdk/raw_evidence_payload.dart';

// PIB Gold-Standard Connector
export 'pib/pib_connector.dart';
export 'pib/pib_connector_config.dart';
export 'pib/pib_raw_parser.dart';

// Services & Orchestration Facade
export 'services/garuda_connector_service.dart';

// Shared Utilities & Classification
export 'shared/category_classifier.dart';
export 'shared/deduplicator.dart';
export 'shared/versioning_orchestrator.dart';
