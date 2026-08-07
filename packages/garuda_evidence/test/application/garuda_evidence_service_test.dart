import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('GarudaEvidenceService Integration Tests', () {
    late GarudaEvidenceService service;
    final now = DateTime.now();

    setUp(() {
      service = GarudaEvidenceService();
    });

    test('All default collectors should be registered on service initialization', () {
      final collectors = service.getAllCollectors();
      expect(collectors.length, equals(17));

      expect(service.getCollector('PIB Releases'), isNotNull);
      expect(service.getCollector('Supreme Court Judgments'), isNotNull);
      expect(service.getCollector('ISRO Publications'), isNotNull);
    });

    test('ingestEvidence should validate and store evidence object', () async {
      final evidence = EvidenceObject(
        id: 'EV-SVC-01',
        title: 'NITI Aayog Health Index 2026',
        sourceName: 'NITI Aayog Reports',
        sourceType: EvidenceSourceType.report,
        authority: const EvidenceAuthority(
          id: 'niti',
          name: 'NITI Aayog',
          type: EvidenceSourceType.report,
          jurisdiction: 'India',
        ),
        publicationDate: now,
        retrievedDate: now,
        category: 'Health',
        subject: 'Governance',
        topic: 'Public Health',
        subtopic: 'State Rankings',
        keywords: const ['NITI', 'Health'],
        language: 'en',
        summary: 'NITI Aayog health index rankings summary.',
        originalUrl: 'https://niti.gov.in/health_index_2026.pdf',
        createdAt: now,
        updatedAt: now,
      );

      final valResult = await service.ingestEvidence(evidence);
      expect(valResult.isValid, isTrue);

      final searchRes = await service.search(const EvidenceSearchQuery(keyword: 'NITI'));
      expect(searchRes.length, equals(1));
      expect(searchRes.first.id, equals('EV-SVC-01'));
    });

    test('linkKnowledgeObject should link EvidenceObject to Knowledge Graph node', () async {
      final evidence = EvidenceObject(
        id: 'EV-LINK-01',
        title: 'Fundamental Rights and Freedom of Speech Judgment',
        sourceName: 'Supreme Court Judgments',
        sourceType: EvidenceSourceType.judiciary,
        authority: const EvidenceAuthority(
          id: 'sc',
          name: 'Supreme Court',
          type: EvidenceSourceType.judiciary,
          jurisdiction: 'India',
        ),
        publicationDate: now,
        retrievedDate: now,
        category: 'Judiciary',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        subtopic: 'Article 19',
        keywords: const ['Article 19', 'Speech'],
        language: 'en',
        summary: 'SC ruling on Article 19(1)(a).',
        originalUrl: 'https://sci.gov.in/judgments/001.pdf',
        createdAt: now,
        updatedAt: now,
      );

      await service.ingestEvidence(evidence);

      final updated = await service.linkKnowledgeObject(
        evidenceId: 'EV-LINK-01',
        type: KnowledgeObjectType.constitutionArticles,
        targetLinkId: 'Art-19-1-a',
      );

      expect(updated, isNotNull);
      expect(updated!.knowledgeObjectLinks.constitutionArticles, contains('Art-19-1-a'));
    });

    test('checkAllGatewaysHealth should return health status for all registered gateways', () async {
      final healthMap = await service.checkAllGatewaysHealth();
      expect(healthMap.length, equals(17));
      expect(healthMap['PIB Releases']?.isHealthy, isTrue);
    });
  });
}
