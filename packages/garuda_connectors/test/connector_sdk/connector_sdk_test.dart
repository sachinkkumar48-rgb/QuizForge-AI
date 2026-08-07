import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:test/test.dart';

void main() {
  group('Connector SDK Tests', () {
    final now = DateTime.now();

    test('RawEvidencePayload serialization and equality', () {
      final payload = RawEvidencePayload(
        sourceIdentifier: '201001',
        rawContent: '<html>PIB content</html>',
        contentType: 'text/html',
        fetchedAt: now,
        metadata: const {'prid': '201001'},
      );

      expect(payload.sourceIdentifier, equals('201001'));
      final json = payload.toJson();
      expect(json['contentType'], equals('text/html'));
    });

    test('ConnectorMetadata serialization and attributes', () {
      const source = EvidenceSource(
        id: 'src_pib',
        name: 'PIB Releases',
        type: EvidenceSourceType.government,
        baseUrl: 'https://pib.gov.in',
      );

      const meta = ConnectorMetadata(
        connectorName: 'PIBConnector',
        source: source,
        version: '1.0.0-gold',
        categories: ['Polity', 'Economy'],
        subjects: ['Polity', 'Economy'],
      );

      expect(meta.connectorName, equals('PIBConnector'));
      expect(meta.supportsIncrementalSync, isTrue);
      final json = meta.toJson();
      expect(json['version'], equals('1.0.0-gold'));
    });

    test('ConnectorHealth serialization and status', () {
      const health = ConnectorHealth(
        connectorName: 'PIBConnector',
        status: SourceHealthStatus.healthy,
        latencyMs: 35.0,
        availabilityScore: 0.999,
        message: 'Healthy',
      );

      expect(health.status, equals(SourceHealthStatus.healthy));
      final json = health.toJson();
      expect(json['availabilityScore'], equals(0.999));
    });
  });
}
