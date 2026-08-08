import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalKnowledgeObject Domain Model', () {
    final who = InternationalKnowledgeObject(
      id: 'int_test',
      officialName: 'World Health Organization',
      shortName: 'World Health Organization',
      acronym: 'WHO',
      bodyType: InternationalBodyType.specialisedAgency,
      category: InternationalCategory.unitedNations,
      institutionalStatus: InstitutionalStatus.active,
      treatyStatus: TreatyStatus.establishedByCharter,
      membershipType: MembershipType.fullMember,
      membershipScope: MembershipScope.global,
      decisionMakingModel: DecisionMakingModel.oneMemberOneVote,
      fundingModel: FundingModel.assessedContributions,
      headquarters: 'Geneva, Switzerland',
      headquartersRegion: HeadquartersRegion.europe,
      establishedYear: 1948,
      foundingTreaty: 'WHO Constitution, 1946',
      secretariat: 'WHO Secretariat',
      membershipCount: 194,
      principalOrgans: 'World Health Assembly, Executive Board, Secretariat',
      leadershipStructure: 'Director-General',
      votingMechanism: 'One member, one vote',
      mandate: 'Direct international health work and set global health standards.',
      objectives: const ['Set norms and standards', 'Coordinate health emergencies'],
      functions: const ['Declare PHEIC', 'Set international health standards'],
      powers: const ['International Health Regulations coordination'],
      fundingMechanism: 'Assessed and voluntary contributions',
      importantConventions: const ['International Health Regulations, 2005'],
      geographicalRegion: GeographicalRegion.global,
      issueAreas: const [GlobalIssueArea.health],
      indiaMembership: IndiaRelationshipStatus.foundingMember,
      indiaJoiningYear: 1948,
      indiaRole: 'Founding Member and active in global health initiatives.',
      currentRelevance: 'Pandemic preparedness and WHO reform.',
      indiaRelevance: 'India is a founding member and key player in WHO programmes.',
      upscRelevance: UpscRelevanceLevel.high,
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.medium,
      prelimsTraps: const ['WHO HQ Geneva', 'Founded 1948'],
      mainsThemes: const ['Global health governance'],
      essayThemes: const ['Global health and development'],
      interviewAreas: const ['WHO reform'],
      relatedOrganisationIds: const ['int_un'],
      relationships: const [
        InternationalRelationship(
          sourceId: 'int_test',
          targetId: 'int_un',
          relationshipType: InternationalRelationshipType.memberOf,
          description: 'WHO is a specialised agency of the UN.',
        ),
      ],
      officialSource: 'https://www.who.int/',
      evidenceIds: const ['ev_test_official'],
      lastVerifiedDate: '2026-06-30',
      editorialStatus: EditorialStatus.evidenceVerified,
      keywords: const ['WHO', 'Global Health', 'Geneva'],
      metadata: const {'region': 'Global'},
    );

    test('creates a fully-populated object with correct field values', () {
      expect(who.id, 'int_test');
      expect(who.officialName, 'World Health Organization');
      expect(who.acronym, 'WHO');
      expect(who.bodyType, InternationalBodyType.specialisedAgency);
      expect(who.category, InternationalCategory.unitedNations);
      expect(who.establishedYear, 1948);
      expect(who.headquarters, 'Geneva, Switzerland');
      expect(who.indiaMembership, IndiaRelationshipStatus.foundingMember);
      expect(who.upscRelevance, UpscRelevanceLevel.high);
      expect(who.metadata['region'], 'Global');
    });

    test('toJson / fromJson round-trips all fields losslessly', () {
      final json = who.toJson();
      final restored = InternationalKnowledgeObject.fromJson(json);

      expect(restored.id, who.id);
      expect(restored.officialName, who.officialName);
      expect(restored.acronym, who.acronym);
      expect(restored.bodyType, who.bodyType);
      expect(restored.category, who.category);
      expect(restored.institutionalStatus, who.institutionalStatus);
      expect(restored.treatyStatus, who.treatyStatus);
      expect(restored.membershipType, who.membershipType);
      expect(restored.decisionMakingModel, who.decisionMakingModel);
      expect(restored.fundingModel, who.fundingModel);
      expect(restored.establishedYear, who.establishedYear);
      expect(restored.foundingTreaty, who.foundingTreaty);
      expect(restored.headquartersRegion, who.headquartersRegion);
      expect(restored.geographicalRegion, who.geographicalRegion);
      expect(restored.issueAreas, who.issueAreas);
      expect(restored.indiaMembership, who.indiaMembership);
      expect(restored.indiaJoiningYear, who.indiaJoiningYear);
      expect(restored.upscRelevance, who.upscRelevance);
      expect(restored.officialSource, who.officialSource);
      expect(restored.evidenceIds, who.evidenceIds);
      expect(restored.lastVerifiedDate, who.lastVerifiedDate);
      expect(restored.editorialStatus, who.editorialStatus);
      expect(restored.keywords, who.keywords);
      expect(restored.metadata['region'], 'Global');
    });

    test('copyWith replaces only the provided fields', () {
      final updated = who.copyWith(
        institutionalStatus: InstitutionalStatus.reformed,
        version: 2,
        evidenceIds: const ['ev_test_official', 'ev_test_extra'],
      );
      expect(updated.institutionalStatus, InstitutionalStatus.reformed);
      expect(updated.version, 2);
      expect(updated.evidenceIds, hasLength(2));
      expect(updated.id, who.id);
      expect(updated.officialName, who.officialName);
      expect(updated.acronym, who.acronym);
    });

    test('toGarudaKnowledgeObject bridges to the editorial registry contract',
        () {
      final ko = who.toGarudaKnowledgeObject();
      expect(ko.id, 'int_test');
      expect(ko.title, 'World Health Organization');
      expect(ko.package, 'garuda_international');
      expect(ko.knowledgeType, 'InternationalKnowledgeObject');
      expect(ko.evidenceIds, contains('ev_test_official'));
      expect(ko.isVerified, isFalse); // evidenceVerified != published
    });

    test('cross-package link lists survive JSON round-trip', () {
      final org = who.copyWith(
        relatedArticleIds: const ['Article 51'],
        relatedActIds: const ['Test Act, 2000'],
        relatedSchemeIds: const ['sch_pm_jay'],
        relatedCurrentAffairsIds: const ['ca_test'],
        relatedPyqIds: const ['PYQ_UPSC_CSE_2020_GS2_Q010'],
        sdgGoals: const ['SDG 3 - Good Health & Well-being'],
      );
      final restored = InternationalKnowledgeObject.fromJson(org.toJson());
      expect(restored.relatedArticleIds, const ['Article 51']);
      expect(restored.relatedActIds, const ['Test Act, 2000']);
      expect(restored.relatedSchemeIds, const ['sch_pm_jay']);
      expect(restored.relatedPyqIds, const ['PYQ_UPSC_CSE_2020_GS2_Q010']);
      expect(restored.sdgGoals, const ['SDG 3 - Good Health & Well-being']);
    });

    test('InternationalRelationship value object serializes and deserializes',
        () {
      const rel = InternationalRelationship(
        sourceId: 'int_a',
        targetId: 'int_b',
        relationshipType: InternationalRelationshipType.partnerOf,
        description: 'A is a partner of B',
      );
      final r = InternationalRelationship.fromJson(rel.toJson());
      expect(r.sourceId, 'int_a');
      expect(r.targetId, 'int_b');
      expect(r.relationshipType, InternationalRelationshipType.partnerOf);
      expect(r.description, 'A is a partner of B');
    });
  });
}
