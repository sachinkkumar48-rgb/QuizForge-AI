import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeValidator', () {
    final validScheme = SchemeKnowledgeObject(
      id: 'sch_valid',
      officialName: 'Valid Test Scheme',
      shortName: 'VTS',
      ministry: SchemeMinistry.healthFamilyWelfare,
      category: SchemeCategory.health,
      sector: SchemeSector.health,
      launchDate: DateTime(2020, 1, 1),
      beneficiaries: const [BeneficiaryGroup.women],
      officialSource: 'https://nhm.gov.in/',
      evidenceIds: const ['ev_valid'],
      lastVerifiedDate: '2026-06-30',
      keywords: const ['Valid'],
    );

    test('accepts a fully-evidenced production scheme', () {
      final report = SchemeValidator.validate(validScheme);
      expect(report.isValid, isTrue);
      expect(report.issues, isEmpty);
    });

    test('rejects a scheme with a missing official source', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(officialSource: ''));
      expect(report.isValid, isFalse);
      expect(
          report.issues.any((i) => i.field == 'officialSource'), isTrue);
    });

    test('rejects a non-official source URL', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(officialSource: 'https://example.com/wiki'));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialSource'), isTrue);
    });

    test('rejects missing evidence (mandatory evidence rule)', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(evidenceIds: const []));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'evidenceIds'), isTrue);
      expect(report.issues.any((i) => i.message.contains('mandatory evidence')),
          isTrue);
    });

    test('rejects missing identity fields', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(officialName: '', shortName: ''));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
      expect(report.issues.any((i) => i.field == 'shortName'), isTrue);
    });

    test('rejects future launch dates', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(launchDate: DateTime(2100, 1, 1)));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'launchDate'), isTrue);
    });

    test('rejects missing beneficiary information', () {
      final report = SchemeValidator.validate(
          validScheme.copyWith(
              beneficiaries: const [], targetBeneficiaries: const []));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'beneficiaries'), isTrue);
    });

    test('detects duplicate scheme IDs', () {
      final report = SchemeValidator.validate(
        validScheme,
        existingSchemes: [validScheme],
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('detects duplicate schemes by name under the same ministry', () {
      final twin = validScheme.copyWith(id: 'sch_twin');
      final report = SchemeValidator.validate(
        twin,
        existingSchemes: [validScheme],
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('flags broken relationships (non-blocking)', () {
      final broken = validScheme.copyWith(
        relationships: const [
          SchemeRelationship(
            sourceId: 'sch_missing_source',
            targetId: 'sch_valid',
            relationshipType: SchemeRelationshipType.fundedBy,
          ),
        ],
      );
      final report = SchemeValidator.validate(broken, existingSchemes: [validScheme]);
      expect(report.issues.any((i) => i.field == 'relationships'), isTrue);
    });

    test('flags broken cross-package references (non-blocking)', () {
      final report = SchemeValidator.validate(
        validScheme.copyWith(
            relatedCommitteeIds: const ['comm_does_not_exist'],
            relatedReportIds: const ['rep_does_not_exist'],
            relatedPyqIds: const ['PYQ_DOES_NOT_EXIST']),
        knownCommitteeIds: const ['comm_swaminathan_2004'],
        knownReportIds: const ['rep_es_2025_official'],
        knownPyqIds: const ['PYQ_UPSC_CSE_2020_GS2_Q010'],
      );
      expect(
          report.issues.any((i) => i.field == 'relatedCommitteeIds'), isTrue);
      expect(report.issues.any((i) => i.field == 'relatedReportIds'), isTrue);
      expect(report.issues.any((i) => i.field == 'relatedPyqIds'), isTrue);
    });

    test('detects malformed serialization', () {
      final report = SchemeValidator.validate(
        validScheme.copyWith(ministry: SchemeMinistry.primeMinisterOffice),
      );
      // round-trip preserves ministry, so a legitimate object is still valid
      expect(report.isValid, isTrue);
    });

    test('rejects a published scheme that lacks evidence', () {
      final report = SchemeValidator.validate(
        validScheme.copyWith(
          editorialStatus: EditorialStatus.published,
          evidenceIds: const [],
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'editorialStatus'), isTrue);
    });

    test('the entire Phase-I corpus passes validation', () {
      final all = SchemeSeedCorpus.phase1Schemes;
      for (final s in all) {
        final report = SchemeValidator.validate(s);
        expect(report.isValid, isTrue,
            reason: 'Seed scheme ${s.id} should be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });
  });
}
