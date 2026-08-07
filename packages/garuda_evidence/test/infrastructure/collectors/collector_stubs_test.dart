import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('Collector Stubs Infrastructure Tests', () {
    final collectors = <EvidenceCollector>[
      PIBCollector(),
      PRSCollector(),
      ParliamentCollector(),
      GazetteCollector(),
      SupremeCourtCollector(),
      HighCourtCollector(),
      RBICollector(),
      SEBICollector(),
      NITICollector(),
      CAGCollector(),
      ISROCollector(),
      DRDOCollector(),
      MinistryCollector(),
      WHOCollector(),
      UNCollector(),
      IMFCollector(),
      WorldBankCollector(),
    ];

    test('All 17 collector stubs must be instantiated and return healthy status', () async {
      expect(collectors.length, equals(17));

      for (final collector in collectors) {
        expect(collector.sourceName, isNotEmpty);

        final health = await collector.healthCheck();
        expect(health.isHealthy, isTrue);
        expect(health.sourceName, equals(collector.sourceName));

        final items = await collector.collect();
        expect(items, isEmpty);
      }
    });

    test('Collector stub parse should handle raw Map and EvidenceObject', () async {
      final collector = PIBCollector();
      final now = DateTime.now();
      final evidence = EvidenceObject(
        id: 'EV-PARSED-1',
        title: 'PIB Release Title',
        sourceName: 'PIB Releases',
        sourceType: EvidenceSourceType.government,
        authority: const EvidenceAuthority(
          id: 'pib',
          name: 'PIB',
          type: EvidenceSourceType.government,
          jurisdiction: 'India',
        ),
        publicationDate: now,
        retrievedDate: now,
        category: 'Governance',
        subject: 'Polity',
        topic: 'Schemes',
        subtopic: 'Digital India',
        keywords: const ['Digital'],
        language: 'en',
        summary: 'Digital India update.',
        originalUrl: 'https://pib.gov.in/release1',
        createdAt: now,
        updatedAt: now,
      );

      final parsedFromObj = await collector.parse(evidence);
      expect(parsedFromObj.id, 'EV-PARSED-1');

      final parsedFromMap = await collector.parse(evidence.toJson());
      expect(parsedFromMap.id, 'EV-PARSED-1');
    });
  });
}
