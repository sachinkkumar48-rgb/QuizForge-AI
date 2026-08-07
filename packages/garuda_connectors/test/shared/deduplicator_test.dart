import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:test/test.dart';

void main() {
  group('EvidenceDeduplicator Tests', () {
    final now = DateTime.now();

    final obj1 = EvidenceObject(
      id: 'EV-PIB-201',
      title: 'Cabinet approves National Green Hydrogen Mission',
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
      category: 'Environment',
      subject: 'Energy',
      topic: 'Green Hydrogen',
      subtopic: 'MNRE',
      keywords: const ['Hydrogen'],
      language: 'en',
      summary: 'Green Hydrogen Mission approved by Cabinet',
      originalUrl: 'https://pib.gov.in/PressReleasePage.aspx?PRID=201',
      createdAt: now,
      updatedAt: now,
    );

    test('titleSimilarity calculation', () {
      final sim = EvidenceDeduplicator.titleSimilarity(
        'Cabinet approves National Green Hydrogen Mission',
        'Cabinet approves Green Hydrogen Mission',
      );
      expect(sim, greaterThan(0.7));
    });

    test('isDuplicate checks URL and exact ID match', () {
      final objSameUrl = obj1.copyWith(id: 'EV-PIB-DIFFERENT-ID');
      expect(EvidenceDeduplicator.isDuplicate(objSameUrl, obj1), isTrue);

      final objUnique = obj1.copyWith(
        id: 'EV-PIB-999',
        title: 'Completely Unrelated Subject Announcement',
        originalUrl: 'https://pib.gov.in/PressReleasePage.aspx?PRID=999',
      );
      expect(EvidenceDeduplicator.isDuplicate(objUnique, obj1), isFalse);
    });
  });
}
