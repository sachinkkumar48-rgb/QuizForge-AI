import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('BodyKnowledgeObject Domain Model', () {
    final eci = BodyKnowledgeObject(
      id: 'bod_test',
      officialName: 'Election Commission of India',
      shortName: 'ECI',
      bodyType: BodyType.constitutional,
      category: BodyCategory.commission,
      constitutionalBasis: ConstitutionalBasis.directArticle,
      statutoryBasis: StatutoryBasis.constitutionItself,
      bodyStatus: BodyStatus.active,
      bodyIndependence: BodyIndependence.constitutionallyIndependent,
      yearEstablished: 1950,
      establishingArticleIds: const ['Article 324'],
      establishingActIds: const ['Representation of the People Act, 1951'],
      parentMinistry: 'Not under any Ministry (constitutionally independent)',
      headquarters: 'New Delhi',
      jurisdiction: BodyJurisdiction.national,
      mandate: 'Superintendence, direction and control of elections.',
      powers: const ['Prepare electoral rolls', 'Conduct elections'],
      functions: const ['Hold elections to Parliament'],
      composition: 'Chief Election Commissioner and two Election Commissioners',
      appointmentMechanism: 'Appointed by the President',
      appointmentAuthority: AppointmentAuthority.president,
      tenure: '6 years or 65 years of age',
      tenureType: TenureType.ageBased,
      removalMechanism: 'Removable like a Supreme Court Judge',
      reportingAuthority: ReportingAuthority.parliament,
      financialStructure: 'Charged on the Consolidated Fund of India',
      upscRelevance: UpscRelevanceLevel.high,
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      relatedArticleIds: const ['Article 324'],
      relatedActIds: const ['Representation of the People Act, 1951'],
      relatedBodyIds: const ['bod_state_election_commissions'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      relationships: const [
        BodyRelationship(
          sourceId: 'bod_test',
          targetId: 'bod_state_election_commissions',
          relationshipType: BodyRelationshipType.supervises,
          description: 'Supervises the framework of State Election Commissions.',
        ),
      ],
      officialSource: 'https://eci.gov.in/',
      evidenceIds: const ['ev_test_official'],
      lastVerifiedDate: '2026-06-30',
      editorialStatus: EditorialStatus.evidenceVerified,
      keywords: const ['Election Commission', 'ECI', 'Elections'],
      metadata: const {'jurisdictionNote': 'All India'},
    );

    test('creates a fully-populated object with correct field values', () {
      expect(eci.id, 'bod_test');
      expect(eci.officialName, 'Election Commission of India');
      expect(eci.shortName, 'ECI');
      expect(eci.bodyType, BodyType.constitutional);
      expect(eci.category, BodyCategory.commission);
      expect(eci.yearEstablished, 1950);
      expect(eci.establishingArticleIds, const ['Article 324']);
      expect(eci.appointmentAuthority, AppointmentAuthority.president);
      expect(eci.tenureType, TenureType.ageBased);
      expect(eci.upscRelevance, UpscRelevanceLevel.high);
      expect(eci.metadata['jurisdictionNote'], 'All India');
    });

    test('toJson / fromJson round-trips all fields losslessly', () {
      final json = eci.toJson();
      final restored = BodyKnowledgeObject.fromJson(json);

      expect(restored.id, eci.id);
      expect(restored.officialName, eci.officialName);
      expect(restored.shortName, eci.shortName);
      expect(restored.bodyType, eci.bodyType);
      expect(restored.category, eci.category);
      expect(restored.constitutionalBasis, eci.constitutionalBasis);
      expect(restored.statutoryBasis, eci.statutoryBasis);
      expect(restored.yearEstablished, eci.yearEstablished);
      expect(restored.establishingArticleIds, eci.establishingArticleIds);
      expect(restored.establishingActIds, eci.establishingActIds);
      expect(restored.jurisdiction, eci.jurisdiction);
      expect(restored.appointmentAuthority, eci.appointmentAuthority);
      expect(restored.tenureType, eci.tenureType);
      expect(restored.upscRelevance, eci.upscRelevance);
      expect(restored.officialSource, eci.officialSource);
      expect(restored.evidenceIds, eci.evidenceIds);
      expect(restored.lastVerifiedDate, eci.lastVerifiedDate);
      expect(restored.editorialStatus, eci.editorialStatus);
      expect(restored.keywords, eci.keywords);
      expect(restored.metadata['jurisdictionNote'], 'All India');
    });

    test('copyWith replaces only the provided fields', () {
      final updated = eci.copyWith(
        bodyStatus: BodyStatus.reconstituted,
        version: 2,
        evidenceIds: const ['ev_test_official', 'ev_test_extra'],
      );
      expect(updated.bodyStatus, BodyStatus.reconstituted);
      expect(updated.version, 2);
      expect(updated.evidenceIds, hasLength(2));
      expect(updated.id, eci.id);
      expect(updated.officialName, eci.officialName);
      expect(updated.establishingArticleIds, eci.establishingArticleIds);
    });

    test('toGarudaKnowledgeObject bridges to the editorial registry contract',
        () {
      final ko = eci.toGarudaKnowledgeObject();
      expect(ko.id, 'bod_test');
      expect(ko.title, 'Election Commission of India');
      expect(ko.package, 'garuda_bodies');
      expect(ko.knowledgeType, 'BodyKnowledgeObject');
      expect(ko.evidenceIds, contains('ev_test_official'));
      expect(ko.relatedArticles, contains('Article 324'));
      expect(ko.isVerified, isFalse); // evidenceVerified != published
    });

    test('cross-package link lists survive JSON round-trip', () {
      final body = eci.copyWith(
        relatedCaseLawIds: const ['Vineet Narain v. Union of India'],
        relatedDoctrineIds: const ['Basic Structure Doctrine'],
        relatedCommitteeIds: const ['comm_pac'],
        relatedReportIds: const ['rep_cag_official'],
        relatedSchemeIds: const ['sch_pmjdy'],
        relatedCurrentAffairsIds: const ['ca_test'],
        relatedPyqIds: const ['PYQ_UPSC_CSE_2021_GS2_Q009'],
      );
      final restored = BodyKnowledgeObject.fromJson(body.toJson());
      expect(restored.relatedCaseLawIds,
          const ['Vineet Narain v. Union of India']);
      expect(restored.relatedDoctrineIds, const ['Basic Structure Doctrine']);
      expect(restored.relatedCommitteeIds, const ['comm_pac']);
      expect(restored.relatedReportIds, const ['rep_cag_official']);
      expect(restored.relatedSchemeIds, const ['sch_pmjdy']);
      expect(restored.relatedPyqIds, const ['PYQ_UPSC_CSE_2021_GS2_Q009']);
    });

    test('BodyRelationship value object serializes and deserializes', () {
      const rel = BodyRelationship(
        sourceId: 'bod_a',
        targetId: 'bod_b',
        relationshipType: BodyRelationshipType.regulates,
        description: 'A regulates B',
      );
      final r = BodyRelationship.fromJson(rel.toJson());
      expect(r.sourceId, 'bod_a');
      expect(r.targetId, 'bod_b');
      expect(r.relationshipType, BodyRelationshipType.regulates);
      expect(r.description, 'A regulates B');
    });
  });
}
