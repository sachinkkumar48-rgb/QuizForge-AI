import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('EvidenceObject Domain Entity Tests', () {
    final now = DateTime.now();
    const authority = EvidenceAuthority(
      id: 'pib_01',
      name: 'Press Information Bureau',
      type: EvidenceSourceType.government,
      jurisdiction: 'India',
    );

    final evidence = EvidenceObject(
      id: 'EV-2026-001',
      title: 'National Green Hydrogen Mission Progress',
      sourceName: 'PIB Releases',
      sourceType: EvidenceSourceType.government,
      authority: authority,
      publicationDate: now,
      retrievedDate: now,
      category: 'Environment',
      subject: 'Renewable Energy',
      topic: 'Green Hydrogen',
      subtopic: 'Electrolyser Manufacturing',
      keywords: const ['Hydrogen', 'Energy', 'PIB'],
      language: 'en',
      summary: 'Government announces updates on Green Hydrogen Mission.',
      originalUrl: 'https://pib.gov.in/PressReleasePage.aspx?PRID=10001',
      pdfUrl: 'https://pib.gov.in/docs/10001.pdf',
      confidenceScore: 0.98,
      verificationStatus: VerificationStatus.verified,
      editorialStatus: EditorialStatus.published,
      createdAt: now,
      updatedAt: now,
    );

    test('should support immutability and copyWith', () {
      final updated = evidence.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.id, evidence.id);
      expect(evidence.title, 'National Green Hydrogen Mission Progress');
    });

    test('should serialize to and deserialize from JSON correctly', () {
      final jsonMap = evidence.toJson();
      expect(jsonMap['id'], 'EV-2026-001');
      expect(jsonMap['sourceType'], 'government');
      expect(jsonMap['verificationStatus'], 'verified');

      final restored = EvidenceObject.fromJson(jsonMap);
      expect(restored.id, evidence.id);
      expect(restored.title, evidence.title);
      expect(restored.authority.id, evidence.authority.id);
      expect(restored.verificationStatus, evidence.verificationStatus);
    });

    test('should support KnowledgeObjectLinks for all 14 categories', () {
      const links = KnowledgeObjectLinks(
        constitutionArticles: ['Art 48A'],
        caseLaws: ['MC Mehta v. Union of India'],
        acts: ['Energy Conservation Act 2001'],
        amendments: ['Energy Conservation Amendment 2022'],
        committees: ['Kirit Parikh Committee'],
        reports: ['NITI Aayog Renewable Report'],
        schemes: ['SIGHT Scheme'],
        people: ['Minister of Power'],
        institutions: ['MNRE'],
        lessons: ['Module 4 - Energy Policy'],
        pyqs: ['UPSC Prelims 2023 Q45'],
        maps: ['India Green Hydrogen Hubs Map'],
        timeline: ['2030 Net Zero Milestone'],
        currentAffairs: ['CA-2026-FEB-001'],
      );

      final withLinks = evidence.copyWith(knowledgeObjectLinks: links);
      final jsonMap = withLinks.toJson();
      final restored = EvidenceObject.fromJson(jsonMap);

      expect(restored.knowledgeObjectLinks.constitutionArticles, contains('Art 48A'));
      expect(restored.knowledgeObjectLinks.caseLaws, contains('MC Mehta v. Union of India'));
      expect(restored.knowledgeObjectLinks.acts, contains('Energy Conservation Act 2001'));
      expect(restored.knowledgeObjectLinks.amendments, contains('Energy Conservation Amendment 2022'));
      expect(restored.knowledgeObjectLinks.committees, contains('Kirit Parikh Committee'));
      expect(restored.knowledgeObjectLinks.reports, contains('NITI Aayog Renewable Report'));
      expect(restored.knowledgeObjectLinks.schemes, contains('SIGHT Scheme'));
      expect(restored.knowledgeObjectLinks.people, contains('Minister of Power'));
      expect(restored.knowledgeObjectLinks.institutions, contains('MNRE'));
      expect(restored.knowledgeObjectLinks.lessons, contains('Module 4 - Energy Policy'));
      expect(restored.knowledgeObjectLinks.pyqs, contains('UPSC Prelims 2023 Q45'));
      expect(restored.knowledgeObjectLinks.maps, contains('India Green Hydrogen Hubs Map'));
      expect(restored.knowledgeObjectLinks.timeline, contains('2030 Net Zero Milestone'));
      expect(restored.knowledgeObjectLinks.currentAffairs, contains('CA-2026-FEB-001'));
    });
  });
}
