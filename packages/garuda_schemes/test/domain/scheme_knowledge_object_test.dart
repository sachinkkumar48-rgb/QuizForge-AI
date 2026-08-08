import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeKnowledgeObject Domain Model', () {
    final pmkisan = SchemeKnowledgeObject(
      id: 'sch_test',
      officialName: 'Test Scheme',
      shortName: 'TS',
      ministry: SchemeMinistry.agricultureFarmersWelfare,
      category: SchemeCategory.agriculture,
      sector: SchemeSector.agriculture,
      schemeType: SchemeType.centralSector,
      status: SchemeStatus.operational,
      launchDate: DateTime(2019, 2, 24),
      funding: const SchemeFundingDetail(
        fundingPattern: FundingPatternType.fullCentral,
        financialAssistance: '₹6,000/year',
      ),
      beneficiaries: const [BeneficiaryGroup.farmers],
      officialSource: 'https://www.pmkisan.gov.in/',
      evidenceIds: const ['ev_test_official'],
      lastVerifiedDate: '2026-06-30',
      editorialStatus: EditorialStatus.evidenceVerified,
      keywords: const ['Test', 'Scheme'],
      metadata: const {'region': 'All India'},
    );

    test('creates a fully-populated object with correct field values', () {
      expect(pmkisan.id, 'sch_test');
      expect(pmkisan.officialName, 'Test Scheme');
      expect(pmkisan.shortName, 'TS');
      expect(pmkisan.ministry.displayName, contains('Agriculture'));
      expect(pmkisan.category, SchemeCategory.agriculture);
      expect(pmkisan.launchDate!.year, 2019);
      expect(pmkisan.funding.financialAssistance, '₹6,000/year');
      expect(pmkisan.beneficiaries, contains(BeneficiaryGroup.farmers));
      expect(pmkisan.editorialStatus, EditorialStatus.evidenceVerified);
      expect(pmkisan.metadata['region'], 'All India');
    });

    test('toJson / fromJson round-trips all fields losslessly', () {
      final json = pmkisan.toJson();
      final restored = SchemeKnowledgeObject.fromJson(json);

      expect(restored.id, pmkisan.id);
      expect(restored.officialName, pmkisan.officialName);
      expect(restored.shortName, pmkisan.shortName);
      expect(restored.ministry, pmkisan.ministry);
      expect(restored.category, pmkisan.category);
      expect(restored.sector, pmkisan.sector);
      expect(restored.schemeType, pmkisan.schemeType);
      expect(restored.status, pmkisan.status);
      expect(restored.launchDate, pmkisan.launchDate);
      expect(restored.funding.fundingPattern, pmkisan.funding.fundingPattern);
      expect(restored.funding.financialAssistance,
          pmkisan.funding.financialAssistance);
      expect(restored.beneficiaries, pmkisan.beneficiaries);
      expect(restored.officialSource, pmkisan.officialSource);
      expect(restored.evidenceIds, pmkisan.evidenceIds);
      expect(restored.lastVerifiedDate, pmkisan.lastVerifiedDate);
      expect(restored.editorialStatus, pmkisan.editorialStatus);
      expect(restored.keywords, pmkisan.keywords);
      expect(restored.metadata['region'], 'All India');
    });

    test('copyWith replaces only the provided fields', () {
      final updated = pmkisan.copyWith(
        status: SchemeStatus.discontinued,
        version: 2,
        evidenceIds: const ['ev_test_official', 'ev_test_extra'],
      );
      expect(updated.status, SchemeStatus.discontinued);
      expect(updated.version, 2);
      expect(updated.evidenceIds, hasLength(2));
      expect(updated.id, pmkisan.id);
      expect(updated.officialName, pmkisan.officialName);
      expect(updated.ministry, pmkisan.ministry);
    });

    test('toGarudaKnowledgeObject bridges to the editorial registry contract',
        () {
      final ko = pmkisan.toGarudaKnowledgeObject();
      expect(ko.id, 'sch_test');
      expect(ko.title, 'Test Scheme');
      expect(ko.package, 'garuda_schemes');
      expect(ko.knowledgeType, 'SchemeKnowledgeObject');
      expect(ko.status, EditorialStatus.evidenceVerified);
      expect(ko.evidenceIds, contains('ev_test_official'));
      expect(ko.isVerified, isFalse); // evidenceVerified != published
    });

    test('benefits and components serialize as structured lists', () {
      final scheme = pmkisan.copyWith(
        benefits: const [
          SchemeBenefit(
            id: 'ben_t',
            title: 'Transfer',
            benefitType: SchemeBenefitType.directBenefitTransfer,
            quantum: '₹6,000',
          ),
        ],
        components: const [
          SchemeComponent(
            id: 'cmp_t',
            name: 'Component',
            coverage: 'All India',
          ),
        ],
      );
      final restored = SchemeKnowledgeObject.fromJson(scheme.toJson());
      expect(restored.benefits, hasLength(1));
      expect(restored.benefits.first.quantum, '₹6,000');
      expect(restored.benefits.first.benefitType,
          SchemeBenefitType.directBenefitTransfer);
      expect(restored.components, hasLength(1));
      expect(restored.components.first.name, 'Component');
    });

    test('cross-package link lists survive JSON round-trip', () {
      final scheme = pmkisan.copyWith(
        relatedArticleIds: const ['Article 21'],
        relatedActIds: const ['Test Act, 2000'],
        relatedCommitteeIds: const ['comm_test'],
        relatedReportIds: const ['rep_test'],
        relatedPyqIds: const ['PYQ_UPSC_CSE_2020_GS2_Q010'],
        relatedCurrentAffairsIds: const ['ca_test'],
        relatedSchemeIds: const ['sch_test_related'],
        sdgGoals: const [SdgGoal.noPoverty, SdgGoal.zeroHunger],
        relationships: const [
          SchemeRelationship(
            sourceId: 'sch_test',
            targetId: 'sch_test_related',
            relationshipType: SchemeRelationshipType.fundedBy,
            description: 'Test relation',
          ),
        ],
        timeline: [
          SchemeTimeline(
            date: DateTime(2019, 2, 24),
            milestone: 'Launched',
            description: 'Test launch.',
          ),
        ],
      );
      final restored = SchemeKnowledgeObject.fromJson(scheme.toJson());
      expect(restored.relatedArticleIds, const ['Article 21']);
      expect(restored.relatedActIds, const ['Test Act, 2000']);
      expect(restored.relatedPyqIds,
          const ['PYQ_UPSC_CSE_2020_GS2_Q010']);
      expect(restored.sdgGoals, contains(SdgGoal.zeroHunger));
      expect(restored.relationships, hasLength(1));
      expect(restored.relationships.first.relationshipType,
          SchemeRelationshipType.fundedBy);
      expect(restored.timeline, hasLength(1));
      expect(restored.timeline.first.date, DateTime(2019, 2, 24));
    });

    test('supporting value objects are immutable and JSON-serializable', () {
      const benefit = SchemeBenefit(
        id: 'b1',
        title: 'Benefit',
        benefitType: SchemeBenefitType.monetary,
        quantum: '₹100',
      );
      final b = SchemeBenefit.fromJson(benefit.toJson());
      expect(b.id, 'b1');
      expect(b.benefitType, SchemeBenefitType.monetary);

      const comp = SchemeComponent(id: 'c1', name: 'Comp');
      expect(SchemeComponent.fromJson(comp.toJson()).name, 'Comp');

      const rel = SchemeRelationship(
        sourceId: 'a',
        targetId: 'b',
        relationshipType: SchemeRelationshipType.subsumedBy,
      );
      final r = SchemeRelationship.fromJson(rel.toJson());
      expect(r.relationshipType, SchemeRelationshipType.subsumedBy);

      final tl = SchemeTimeline(
        date: DateTime(2020, 1, 1),
        milestone: 'M',
      );
      final t = SchemeTimeline.fromJson(tl.toJson());
      expect(t.date, DateTime(2020, 1, 1));
      expect(t.milestone, 'M');

      const funding = SchemeFundingDetail(
        fundingPattern: FundingPatternType.sharedCentreState,
        centralShare: '60:40',
      );
      expect(SchemeFundingDetail.fromJson(funding.toJson()).centralShare, '60:40');
    });
  });
}
