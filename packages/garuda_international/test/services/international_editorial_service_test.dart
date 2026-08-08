import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalEditorialService', () {
    final org = InternationalKnowledgeObject(
      id: 'int_editorial',
      officialName: 'United Nations Office on Drugs and Crime',
      shortName: 'UN Office on Drugs and Crime',
      acronym: 'UNODC',
      bodyType: InternationalBodyType.programme,
      category: InternationalCategory.unitedNations,
      institutionalStatus: InstitutionalStatus.active,
      treatyStatus: TreatyStatus.establishedByResolution,
      establishedYear: 1997,
      foundingTreaty:
          'Established 1997 by UN General Assembly (merger of UNDCP and the Centre for International Crime Prevention)',
      headquarters: 'Vienna, Austria',
      headquartersRegion: HeadquartersRegion.europe,
      mandate:
          'Assist the UN in addressing a coordinated response to drugs and crime.',
      membershipType: MembershipType.fullMember,
      geographicalRegion: GeographicalRegion.global,
      issueAreas: const [GlobalIssueArea.counterTerrorism, GlobalIssueArea.antiMoneyLaundering],
      indiaMembership: IndiaRelationshipStatus.fullMember,
      officialSource: 'https://www.unodc.org/',
      evidenceIds: const [
        'ev_unodc_official',
        'ev_unodc_pib',
        'ev_unodc_portal',
      ],
      lastVerifiedDate: '2026-06-30',
      relatedArticleIds: const ['Article 51', 'Article 253'],
      keywords: const ['UNODC', 'Drugs', 'Crime', 'Organised Crime'],
    );

    test('submits into the editorial workflow and registers in the registry',
        () {
      final service = InternationalEditorialService();
      service.submitToEditorialWorkflow(org);

      final ko = service.workflowEngine.getKnowledgeObject('int_editorial');
      expect(ko, isNotNull);
      expect(ko!.title, 'United Nations Office on Drugs and Crime');
      expect(ko.knowledgeType, 'InternationalKnowledgeObject');
      expect(ko.evidenceIds, isNotEmpty);
    });

    test('advances through the sequential editorial lifecycle', () {
      final service = InternationalEditorialService();
      service.submitToEditorialWorkflow(org);

      final first = service.advanceEditorialStage(
        objectId: 'int_editorial',
        actorId: 'ed1',
        actorName: 'Editor',
      );
      expect(first.isSuccess, isTrue);
      expect(first.updatedObject.status, isNot(EditorialStatus.imported));

      final second = service.advanceEditorialStage(
        objectId: 'int_editorial',
        actorId: 'ed2',
        actorName: 'Peer Reviewer',
      );
      expect(second.isSuccess, isTrue);
    });

    test('calculates a quality score for the organisation', () {
      final service = InternationalEditorialService();
      final approved =
          org.copyWith(editorialStatus: EditorialStatus.approved);
      final score = service.calculateQualityScore(approved);
      expect(score, isNotNull);
      expect(score.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('publishes only through the quality gate and updates status/version',
        () {
      final service = InternationalEditorialService();
      service.submitToEditorialWorkflow(org);

      final approved =
          org.copyWith(editorialStatus: EditorialStatus.approved);
      final published = service.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);
      expect(published.version, greaterThan(approved.version));
    });

    test('refuses to publish an object that fails the quality gate', () {
      final service = InternationalEditorialService();
      service.submitToEditorialWorkflow(org);

      final gated = org.copyWith(
        editorialStatus: EditorialStatus.approved,
        evidenceIds: const [],
        officialSource: '',
      );

      expect(
        () => service.publishObject(
          gated,
          actorId: 'editor_001',
          actorName: 'Chief Editor',
        ),
        throwsA(anything),
      );
    });
  });
}
