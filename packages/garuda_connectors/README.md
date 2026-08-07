# Project TITAN - GARUDA Connectors Package (`garuda_connectors`)

The `garuda_connectors` package contains the **GarudaConnector SDK** and reference gold-standard connectors for Project TITAN.

The **PIB Connector** (`PIBConnector`) implemented in this package serves as the **Gold Standard Reference Implementation** for every future connector.

---

## Architectural Principles

- **Clean Architecture & SOLID**: Reusable Connector SDK (`GarudaConnector`) defining the single contract for external evidence discovery, fetching, parsing, validation, and health diagnostics.
- **Reference Gold Standard**: `PIBConnector` demonstrates the exact pattern required for all future connectors.
- **Automated UPSC Classification**: `CategoryClassifier` maps evidence into 11 core categories (Polity, Economy, Environment, Science, Agriculture, Governance, International Relations, Security, Social Justice, Culture, Technology).
- **Deduplication Engine**: `EvidenceDeduplicator` evaluates checksums, URLs, publication dates, and title similarity before storage.
- **Non-Destructive Versioning**: `VersioningOrchestrator` generates Version 2 (or N+1) upon content modifications, keeping full audit history without overwriting past evidence.
- **Editorial Queue Integration**: Every successfully validated item enters `REVIEW_PENDING` status in the `EditorialQueue`.

---

## How Future Connectors Extend the SDK

Every future connector must extend `GarudaConnector` and implement the 9 standard SDK functions:

```dart
import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

class SupremeCourtConnector extends BaseEvidenceCollector implements GarudaConnector {
  @override
  EvidenceSource source() => const EvidenceSource(
        id: 'src_supreme_court',
        name: 'Supreme Court Judgments',
        type: EvidenceSourceType.judiciary,
        baseUrl: 'https://main.sci.gov.in',
      );

  @override
  ConnectorMetadata metadata() => ConnectorMetadata(
        connectorName: 'SupremeCourtConnector',
        source: source(),
        version: '1.0.0',
        categories: const ['Polity', 'Judiciary', 'Social Justice'],
        subjects: const ['Polity'],
      );

  @override
  List<String> supportedCategories() => const ['Polity', 'Judiciary'];

  @override
  List<String> supportedSubjects() => const ['Polity'];

  @override
  Future<List<RawEvidencePayload>> discover({Map<String, dynamic>? params}) async {
    // 1. Discover judgments
    return [];
  }

  @override
  Future<RawEvidencePayload> fetch(String identifier) async {
    // 2. Fetch judgment payload
    return RawEvidencePayload(...);
  }

  @override
  Future<EvidenceObject> parseRaw(RawEvidencePayload payload) async {
    // 3. Parse judgment payload into EvidenceObject with Lineage & Lifecycle
    return EvidenceObject(...);
  }

  @override
  Future<ConnectorHealth> healthCheckDiagnostic() async {
    return const ConnectorHealth(
      connectorName: 'SupremeCourtConnector',
      status: SourceHealthStatus.healthy,
    );
  }
}
```

---

## Supported Connectors Strategy

The following connectors follow this exact pattern:
1. `PIBConnector` (Gold Standard - Implemented)
2. `SupremeCourtConnector` (Judgments)
3. `PRSCollector` / `PRSConnector` (PRS Legislative Research)
4. `ParliamentConnector` (Bills & Debates)
5. `GazetteConnector` (Gazette Notifications)
6. `RBIConnector` (RBI Notifications)
7. `SEBIConnector` (SEBI Circulars)
8. `ISROConnector` (ISRO Publications)
9. `DRDOConnector` (DRDO Reports)
10. `WHOConnector` (WHO Bulletins)
11. `IMFConnector` (IMF Financial Reports)
12. `WorldBankConnector` (World Bank Studies)
