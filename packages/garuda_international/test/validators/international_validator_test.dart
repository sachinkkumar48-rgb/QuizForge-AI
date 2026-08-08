import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalValidator', () {
    final validOrg = InternationalKnowledgeObject(
      id: 'int_valid',
      officialName: 'Valid International Organisation',
      shortName: 'Valid Org',
      acronym: 'VIO',
      bodyType: InternationalBodyType.organisation,
      category: InternationalCategory.regionalGrouping,
      institutionalStatus: InstitutionalStatus.active,
      treatyStatus: TreatyStatus.notApplicable,
      membershipType: MembershipType.fullMember,
      membershipScope: MembershipScope.regional,
      decisionMakingModel: DecisionMakingModel.consensus,
      fundingModel: FundingModel.memberContributions,
      headquarters: 'New Delhi',
      headquartersRegion: HeadquartersRegion.india,
      establishedYear: 2010,
      mandate: 'Valid organisation mandate.',
      geographicalRegion: GeographicalRegion.southAsia,
      issueAreas: const [GlobalIssueArea.economy],
      indiaMembership: IndiaRelationshipStatus.fullMember,
      indiaJoiningYear: 2010,
      indiaRelevance: 'India is a member.',
      upscRelevance: UpscRelevanceLevel.high,
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.medium,
      officialSource: 'https://www.un.org/',
      evidenceIds: const ['ev_valid'],
      lastVerifiedDate: '2026-06-30',
      keywords: const ['Valid', 'Organisation'],
    );

    test('accepts a fully-evidenced production organisation', () {
      final report = InternationalValidator.validate(validOrg);
      expect(report.isValid, isTrue,
          reason: report.issues.map((i) => i.message).join(' | '));
      expect(report.issues, isEmpty);
    });

    test('rejects an organisation with a missing official name', () {
      final report =
          InternationalValidator.validate(validOrg.copyWith(officialName: ''));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
    });

    test('rejects a default-filled (unclassified) record', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(
          bodyType: InternationalBodyType.organisation,
          category: InternationalCategory.unitedNations,
          establishedYear: 0,
          headquarters: '',
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'bodyType'), isTrue);
    });

    test('rejects missing mandatory evidence', () {
      final report =
          InternationalValidator.validate(validOrg.copyWith(evidenceIds: const []));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'evidenceIds'), isTrue);
      expect(
          report.issues.any((i) => i.message.contains('mandatory evidence')),
          isTrue);
    });

    test('rejects a non-official / fabricated source URL', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(
            officialSource: 'https://en.wikipedia.org/wiki/WHO'),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialSource'), isTrue);
    });

    test('rejects invalid founding dates', () {
      final report =
          InternationalValidator.validate(validOrg.copyWith(establishedYear: 0));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'establishedYear'), isTrue);
    });

    test('rejects contradictory treaty metadata', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(
          treatyStatus: TreatyStatus.establishedByCharter,
          foundingTreaty: '',
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'foundingTreaty'), isTrue);
    });

    test('rejects invalid membership data', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(membershipCount: 0),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'membershipCount'), isTrue);
    });

    test('rejects contradictory India relationship metadata', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(
          indiaMembership: IndiaRelationshipStatus.nonMember,
          indiaJoiningYear: 2010,
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'indiaJoiningYear'), isTrue);
    });

    test('flags missing India joining year for founding members (non-blocking)',
        () {
      final foundingOrg = InternationalKnowledgeObject(
        id: 'int_founding',
        officialName: 'Founding Member Org',
        shortName: 'Founding Org',
        acronym: 'FMO',
        bodyType: InternationalBodyType.organisation,
        category: InternationalCategory.regionalGrouping,
        establishedYear: 2000,
        headquarters: 'New Delhi',
        mandate: 'Founding member organisation.',
        indiaMembership: IndiaRelationshipStatus.foundingMember,
        // indiaJoiningYear intentionally not set.
        officialSource: 'https://www.un.org/',
        evidenceIds: const ['ev_founding'],
      );
      final report = InternationalValidator.validate(foundingOrg);
      expect(report.issues.any((i) => i.field == 'indiaJoiningYear'), isTrue);
      // Non-blocking: the record remains valid for publication.
      expect(report.isValid, isTrue);
    });

    test('rejects a placeholder record', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(officialName: 'Placeholder Org', mandate: ''),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
      expect(report.issues.any((i) => i.field == 'mandate'), isTrue);
    });

    test('detects duplicate organisation IDs and names', () {
      final report = InternationalValidator.validate(
        validOrg,
        existingOrganisations: [validOrg],
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);

      final twin = validOrg.copyWith(id: 'int_twin');
      final nameReport = InternationalValidator.validate(
        twin,
        existingOrganisations: [validOrg],
      );
      expect(nameReport.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('flags broken relationship references (non-blocking)', () {
      final broken = validOrg.copyWith(
        relationships: const [
          InternationalRelationship(
            sourceId: 'int_missing',
            targetId: 'int_valid',
            relationshipType: InternationalRelationshipType.partnerOf,
          ),
        ],
      );
      final report = InternationalValidator.validate(
        broken,
        existingOrganisations: [validOrg],
      );
      expect(report.issues.any((i) => i.field == 'relationships'), isTrue);
    });

    test('rejects a published organisation that lacks evidence', () {
      final report = InternationalValidator.validate(
        validOrg.copyWith(
          editorialStatus: EditorialStatus.published,
          evidenceIds: const [],
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'editorialStatus'), isTrue);
    });

    test('the entire Phase-I corpus passes validation', () {
      final all = InternationalSeedCorpus.phase1Organisations;
      for (final o in all) {
        final report = InternationalValidator.validate(o);
        expect(report.isValid, isTrue,
            reason: 'Seed org ${o.id} should be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });

    test('corpus integrity: no duplicate IDs, evidence everywhere, valid India metadata',
        () {
      final all = InternationalSeedCorpus.phase1Organisations;
      final ids = all.map((o) => o.id).toSet();
      expect(ids.length, all.length); // no duplicate IDs

      for (final o in all) {
        expect(o.evidenceIds, isNotEmpty,
            reason: '${o.id} must carry official evidence');
        expect(o.officialSource.trim(), isNotEmpty,
            reason: '${o.id} must carry an official source');
        expect(o.establishedYear, greaterThan(0),
            reason: '${o.id} must have a valid founding year');
        expect(o.mandate.trim(), isNotEmpty,
            reason: '${o.id} must have a mandate (no placeholders)');

        // Valid India-relationship metadata: joining year only when India is a member.
        if (o.indiaMembership == IndiaRelationshipStatus.nonMember ||
            o.indiaMembership == IndiaRelationshipStatus.notApplicable) {
          expect(o.indiaJoiningYear, isNull,
              reason: '${o.id} must not have a joining year for '
                  '${o.indiaMembership.name}');
        }
      }
    });
  });
}
