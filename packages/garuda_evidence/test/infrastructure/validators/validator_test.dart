import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('Validation Framework Tests', () {
    late EvidenceObject validEvidence;
    final now = DateTime.now();

    setUp(() {
      validEvidence = EvidenceObject(
        id: 'EV-VALID-001',
        title: 'Supreme Court Ruling on Electoral Bonds',
        sourceName: 'Supreme Court Judgments',
        sourceType: EvidenceSourceType.judiciary,
        authority: const EvidenceAuthority(
          id: 'sc_india',
          name: 'Supreme Court of India',
          type: EvidenceSourceType.judiciary,
          jurisdiction: 'India',
        ),
        publicationDate: now.subtract(const Duration(days: 1)),
        retrievedDate: now,
        category: 'Judiciary',
        subject: 'Polity',
        topic: 'Elections',
        subtopic: 'Electoral Bonds',
        keywords: const ['Supreme Court', 'Elections', 'Polity'],
        language: 'en',
        summary: 'Landmark verdict on electoral bond transparency.',
        originalUrl: 'https://main.sci.gov.in/supremecourt/2024/judgment.pdf',
        pdfUrl: 'https://main.sci.gov.in/supremecourt/2024/judgment.pdf',
        confidenceScore: 1.0,
        verificationStatus: VerificationStatus.verified,
        editorialStatus: EditorialStatus.published,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );
    });

    test('MetadataValidator should pass for valid evidence and fail for missing title', () async {
      final validator = MetadataValidator();
      final resPass = await validator.validate(validEvidence);
      expect(resPass.isValid, isTrue);

      final invalid = validEvidence.copyWith(title: '');
      final resFail = await validator.validate(invalid);
      expect(resFail.isValid, isFalse);
      expect(resFail.errors.any((e) => e.code == 'MISSING_TITLE'), isTrue);
    });

    test('AuthorityValidator should validate authority fields', () async {
      final validator = AuthorityValidator();
      final resPass = await validator.validate(validEvidence);
      expect(resPass.isValid, isTrue);

      final invalid = validEvidence.copyWith(
        authority: const EvidenceAuthority(
          id: '',
          name: '',
          type: EvidenceSourceType.other,
          jurisdiction: '',
        ),
      );
      final resFail = await validator.validate(invalid);
      expect(resFail.isValid, isFalse);
      expect(resFail.errors.length, greaterThanOrEqualTo(2));
    });

    test('DateValidator should check future dates', () async {
      final validator = DateValidator();
      final resPass = await validator.validate(validEvidence);
      expect(resPass.isValid, isTrue);

      final futureDate = now.add(const Duration(days: 10));
      final invalid = validEvidence.copyWith(publicationDate: futureDate);
      final resFail = await validator.validate(invalid);
      expect(resFail.isValid, isFalse);
      expect(resFail.errors.any((e) => e.code == 'FUTURE_PUBLICATION_DATE'), isTrue);
    });

    test('URLValidator should validate originalUrl', () async {
      final validator = URLValidator();
      final resPass = await validator.validate(validEvidence);
      expect(resPass.isValid, isTrue);

      final invalid = validEvidence.copyWith(originalUrl: 'invalid-url-format');
      final resFail = await validator.validate(invalid);
      expect(resFail.isValid, isFalse);
      expect(resFail.errors.any((e) => e.code == 'INVALID_ORIGINAL_URL'), isTrue);
    });

    test('JSONValidator should verify serialization integrity', () async {
      final validator = JSONValidator();
      final resPass = await validator.validate(validEvidence);
      expect(resPass.isValid, isTrue);
    });

    test('CompositeEvidenceValidator should execute all 6 validators', () async {
      final composite = CompositeEvidenceValidator.standard();
      final res = await composite.validate(validEvidence);
      expect(res.isValid, isTrue);
    });
  });
}
