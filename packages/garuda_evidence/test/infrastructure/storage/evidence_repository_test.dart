import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('InMemoryEvidenceRepository Tests', () {
    late EvidenceRepository repo;
    late EvidenceObject item1;
    late EvidenceObject item2;
    final now = DateTime.now();

    setUp(() {
      repo = InMemoryEvidenceRepository();

      item1 = EvidenceObject(
        id: 'EV-001',
        title: 'RBI Monetary Policy Statement',
        sourceName: 'RBI Releases',
        sourceType: EvidenceSourceType.government,
        authority: const EvidenceAuthority(
          id: 'rbi',
          name: 'Reserve Bank of India',
          type: EvidenceSourceType.government,
          jurisdiction: 'India',
        ),
        publicationDate: now.subtract(const Duration(days: 2)),
        retrievedDate: now,
        category: 'Economy',
        subject: 'Banking',
        topic: 'Repo Rate',
        subtopic: 'Inflation Control',
        keywords: const ['RBI', 'Repo Rate', 'Banking'],
        language: 'en',
        summary: 'Repo rate kept unchanged at 6.5%.',
        originalUrl: 'https://rbi.org.in/press/001',
        confidenceScore: 0.95,
        verificationStatus: VerificationStatus.verified,
        editorialStatus: EditorialStatus.published,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      );

      item2 = EvidenceObject(
        id: 'EV-002',
        title: 'SEBI Circular on Algo Trading Framework',
        sourceName: 'SEBI Circulars',
        sourceType: EvidenceSourceType.government,
        authority: const EvidenceAuthority(
          id: 'sebi',
          name: 'Securities and Exchange Board of India',
          type: EvidenceSourceType.government,
          jurisdiction: 'India',
        ),
        publicationDate: now.subtract(const Duration(days: 1)),
        retrievedDate: now,
        category: 'Economy',
        subject: 'Markets',
        topic: 'Algo Trading',
        subtopic: 'Investor Protection',
        keywords: const ['SEBI', 'Algo Trading', 'Markets'],
        language: 'en',
        summary: 'SEBI mandates enhanced risk checks for algo trading.',
        originalUrl: 'https://sebi.gov.in/circulars/002',
        confidenceScore: 0.99,
        verificationStatus: VerificationStatus.verified,
        editorialStatus: EditorialStatus.published,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );
    });

    test('save, findById, update, and delete should work correctly', () async {
      await repo.save(item1);
      final fetched = await repo.findById('EV-001');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'RBI Monetary Policy Statement');

      final updated = item1.copyWith(title: 'Updated Policy');
      await repo.update(updated);
      final reFetched = await repo.findById('EV-001');
      expect(reFetched!.title, 'Updated Policy');

      final deleted = await repo.delete('EV-001');
      expect(deleted, isTrue);
      expect(await repo.findById('EV-001'), isNull);
    });

    test('findBySource, findByTopic, findByTag, findRecent', () async {
      await repo.save(item1);
      await repo.save(item2);

      final bySource = await repo.findBySource('RBI Releases');
      expect(bySource.length, equals(1));

      final byTopic = await repo.findByTopic('Repo Rate');
      expect(byTopic.length, equals(1));

      final byTag = await repo.findByTag('SEBI');
      expect(byTag.length, equals(1));

      final recent = await repo.findRecent(limit: 10);
      expect(recent.length, equals(2));
      expect(recent.first.id, equals('EV-002'));
    });

    test('search across 8 query vectors', () async {
      await repo.save(item1);
      await repo.save(item2);

      final kwSearch = await repo.search(const EvidenceSearchQuery(keyword: 'Algo'));
      expect(kwSearch.length, equals(1));
      expect(kwSearch.first.id, equals('EV-002'));

      final topicSearch = await repo.search(const EvidenceSearchQuery(topic: 'Repo Rate'));
      expect(topicSearch.length, equals(1));

      final dateSearch = await repo.search(EvidenceSearchQuery(
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.subtract(const Duration(days: 1, hours: 12)),
      ));
      expect(dateSearch.length, equals(1));
      expect(dateSearch.first.id, equals('EV-001'));
    });
  });
}
