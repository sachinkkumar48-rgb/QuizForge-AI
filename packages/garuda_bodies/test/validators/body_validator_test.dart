import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('BodyValidator', () {
    final validBody = BodyKnowledgeObject(
      id: 'bod_valid',
      officialName: 'Valid Test Body',
      shortName: 'VTB',
      bodyType: BodyType.constitutional,
      category: BodyCategory.commission,
      constitutionalBasis: ConstitutionalBasis.directArticle,
      statutoryBasis: StatutoryBasis.constitutionItself,
      yearEstablished: 2000,
      establishingArticleIds: const ['Article 324'],
      establishingActIds: const ['Representation of the People Act, 1951'],
      headquarters: 'New Delhi',
      jurisdiction: BodyJurisdiction.national,
      mandate: 'Valid body mandate.',
      appointmentMechanism: 'Appointed by the President',
      appointmentAuthority: AppointmentAuthority.president,
      tenure: '6 years or 65 years of age',
      tenureType: TenureType.ageBased,
      removalMechanism: 'Removable like a Supreme Court Judge',
      reportingAuthority: ReportingAuthority.parliament,
      officialSource: 'https://eci.gov.in/',
      evidenceIds: const ['ev_valid'],
      lastVerifiedDate: '2026-06-30',
      keywords: const ['Valid', 'Body'],
    );

    test('accepts a fully-evidenced production body', () {
      final report = BodyValidator.validate(validBody);
      expect(report.isValid, isTrue,
          reason: report.issues.map((i) => i.message).join(' | '));
      expect(report.issues, isEmpty);
    });

    test('rejects a body with a missing official name', () {
      final report =
          BodyValidator.validate(validBody.copyWith(officialName: ''));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
    });

    test('rejects a body with no legal (constitutional/statutory) basis', () {
      final report = BodyValidator.validate(
        validBody.copyWith(
          establishingArticleIds: const [],
          establishingActIds: const [],
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'legalBasis'), isTrue);
    });

    test('rejects malformed Article references', () {
      final report = BodyValidator.validate(
        validBody.copyWith(establishingArticleIds: const ['Article-324']),
      );
      expect(report.isValid, isFalse);
      expect(
          report.issues.any((i) => i.field == 'establishingArticleIds'), isTrue);
    });

    test('rejects contradictory constitutional-basis metadata', () {
      // Articles present but basis marked "none".
      final contradiction = BodyValidator.validate(
        validBody.copyWith(
          constitutionalBasis: ConstitutionalBasis.none,
        ),
      );
      expect(contradiction.isValid, isFalse);
      expect(
          contradiction.issues.any((i) => i.field == 'constitutionalBasis'),
          isTrue);

      // Constitutional basis declared but no article provided.
      final missingArticle = BodyValidator.validate(
        validBody.copyWith(
          constitutionalBasis: ConstitutionalBasis.directArticle,
          establishingArticleIds: const [],
        ),
      );
      expect(missingArticle.isValid, isFalse);
    });

    test('rejects missing mandatory evidence', () {
      final report =
          BodyValidator.validate(validBody.copyWith(evidenceIds: const []));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'evidenceIds'), isTrue);
      expect(report.issues.any((i) => i.message.contains('mandatory evidence')),
          isTrue);
    });

    test('rejects a non-official source URL', () {
      final report = BodyValidator.validate(
        validBody.copyWith(officialSource: 'https://en.wikipedia.org/wiki/ECI'),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialSource'), isTrue);
    });

    test('rejects a placeholder record', () {
      final report = BodyValidator.validate(
        validBody.copyWith(
          officialName: 'Placeholder Body',
          mandate: '',
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
      expect(report.issues.any((i) => i.field == 'mandate'), isTrue);
    });

    test('rejects incomplete tenure/removal data for constitutional bodies',
        () {
      final report = BodyValidator.validate(
        validBody.copyWith(tenure: '', removalMechanism: ''),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'tenure'), isTrue);
      expect(report.issues.any((i) => i.field == 'removalMechanism'), isTrue);
    });

    test('rejects a missing year of establishment', () {
      final report =
          BodyValidator.validate(validBody.copyWith(yearEstablished: 0));
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'yearEstablished'), isTrue);
    });

    test('detects duplicate body IDs', () {
      final report = BodyValidator.validate(validBody, existingBodies: [validBody]);
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('detects duplicate bodies by official name', () {
      final twin = validBody.copyWith(id: 'bod_twin');
      final report = BodyValidator.validate(twin, existingBodies: [validBody]);
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('flags broken relationship references (non-blocking)', () {
      final broken = validBody.copyWith(
        relationships: const [
          BodyRelationship(
            sourceId: 'bod_missing',
            targetId: 'bod_valid',
            relationshipType: BodyRelationshipType.regulates,
          ),
        ],
      );
      final report =
          BodyValidator.validate(broken, existingBodies: [validBody]);
      expect(report.issues.any((i) => i.field == 'relationships'), isTrue);
    });

    test('rejects a published body that lacks evidence', () {
      final report = BodyValidator.validate(
        validBody.copyWith(
          editorialStatus: EditorialStatus.published,
          evidenceIds: const [],
        ),
      );
      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'editorialStatus'), isTrue);
    });

    test('the entire Phase-I corpus passes validation', () {
      final all = BodySeedCorpus.phase1Bodies;
      for (final b in all) {
        final report = BodyValidator.validate(b);
        expect(report.isValid, isTrue,
            reason: 'Seed body ${b.id} should be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });

    test('corpus integrity: no duplicate IDs and evidence present everywhere',
        () {
      final all = BodySeedCorpus.phase1Bodies;
      final ids = all.map((b) => b.id).toSet();
      expect(ids.length, all.length); // no duplicate IDs
      for (final b in all) {
        expect(b.evidenceIds, isNotEmpty,
            reason: '${b.id} must carry official evidence');
        expect(b.officialSource.trim(), isNotEmpty,
            reason: '${b.id} must carry an official source');
        expect(b.establishingArticleIds.isNotEmpty ||
            b.establishingActIds.isNotEmpty, isTrue,
            reason: '${b.id} must have a legal basis');
      }
    });
  });
}
