import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:test/test.dart';

void main() {
  group('PIBConnector Gold-Standard Connector Tests', () {
    late PIBConnector connector;

    setUp(() {
      connector = PIBConnector();
    });

    test('metadata and source properties are configured correctly', () {
      final meta = connector.metadata();
      expect(meta.connectorName, equals('PIBConnector'));
      expect(meta.version, equals('1.0.0-gold'));
      expect(meta.supportsIncrementalSync, isTrue);

      final src = connector.source();
      expect(src.name, equals('PIB Releases'));
      expect(src.type, equals(EvidenceSourceType.government));
    });

    test('discover should return raw payloads with metadata', () async {
      final payloads = await connector.discover();
      expect(payloads.length, equals(2));
      expect(payloads.first.sourceIdentifier, equals('201001'));
      expect(payloads.first.metadata['ministry'], isNotNull);
    });

    test('fetch should return payload for specific PRID', () async {
      final payload = await connector.fetch('303030');
      expect(payload.sourceIdentifier, equals('303030'));
      expect(payload.metadata['title'], contains('303030'));
    });

    test('parseRaw should transform payload to EvidenceObject with lineage and lifecycle', () async {
      final payloads = await connector.discover();
      final evidence = await connector.parseRaw(payloads.first);

      expect(evidence.id, equals('EV-PIB-201001'));
      expect(evidence.title, contains('Green Hydrogen'));
      expect(evidence.sourceName, equals('PIB Releases'));
      expect(evidence.originalUrl, equals('https://pib.gov.in/PressReleasePage.aspx?PRID=201001'));
      expect(evidence.pdfUrl, equals('https://pib.gov.in/docs/201001.pdf'));

      // Check Lineage & Lifecycle
      expect(evidence.lineage, isNotNull);
      expect(evidence.lineage!.originalSource, equals('PIB Releases'));
      expect(evidence.lineage!.parserVersion, equals('1.0.0-gold'));

      expect(evidence.activeLifecycle.currentState, equals(EvidenceLifecycleState.parsed));
    });

    test('healthCheckDiagnostic should return healthy diagnostic status', () async {
      final health = await connector.healthCheckDiagnostic();
      expect(health.status, equals(SourceHealthStatus.healthy));
      expect(health.availabilityScore, equals(1.0));
    });
  });
}
